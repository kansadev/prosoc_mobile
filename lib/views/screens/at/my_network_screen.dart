import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:prosoc/views/screens/adh%C3%A9rent/widgets/payer_contributionScreen.dart';
import 'package:prosoc/views/screens/adh%C3%A9rent/widgets/payer_frais_screen.dart';
import 'package:prosoc/views/screens/adh%C3%A9rent/widgets/payer_souscription_screen.dart';
import 'package:prosoc/views/screens/adh%C3%A9rent/AffiliateDetailsScreen.dart';
import 'package:prosoc/views/screens/adh%C3%A9rent/arrieres_affilie_screen.dart';
import 'package:prosoc/views/screens/adh%C3%A9rent/adherent_demande_bon_screen.dart';
import 'package:prosoc/widgets/popup_menu_widget.dart';
import 'package:prosoc/utils/medical_permissions.dart';
import 'package:prosoc/views/screens/medical/medical_home_screen.dart';
import 'package:prosoc/widgets/dependant_bottom_sheet.dart';
import 'package:prosoc/widgets/souscription_bottom_sheet.dart';
import '../../../config/colors.dart';
import '../../../config/api.dart';
import '../../../offline/offline_mode.dart';
import '../../../services/sync_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/recent_affilie_model.dart';
import '../../../utils/affilie_id_helper.dart';
import '../../../utils/api_error_helper.dart';
import '../../../utils/paginated_response_helper.dart';
import 'new_adhesion_screen.dart';

// ============================================
// ÉCRAN MON RÉSEAU (VIEW)
// ============================================
class MyNetworkScreen extends StatefulWidget {
  /// Quand l'écran est un onglet (ex. shell superviseur), retour vers l'accueil
  /// au lieu de [Navigator.pop] qui n'a pas de route parente.
  final VoidCallback? onBack;

  const MyNetworkScreen({super.key, this.onBack});

  @override
  State<MyNetworkScreen> createState() => _MyNetworkScreenState();
}

