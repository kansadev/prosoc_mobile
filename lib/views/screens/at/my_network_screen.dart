import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:prosoc/views/screens/adh%C3%A9rent/widgets/payer_contributionScreen.dart';
import 'package:prosoc/views/screens/adh%C3%A9rent/AffiliateDetailsScreen.dart';
import 'package:prosoc/widgets/popup_menu_widget.dart';
import 'package:prosoc/widgets/antecedent_bottom_sheet.dart';
import 'package:prosoc/widgets/dependant_bottom_sheet.dart';
import 'package:prosoc/widgets/souscription_bottom_sheet.dart';
import '../../../config/colors.dart';
import '../../../config/api.dart';
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

class _MyNetworkScreenState extends State<MyNetworkScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // Données des affiliés de l'agent (son réseau)
  List<Map<String, dynamic>> _membres = [];
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasNextPage = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadAffilies(reset: true);
  }

  void _onScroll() {
    if (_isLoading || _isLoadingMore || !_hasNextPage) return;

    const threshold = 200.0;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - threshold) {
      _loadAffilies();
    }
  }

  Future<void> _loadAffilies({bool reset = false}) async {
    try {
      if (reset) {
        setState(() {
          _isLoading = true;
          _isLoadingMore = false;
          _errorMessage = null;
          _membres = [];
          _currentPage = 1;
          _hasNextPage = false;
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
          _currentPage = payload['currentPage'] is int
              ? payload['currentPage'] as int
              : pageToLoad;
          _hasNextPage = payload['hasNextPage'] == true;
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _errorMessage =
              response.message ??
              ApiErrorHelper.userFacingMessage(
                statusCode: response.statusCode,
              );
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('MyNetwork/affilies', e, stackTrace);
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiErrorHelper.userFacingNetwork();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadAffilies(reset: true),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _loadAffilies(reset: true),
              color: AppColors.prosocGreen,
              child: _buildMembersList(),
            ),
      floatingActionButton: FloatingActionButton.extended(
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

  Widget _buildMembersList() {
    if (_membres.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Aucun affilié dans votre réseau',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    final actifs = _membres
        .where((m) => m['statutAffilie'] == true || m['statut'] == true)
        .length;
    final enAttente = _membres.where((m) {
      final statutDossier = (m['statutDossier'] ?? '').toString().toLowerCase();
      return statutDossier.contains('attente');
    }).length;

    return Column(
      children: [
        // Statistiques
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.prosocGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('Total', _membres.length.toString()),
              _buildStat('Actifs', actifs.toString()),
              _buildStat('En attente', enAttente.toString()),
            ],
          ),
        ),
        // Liste des membres
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
        ),
      ],
    );
  }

  bool _isSoloAdhesion(String typeAdhesion) {
    return typeAdhesion.toLowerCase().contains('solo');
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.prosocGreen,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
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
              preview: RecentAffilieModel(
                idAffilie: affilieId,
                nom: membre['nom'],
                prenom: membre['prenom'],
                telephone: membre['phone'] ?? membre['telephone'],
                dateAdhesion: membre['dateCreation'],
                typeAdhesion: membre['typeAdhesion'] ?? 'N/A',
              ),
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
                      ),
                    ),
                  );
                },
                onDependants: _isSoloAdhesion(typeAdhesion)
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
                  );
                },
                onAntecedents: () {
                  AntecedentBottomSheet.show(
                    context,
                    affilieId: affilieId,
                    affilieNom: nom,
                    affiliePrenom: prenom,
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
