import 'package:flutter/material.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/bon_envoi_model.dart';
import '../../../models/demande_bon_envoi_model.dart';
import '../../../models/souscription_prestation_model.dart';
import '../../../services/auth_service.dart';
import '../../../utils/api_error_helper.dart';
import '../../../utils/formatters.dart';
import '../../../utils/paginated_response_helper.dart';
import '../../widgets/dashboard_segment_tab_bar.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/bon_envoi_qr_view.dart';
import 'widgets/bon_envoi_detail_sheet.dart';
import 'widgets/demande_bon_form_sheet.dart';

/// Bons d'envoi et demandes — BonEnvoi paginé + DemandeBonEnvoi.
class AdherentDemandeBonScreen extends StatefulWidget {
  const AdherentDemandeBonScreen({super.key});

  @override
  State<AdherentDemandeBonScreen> createState() =>
      _AdherentDemandeBonScreenState();
}

class _AdherentDemandeBonScreenState extends State<AdherentDemandeBonScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _bonsScrollController = ScrollController();

  List<BonEnvoiModel> _bons = [];
  List<DemandeBonEnvoiModel> _demandes = [];
  List<SouscriptionPrestationModel> _souscriptions = [];
  DemandeBonEligibilite? _eligibilite;
  bool _eligibiliteVerifiee = false;

  bool _loadingBons = true;
  bool _loadingBonsMore = false;
  bool _bonsHasNext = false;
  int _bonsPage = 1;
  String? _errorBons;

  bool _loadingDemandes = true;
  String? _errorDemandes;

  static const _pageSize = 20;

  int? get _affilieId => AuthService.affilieId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _bonsScrollController.addListener(_onBonsScroll);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _bonsScrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  void _onBonsScroll() {
    if (!_bonsHasNext || _loadingBonsMore || _loadingBons) return;
    if (_bonsScrollController.position.pixels >=
        _bonsScrollController.position.maxScrollExtent - 200) {
      _loadBons();
    }
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadBons(reset: true),
      _loadDemandesAndMeta(),
    ]);
  }

  Future<void> _loadBons({bool reset = false}) async {
    final affilieId = _affilieId;
    if (affilieId == null || affilieId <= 0) {
      setState(() {
        _errorBons = 'Profil affilié introuvable.';
        _loadingBons = false;
      });
      return;
    }

    if (reset) {
      setState(() {
        _loadingBons = true;
        _errorBons = null;
        _bonsPage = 1;
        _bonsHasNext = false;
      });
    } else {
      if (!_bonsHasNext) return;
      setState(() => _loadingBonsMore = true);
    }

    try {
      final response = await ApiService.getBonEnvoiByAffiliePaginated(
        affilieId: affilieId,
        page: reset ? 1 : _bonsPage,
        pageSize: _pageSize,
        sortBy: 'dateEmission',
        sortDirection: 'desc',
      );

      if (!mounted) return;

      final payload = response.data;
      if (response.success && payload != null) {
        final rows = PaginatedResponseHelper.extractRows(payload);
        final parsed = <BonEnvoiModel>[];
        for (final item in rows) {
          if (item is! Map) continue;
          try {
            final map = item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item);
            parsed.add(BonEnvoiModel.fromJson(map));
          } catch (e, st) {
            ApiErrorHelper.logException('BonEnvoi/json', e, st);
          }
        }

        setState(() {
          if (reset) {
            _bons = parsed;
          } else {
            _bons = [..._bons, ...parsed];
          }
          _bonsHasNext = PaginatedResponseHelper.extractHasNext(payload);
          if (_bonsHasNext) {
            _bonsPage =
                PaginatedResponseHelper.extractCurrentPage(payload) + 1;
          }
          _errorBons = null;
          _loadingBons = false;
          _loadingBonsMore = false;
        });
      } else {
        setState(() {
          if (reset) {
            _bons = [];
            _errorBons = response.message ??
                'Impossible de charger les bons.';
          }
          _loadingBons = false;
          _loadingBonsMore = false;
        });
      }
    } catch (e, st) {
      ApiErrorHelper.logException('BonEnvoi/load', e, st, false);
      if (!mounted) return;
      setState(() {
        if (reset) {
          _errorBons = ApiErrorHelper.userFacingNetwork();
          _bons = [];
        }
        _loadingBons = false;
        _loadingBonsMore = false;
      });
    }
  }

  Future<void> _loadDemandesAndMeta() async {
    final affilieId = _affilieId;
    if (affilieId == null || affilieId <= 0) {
      setState(() {
        _errorDemandes = 'Profil affilié introuvable.';
        _loadingDemandes = false;
      });
      return;
    }

    setState(() {
      _loadingDemandes = true;
      _errorDemandes = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getDemandesBonEnvoiByAffilie(affilieId),
        ApiService.verifierEligibiliteDemandeBon(affilieId),
        ApiService.getSouscriptionsPrestationByAffilie(affilieId),
      ]);

      if (!mounted) return;

      final listResponse =
          results[0] as ApiResponse<List<DemandeBonEnvoiModel>>;
      final eligResponse = results[1] as ApiResponse<DemandeBonEligibilite>;
      final sousResponse =
          results[2] as ApiResponse<List<SouscriptionPrestationModel>>;

      final eligibiliteVerifiee = eligResponse.success;
      final eligibilite = eligResponse.data;

      if (listResponse.success) {
        final sorted = List<DemandeBonEnvoiModel>.from(listResponse.data ?? [])
          ..sort((a, b) {
            final da = a.dateDemande ?? a.dateCreation;
            final db = b.dateDemande ?? b.dateCreation;
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return db.compareTo(da);
          });
        setState(() {
          _demandes = sorted;
          _eligibiliteVerifiee = eligibiliteVerifiee;
          _eligibilite = eligibilite;
          _souscriptions = sousResponse.data ?? [];
          _errorDemandes = null;
          _loadingDemandes = false;
        });
      } else {
        setState(() {
          _demandes = [];
          _eligibiliteVerifiee = eligibiliteVerifiee;
          _eligibilite = eligibilite;
          _souscriptions = sousResponse.data ?? [];
          _errorDemandes = listResponse.message ??
              'Impossible de charger les demandes.';
          _loadingDemandes = false;
        });
      }
    } catch (e, st) {
      ApiErrorHelper.logException('DemandeBonEnvoi/load', e, st, false);
      if (!mounted) return;
      setState(() {
        _errorDemandes = ApiErrorHelper.userFacingNetwork();
        _loadingDemandes = false;
      });
    }
  }

  bool get _peutCreerDemande {
    if (!_eligibiliteVerifiee) return false;
    final elig = _eligibilite;
    if (elig == null || !elig.eligible) return false;
    return _souscriptions.any((s) => s.statut && s.prestationId > 0);
  }

  bool get _showFab =>
      _tabController.index == 1 && _peutCreerDemande && !_loadingDemandes;

  String get _messageEligibilite {
    if (!_eligibiliteVerifiee) {
      return 'La vérification d\'éligibilité a échoué. '
          'Vous ne pouvez pas soumettre de demande pour le moment.';
    }
    final elig = _eligibilite;
    if (elig == null || !elig.eligible) {
      return elig?.message.isNotEmpty == true
          ? elig!.message
          : 'Vous n\'êtes pas éligible à une demande de bon.';
    }
    if (!_souscriptions.any((s) => s.statut && s.prestationId > 0)) {
      return 'Aucune souscription active. Souscrivez à une prestation '
          'avant de demander un bon.';
    }
    return '';
  }

  bool get _afficherBanniereEligibilite => _messageEligibilite.isNotEmpty;

  Widget _buildEligibiliteHeader() {
    if (!_afficherBanniereEligibilite) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: _eligibiliteBanner(_messageEligibilite),
    );
  }

  Future<void> _openCreateForm() async {
    final affilieId = _affilieId;
    if (affilieId == null) return;

    if (!_peutCreerDemande) {
      final msg = _messageEligibilite;
      if (msg.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
      return;
    }

    final recheck = await ApiService.verifierEligibiliteDemandeBon(affilieId);
    if (!mounted) return;
    if (!recheck.success || recheck.data?.eligible != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            recheck.data?.message.isNotEmpty == true
                ? recheck.data!.message
                : (recheck.message ??
                    'Vous n\'êtes pas éligible à une demande de bon.'),
          ),
        ),
      );
      setState(() {
        _eligibiliteVerifiee = recheck.success;
        _eligibilite = recheck.data;
      });
      return;
    }

    final ok = await DemandeBonFormSheet.show(
      context,
      affilieId: affilieId,
      souscriptions: _souscriptions,
    );
    if (ok == true && mounted) {
      await _loadDemandesAndMeta();
      await _loadBons(reset: true);
    }
  }

  Color _demandeStatutColor(String statut) {
    final s = statut.toLowerCase();
    if (s.contains('valid') || s.contains('approuv')) {
      return AppColors.prosocGreen;
    }
    if (s.contains('refus') || s.contains('rejet')) {
      return AppColors.errorColor;
    }
    if (s.contains('attent') || s.contains('cours')) {
      return Colors.orange.shade700;
    }
    return Colors.blue.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('Bons et Demandes'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      floatingActionButton: _showFab
          ? FloatingActionButton.extended(
              heroTag: 'fab_adherent_demande_bon',
              onPressed: _openCreateForm,
              backgroundColor: AppColors.prosocGreen,
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle demande'),
            )
          : null,
      body: Column(
        children: [
          DashboardSegmentTabBar(
            controller: _tabController,
            tabs: [
              DashboardSegmentTabItem(
                label: 'Mes bons',
                badgeCount: _bons.length,
              ),
              DashboardSegmentTabItem(
                label: 'Demandes',
                badgeCount: _demandes.length,
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: () => _loadBons(reset: true),
                  color: AppColors.prosocGreen,
                  child: _buildBonsTab(),
                ),
                RefreshIndicator(
                  onRefresh: _loadDemandesAndMeta,
                  color: AppColors.prosocGreen,
                  child: _buildDemandesTab(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBonsTab() {
    if (_loadingBons && _bons.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_errorBons != null && _bons.isEmpty) {
      return _errorList(_errorBons!, () => _loadBons(reset: true));
    }

    if (_bons.isEmpty) {
      return const EmptyStateScrollable(
        icon: Icons.receipt_long_outlined,
        title: 'Aucun bon émis',
        subtitle: 'Vos bons d\'envoi validés apparaîtront ici.',
      );
    }

    return ListView.builder(
      controller: _bonsScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: _bons.length + (_loadingBonsMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _bons.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        return _buildBonCard(_bons[index]);
      },
    );
  }

  Widget _buildDemandesTab() {
    if (_loadingDemandes && _demandes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_errorDemandes != null && _demandes.isEmpty) {
      return _errorList(_errorDemandes!, _loadDemandesAndMeta);
    }

    if (_demandes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
        children: [
          _buildEligibiliteHeader(),
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.35,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 56,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Aucune demande',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Vos demandes de bon enregistrées apparaîtront ici.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
      children: [
        _buildEligibiliteHeader(),
        if (!_afficherBanniereEligibilite) _workflowInfoBanner(),
        ..._demandes.map(_buildDemandeCard),
      ],
    );
  }

  Widget _workflowInfoBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Après validation par un agent, un bon d\'envoi et un jeton médical '
              'liés sont générés ensemble.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eligibiliteBanner(String text) {
    final isDossierIncomplet = text.toLowerCase().contains('incomplet');
    final accent = isDossierIncomplet
        ? AppColors.warningColor
        : Colors.orange.shade800;
    final bg = isDossierIncomplet
        ? AppColors.warningColor.withValues(alpha: 0.1)
        : Colors.orange.withValues(alpha: 0.1);
    final border = isDossierIncomplet
        ? AppColors.warningColor.withValues(alpha: 0.35)
        : Colors.orange.withValues(alpha: 0.35);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDossierIncomplet
                ? Icons.folder_off_outlined
                : Icons.info_outline,
            size: 20,
            color: accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDossierIncomplet) ...[
                  Text(
                    'Dossier incomplet',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorList(String message, Future<void> Function() onRetry) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.4,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBonCard(BonEnvoiModel b) {
    final color = b.estUtilise ? Colors.grey.shade700 : AppColors.prosocGreen;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => BonEnvoiDetailSheet.show(context, b),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.numeroBon.isNotEmpty
                              ? 'Bon ${b.numeroBon}'
                              : 'Bon #${b.idBonEnvoi}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        if (b.prestationNom.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            b.prestationNom,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          [
                            if (b.dateEmission != null)
                              'Émis ${AppFormatters.formatDate(b.dateEmission)}',
                            if (b.hasJetonLie && b.jetonMedicalCode.isNotEmpty)
                              'Jeton ${b.jetonMedicalCode}',
                            if (b.dateUtilisation != null)
                              'Utilisé ${AppFormatters.formatDate(b.dateUtilisation)}',
                          ].where((s) => s.isNotEmpty).join(' · '),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      b.statutLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Center(
                child: BonEnvoiQrView(
                  qrCodeImageBase64: b.qrCodeImageBase64,
                  qrCodePayload: b.qrCodePayload,
                  size: 140,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Voir le détail',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.prosocGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.prosocGreen,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemandeCard(DemandeBonEnvoiModel d) {
    final statut = d.statutDemande.isNotEmpty ? d.statutDemande : 'En cours';
    final color = _demandeStatutColor(statut);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    d.prestationNom.isNotEmpty
                        ? d.prestationNom
                        : (d.typeDemande.isNotEmpty
                            ? d.typeDemande
                            : 'Demande #${d.idDemande}'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statut,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            if (d.typeDemande.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                d.typeDemande,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
            if (d.motifDemande.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                d.motifDemande,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              [
                if (d.dateDemande != null)
                  AppFormatters.formatDate(d.dateDemande),
                if (d.bonEnvoiNumero.isNotEmpty) 'Bon ${d.bonEnvoiNumero}',
                if (d.jetonMedicalCode.isNotEmpty)
                  'Jeton ${d.jetonMedicalCode}',
              ].where((s) => s.isNotEmpty).join(' · '),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            if (d.hasCoupleBonJeton && d.hasQr) ...[
              const SizedBox(height: 12),
              Center(
                child: BonEnvoiQrView(
                  qrCodeImageBase64: d.qrCodeImageBase64,
                  qrCodePayload: d.qrCodePayload,
                  size: 120,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
