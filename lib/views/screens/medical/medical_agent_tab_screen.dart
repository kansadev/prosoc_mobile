import 'dart:async';

import 'package:flutter/material.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../services/auth_service.dart';
import '../../../utils/affilie_id_helper.dart';
import '../../../utils/medical_permissions.dart';
import '../../../utils/paginated_response_helper.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/prosoc_resource_error_view.dart';
import '../../../models/medical/prise_en_charge_medicale_model.dart';
import 'medical_home_screen.dart';
import 'prise_en_charge_screen.dart';
import 'widgets/medical_ui.dart';

/// Prestations médicales du personnel :
/// - « Affiliés » : choix d'un affilié pour gérer sa couverture (réseau de
///   l'agent pour l'AT, recherche générale pour percepteur / superviseur) ;
/// - « À confirmer » : file des prises en charge `EN_ATTENTE`, pour les comptes
///   autorisés à confirmer ;
/// - scan des bons, selon les permissions.
class MedicalAgentTabScreen extends StatefulWidget {
  const MedicalAgentTabScreen({
    super.key,
    this.reseauSeulement = true,
    this.estOnglet = true,
  });

  /// `true` : affiliés du réseau de l'agent connecté (AT).
  /// `false` : recherche dans tous les affiliés accessibles au compte.
  final bool reseauSeulement;

  /// Affiché comme onglet (pas de bouton retour) ou comme écran poussé.
  final bool estOnglet;

  @override
  State<MedicalAgentTabScreen> createState() => _MedicalAgentTabScreenState();
}

class _MedicalAgentTabScreenState extends State<MedicalAgentTabScreen> {
  static const int _pageSize = 20;

  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _membres = const [];
  int _page = 1;
  bool _hasNext = false;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int? _errorStatus;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _load(reset: true),
    );
  }

  Future<void> _load({required bool reset}) async {
    final agentId = AuthService.agentId;
    if (widget.reseauSeulement && agentId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Profil agent introuvable. Reconnectez-vous.';
      });
      return;
    }
    if (!reset && (_isLoadingMore || !_hasNext)) return;
    setState(() {
      if (reset) {
        _isLoading = true;
        _error = null;
      } else {
        _isLoadingMore = true;
      }
    });

    final page = reset ? 1 : _page + 1;
    final search = _searchController.text.trim();
    final response = widget.reseauSeulement
        ? await ApiService.getAffiliesByAgent(
            agentId!,
            page: page,
            pageSize: _pageSize,
            search: search.isEmpty ? null : search,
          )
        : await ApiService.searchAffilies(
            page: page,
            pageSize: _pageSize,
            search: search.isEmpty ? null : search,
          );
    if (!mounted) return;

    if (!response.success || response.data == null) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _error = response.message;
        _errorStatus = response.statusCode;
      });
      return;
    }
    final payload = response.data!;
    final rows = PaginatedResponseHelper.extractRows(payload)
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .where((m) => resolveAffilieId(m) > 0)
        .toList();
    setState(() {
      _membres = reset ? rows : [..._membres, ...rows];
      _page = page;
      _hasNext = PaginatedResponseHelper.extractHasNext(payload);
      _isLoading = false;
      _isLoadingMore = false;
      _error = null;
    });
  }

  void _ouvrirCouverture(Map<String, dynamic> membre) {
    final nom = [
      (membre['prenom'] ?? '').toString(),
      (membre['nom'] ?? '').toString(),
    ].where((e) => e.trim().isNotEmpty).join(' ');
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MedicalHomeScreen(
          affilieId: resolveAffilieId(membre),
          affilieNom: nom.isEmpty ? null : nom,
        ),
      ),
    );
  }

  void _scanner() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const MedicalScanScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final peutConsulter = MedicalPermissions.peutConsulterSouscriptions;
    final avecFile = MedicalPermissions.peutConfirmerPriseEnCharge;
    final affilies = !peutConsulter ? _buildScanOnly() : _buildAffilies();
    final appBar = AppBar(
      title: const Text('Prestations médicales'),
      automaticallyImplyLeading: !widget.estOnglet,
      backgroundColor: AppColors.prosocGreen,
      foregroundColor: Colors.white,
      actions: [
        if (MedicalPermissions.peutScanner)
          IconButton(
            tooltip: 'Scanner un bon',
            onPressed: _scanner,
            icon: const Icon(Icons.qr_code_scanner),
          ),
      ],
      bottom: avecFile
          ? const TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: 'À confirmer'),
                Tab(text: 'Affiliés'),
              ],
            )
          : null,
    );
    final scaffold = Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: appBar,
      body: avecFile
          ? TabBarView(children: [const _FileAConfirmer(), affilies])
          : affilies,
    );
    return avecFile
        ? DefaultTabController(length: 2, child: scaffold)
        : scaffold;
  }

  Widget _buildAffilies() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Rechercher un affilié (nom, code, téléphone)',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _load(reset: true),
            child: _buildList(),
          ),
        ),
      ],
    );
  }

  Widget _buildScanOnly() {
    return EmptyStateWidget(
      icon: Icons.qr_code_scanner,
      title: 'Vérification des bons médicaux',
      subtitle: 'Scannez le QR code présenté par l\'affilié.',
      action: ElevatedButton.icon(
        onPressed: _scanner,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scanner un bon'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.prosocGreen,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ListView(
        children: [
          ProsocResourceErrorView(
            message: _error!,
            statusCode: _errorStatus,
            onRetry: () => _load(reset: true),
          ),
        ],
      );
    }
    if (_membres.isEmpty) {
      return ListView(
        children: const [
          EmptyStateWidget(
            icon: Icons.people_outline,
            title: 'Aucun affilié trouvé',
            subtitle: 'Modifiez la recherche ou vérifiez votre réseau.',
            expandVertically: false,
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _membres.length + (_hasNext ? 1 : 0),
      itemBuilder: (_, i) {
        if (i >= _membres.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: _isLoadingMore
                  ? const CircularProgressIndicator()
                  : TextButton(
                      onPressed: () => _load(reset: false),
                      child: const Text('Afficher plus'),
                    ),
            ),
          );
        }
        final m = _membres[i];
        final nom = [
          (m['prenom'] ?? '').toString(),
          (m['nom'] ?? '').toString(),
        ].where((e) => e.trim().isNotEmpty).join(' ');
        final code = (m['matricule'] ?? m['codeAdhesion'] ?? '').toString();
        final tel = (m['phone'] ?? m['telephone'] ?? '').toString();
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0x1A2DB467),
              child: Icon(Icons.person_outline, color: AppColors.prosocGreen),
            ),
            title: Text(
              nom.isEmpty ? 'Affilié #${resolveAffilieId(m)}' : nom,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              [code, tel].where((e) => e.trim().isNotEmpty).join(' · '),
            ),
            trailing: const Icon(
              Icons.local_hospital_outlined,
              color: Colors.teal,
            ),
            onTap: () => _ouvrirCouverture(m),
          ),
        );
      },
    );
  }
}