class _MyNetworkScreenState extends State<MyNetworkScreen>
    with OfflineAwareState<MyNetworkScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _activeSearch;

  // Données des affiliés de l'agent (son réseau)
  List<Map<String, dynamic>> _membres = [];
  int _currentPage = 1;
  static const int _pageSize = 20;
  bool _hasNextPage = false;

  /// La liste affichée vient du cache local.
  bool _depuisCache = false;

  int _ecrituresEnAttente = 0;

  static const String _sortBy = 'dateAdhesion';
  static const String _sortDirection = 'desc';

  @override
  void initState() {
    super.initState();
    _ecrituresEnAttente = SyncService.instance.pendingCount;
    SyncService.instance.state.addListener(_onFileChangee);
    _scrollController.addListener(_onScroll);
    _loadAffilies(reset: true);
  }

  /// Des écritures hors ligne viennent de partir : le rechargement fait au
  /// retour du réseau était antérieur à leur envoi.
  void _onFileChangee() {
    final enAttente = SyncService.instance.pendingCount;
    final envoyees = enAttente < _ecrituresEnAttente;
    _ecrituresEnAttente = enAttente;
    if (envoyees && mounted && !isOffline) {
      _loadAffilies(reset: true, search: _activeSearch);
    }
  }

  /// Liste issue du dernier téléchargement : hors ligne, ou réseau en échec.
  void _chargerDepuisCache(String? search) {
    final agentId = AuthService.currentUser?.utilisateur.agentId;
    setState(() {
      _membres = OfflineMode.membresLocaux(
        recherche: search ?? '',
        agentId: agentId,
      );
      _depuisCache = true;
      _activeSearch = search;
      _currentPage = 1;
      _hasNextPage = false;
      _errorMessage = null;
      _isLoading = false;
      _isLoadingMore = false;
    });
  }

  @override
  void onOfflineChanged(bool offline) {
    if (offline && !_depuisCache) {
      _chargerDepuisCache(_activeSearch);
    } else if (!offline && _depuisCache) {
      _loadAffilies(reset: true, search: _activeSearch);
    }
  }

  void _onScroll() {
    if (_isLoading || _isLoadingMore || !_hasNextPage) return;

    const threshold = 200.0;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - threshold) {
      _loadAffilies();
    }
  }

  Future<void> _loadAffilies({bool reset = false, String? search}) async {
    if (isOffline) {
      if (reset) _chargerDepuisCache(search);
      return;
    }
    try {
      if (reset) {
        setState(() {
          _depuisCache = false;
          _isLoading = true;
          _isLoadingMore = false;
          _errorMessage = null;
          _membres = [];
          _currentPage = 1;
          _hasNextPage = false;
          _activeSearch = search;
        });
      } else {
        if (_isLoadingMore || !_hasNextPage) return;
        setState(() {
          _isLoadingMore = true;
          _errorMessage = null;
        });
      }

      final agentId =
          AuthService.currentUser?.utilisateur.agentId ?? AuthService.userId;
      if (agentId == null) {
        if (kDebugMode) {
          throw Exception('Vous n\'êtes pas connecté');
        }
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Vous n\'êtes pas connecté';
          _isLoading = false;
          _isLoadingMore = false;
        });
        return;
      }

      final pageToLoad = reset ? 1 : _currentPage + 1;
      final response = await ApiService.getAffiliesByAgent(
        agentId,
        page: pageToLoad,
        pageSize: _pageSize,
        sortBy: _sortBy,
        sortDirection: _sortDirection,
        search: search ?? _activeSearch,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        final payload = response.data!;
        final rows = PaginatedResponseHelper.extractRows(payload);

        final membresPage = rows
            .map<Map<String, dynamic>>((e) {
              if (e is Map<String, dynamic>) return e;
              if (e is Map) return Map<String, dynamic>.from(e);
              return <String, dynamic>{};
            })
            .where((m) => m.isNotEmpty)
            .toList();

        setState(() {
          _membres = reset ? membresPage : [..._membres, ...membresPage];
          _currentPage = PaginatedResponseHelper.extractCurrentPage(
            payload,
            fallback: pageToLoad,
          );
          _hasNextPage = PaginatedResponseHelper.extractHasNext(payload);
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else if (reset &&
          OfflineMode.sansReseau(
            success: response.success,
            statusCode: response.statusCode,
          )) {
        _chargerDepuisCache(search);
      } else {
        setState(() {
          _errorMessage =
              response.message ??
              ApiErrorHelper.userFacingMessage(statusCode: response.statusCode);
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('MyNetwork/affilies', e, stackTrace);
      if (!mounted) return;
      if (reset) {
        _chargerDepuisCache(search);
        return;
      }
      setState(() {
        _errorMessage = ApiErrorHelper.userFacingNetwork();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      final query = value.trim();
      _loadAffilies(reset: true, search: query.isEmpty ? null : query);
    });
  }

  Future<void> _navigateToNewAdhesion() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const NewAdhesionScreen()),
    );

    if (created == true && mounted) {
      await _loadAffilies(reset: true);
    }
  }

  @override
  void dispose() {
    SyncService.instance.state.removeListener(_onFileChangee);
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showBack = widget.onBack != null || Navigator.canPop(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: showBack
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppColors.textPrimary,
                ),
                onPressed: _handleBack,
              )
            : null,
        title: const Text(
          'Mon Réseau',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un affilié (nom, matricule…)',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {});
                _onSearchChanged(value);
              },
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ),
          if (_depuisCache)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: OfflineDataBanner(
                complement: 'Certaines actions nécessitent une connexion.',
              ),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
      // L'adhésion hors ligne a besoin des catalogues synchronisés.
      floatingActionButton:
          _depuisCache && (OfflineMode.referentials?.isEmpty ?? true)
          ? null
          : FloatingActionButton.extended(
              onPressed: _navigateToNewAdhesion,
              backgroundColor: AppColors.prosocGreen,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Nouvelle adhésion',
                style: TextStyle(color: Colors.white),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.prosocGreen),
      );
    }

    if (_membres.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadAffilies(reset: true, search: _activeSearch),
        color: AppColors.prosocGreen,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _activeSearch != null
                  ? 'Aucun affilié trouvé pour « $_activeSearch ».'
                  : _depuisCache
                  ? 'Aucun affilié enregistré sur cet appareil. Connectez-vous '
                        'une fois pour les synchroniser.'
                  : 'Aucun affilié dans votre réseau',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () =>
                      _loadAffilies(reset: true, search: _activeSearch),
                  child: const Text('Réessayer'),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadAffilies(reset: true, search: _activeSearch),
      color: AppColors.prosocGreen,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
        itemCount: _membres.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (_isLoadingMore && index == _membres.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.prosocGreen,
                ),
              ),
            );
          }

          final membre = _membres[index];
          return _buildMemberCard(membre);
        },
      ),
    );
  }

  bool _isSoloAdhesion(String typeAdhesion) {
    return typeAdhesion.toLowerCase().contains('solo');
  }

  Widget _buildMemberCard(Map<String, dynamic> membre) {
    final affilieId = resolveAffilieId(membre);
    final prenom = (membre['prenom'] ?? '').toString();
    final nom = (membre['nom'] ?? '').toString();
    final telephone = (membre['phone'] ?? membre['telephone'] ?? '').toString();
    final matricule = (membre['matricule'] ?? membre['codeAdhesion'] ?? '')
        .toString();
    final typeAdhesion = (membre['typeAdhesion'] ?? '').toString();
    final statutDossier = (membre['statutDossier'] ?? '').toString();
    final statutAffilie =
        membre['statutAffilie'] == true || membre['statut'] == true;

    final statusLabel = statutDossier.isNotEmpty
        ? statutDossier
        : (statutAffilie ? 'Actif' : 'Inactif');
    final isPending = statusLabel.toLowerCase().contains('attente');

    final statusBg = isPending
        ? Colors.orange.shade100
        : statutAffilie
        ? Colors.green.shade100
        : Colors.grey.shade200;

    final statusFg = isPending
        ? Colors.orange.shade700
        : statutAffilie
        ? Colors.green.shade700
        : Colors.grey.shade700;

    final initials = [
      if (prenom.trim().isNotEmpty) prenom.trim()[0] else '?',
      if (nom.trim().isNotEmpty) nom.trim()[0] else '?',
    ].join();

    return InkWell(
      onTap: () {
        // Naviguer vers les détails de l'affilié
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AffiliateDetailsScreen(
              affilieId: affilieId,
              preview: RecentAffilieModel.fromJson({
                ...membre,
                'idAffilie': affilieId,
                'affilieId': affilieId,
              }),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.prosocGreen.withValues(alpha: 0.1),
                child: Text(
                  initials.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.prosocGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$prenom $nom'.trim(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (telephone.isNotEmpty)
                      Text(
                        telephone,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    if (matricule.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        matricule,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(fontSize: 12, color: statusFg),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (typeAdhesion.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              typeAdhesion,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              AffiliatePopupMenuWidget(
                onCollecte: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PayerContributionScreen(
                        affilieId: affilieId,
                        affilieNom: nom,
                        affiliePrenom: prenom,
                        affilieTelephone: telephone.isNotEmpty
                            ? telephone
                            : null,
                        allowVirtualAccount: true,
                      ),
                    ),
                  );
                },
                onPayerFrais: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PayerFraisScreen(
                        affilieId: affilieId,
                        affilieNom: nom,
                        affiliePrenom: prenom,
                        affilieTelephone: telephone.isNotEmpty
                            ? telephone
                            : null,
                        allowVirtualAccount: true,
                      ),
                    ),
                  );
                },
                onPayerSouscription: _depuisCache ? null : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PayerSouscriptionScreen(
                        affilieId: affilieId,
                        affilieNom: nom,
                        affiliePrenom: prenom,
                        affilieTelephone: telephone.isNotEmpty
                            ? telephone
                            : null,
                        allowVirtualAccount: true,
                      ),
                    ),
                  );
                },
                onDependants: _depuisCache || _isSoloAdhesion(typeAdhesion)
                    ? null
                    : () {
                        DependantBottomSheet.show(
                          context,
                          affilieId: affilieId,
                          affilieNom: nom,
                          affiliePrenom: prenom,
                        );
                      },
                onSouscription: () {
                  SouscriptionBottomSheet.show(
                    context,
                    affilieId: affilieId,
                    affilieNom: nom,
                    affiliePrenom: prenom,
                    affilieTelephone: telephone.trim().isNotEmpty
                        ? telephone
                        : null,
                    allowVirtualAccount: true,
                  );
                },
                onDemandeBon: _depuisCache ? null : () {
                  final name = '$prenom $nom'.trim();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdherentDemandeBonScreen(
                        affilieId: affilieId,
                        agentId: AuthService.agentId,
                        affilieNomComplet: name.isNotEmpty ? name : null,
                      ),
                    ),
                  );
                },
                onCouvertureMedicale:
                    !_depuisCache &&
                        MedicalPermissions.peutConsulterSouscriptions
                    ? () {
                        final name = '$prenom $nom'.trim();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MedicalHomeScreen(
                              affilieId: affilieId,
                              affilieNom: name.isNotEmpty ? name : null,
                            ),
                          ),
                        );
                      }
                    : null,
                onArrieres: _depuisCache ? null : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArrieresAffilieScreen(
                        affilieId: affilieId,
                        affilieNom: nom,
                        affiliePrenom: prenom,
                        allowVirtualAccount: true,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