/// File des prises en charge médicales `EN_ATTENTE` (tous affiliés), à
/// confirmer ou rejeter depuis le détail.
class _FileAConfirmer extends StatefulWidget {
  const _FileAConfirmer();

  @override
  State<_FileAConfirmer> createState() => _FileAConfirmerState();
}

class _FileAConfirmerState extends State<_FileAConfirmer>
    with AutomaticKeepAliveClientMixin {
  List<PriseEnChargeMedicale> _demandes = const [];
  bool _isLoading = true;
  String? _error;
  int? _errorStatus;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final response = await ApiService.getPrisesEnChargeEnAttente();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (response.success && response.data != null) {
        _demandes = [...response.data!]
          ..sort(
            (a, b) => (a.dateDemandeUtc ?? DateTime(0)).compareTo(
              b.dateDemandeUtc ?? DateTime(0),
            ),
          );
      } else {
        _error = response.message;
        _errorStatus = response.statusCode;
      }
    });
  }

  Future<void> _ouvrir(PriseEnChargeMedicale demande) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PriseEnChargeScreen(priseEnChargeId: demande.id),
      ),
    );
    // Une demande traitée quitte la file : on recharge.
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: _load,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ListView(
              children: [
                ProsocResourceErrorView(
                  message: _error!,
                  statusCode: _errorStatus,
                  onRetry: _load,
                ),
              ],
            )
          : _demandes.isEmpty
          ? ListView(
              children: const [
                EmptyStateWidget(
                  icon: Icons.inbox_outlined,
                  title: 'Aucune demande à confirmer',
                  subtitle:
                      'Les nouvelles demandes de prise en charge '
                      'apparaîtront ici.',
                  expandVertically: false,
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: _demandes.length,
              itemBuilder: (_, i) {
                final d = _demandes[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0x1AF57C00),
                      child: Icon(
                        Icons.pending_actions_outlined,
                        color: AppColors.warningColor,
                      ),
                    ),
                    title: Text(
                      d.soinNom ?? 'Soin #${d.soinId}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Affilié #${d.affilieId} · '
                      '${MedicalFormat.dateHeure(d.dateDemandeUtc)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _ouvrir(d),
                  ),
                );
              },
            ),
    );
  }
}
