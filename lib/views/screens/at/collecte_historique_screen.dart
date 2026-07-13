import 'package:flutter/material.dart';
import 'package:prosoc/config/api.dart';
import 'package:prosoc/config/colors.dart';
import 'package:prosoc/models/adhesion_with_affilie_model.dart';
import 'package:prosoc/models/affilie_paiement_historique_model.dart';
import 'package:prosoc/services/auth_service.dart';
import 'package:prosoc/utils/api_error_helper.dart';
import 'package:prosoc/utils/currency_formatter.dart';
import 'package:prosoc/utils/formatters.dart';
import 'package:prosoc/views/widgets/dashboard_segment_tab_bar.dart';
import 'package:prosoc/views/widgets/empty_state_widget.dart';
import 'package:prosoc/views/widgets/prosoc_resource_error_view.dart';
import 'package:prosoc/views/widgets/prosoc_shimmer_loading.dart';

/// Historique des collectes agent.
/// - `GET /api/Collecte/by-agent/{agentId}` (onglet Tous)
/// - `GET /api/Collecte/by-type/{typeCollecte}` (Frais, Souscription, Cotisation)
class CollecteHistoriqueScreen extends StatefulWidget {
  const CollecteHistoriqueScreen({super.key});

  @override
  State<CollecteHistoriqueScreen> createState() =>
      _CollecteHistoriqueScreenState();
}

class _CollecteHistoriqueScreenState extends State<CollecteHistoriqueScreen>
    with SingleTickerProviderStateMixin {
  static const _tabLabels = ['Tous', 'Frais', 'Souscription', 'Cotisation'];
  static const _typeFilters = <String?>[
    null,
    AdhesionApiValues.typeCollecteFrais,
    AdhesionApiValues.typeCollecteSouscription,
    AdhesionApiValues.typeCollecteCotisation,
  ];

  late final TabController _tabController;

  List<AffiliePaiementHistoriqueModel> _collectes = [];
  bool _isLoading = true;
  String? _error;
  int? _errorStatusCode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadCollectes(reset: true);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _loadCollectes(reset: true);
  }

  int? get _agentId => AuthService.currentUser?.utilisateur.agentId;

  String? get _activeTypeFilter => _typeFilters[_tabController.index];

  Future<void> _loadCollectes({bool reset = false}) async {
    final agentId = _agentId;
    if (agentId == null) {
      setState(() {
        _error = 'Agent non identifié';
        _isLoading = false;
      });
      return;
    }

    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
        _errorStatusCode = null;
      });
    }

    final typeFilter = _activeTypeFilter;

    try {
      final ApiResponse<List<dynamic>> response;
      if (typeFilter == null) {
        response = await ApiService.getCollecteByAgent(agentId);
      } else {
        response = await ApiService.getCollecteByType(typeFilter);
      }

      if (!mounted) return;

      if (response.success && response.data != null) {
        var rows = ApiService.parseCollecteHistoriqueList(response.data);
        if (typeFilter != null) {
          rows = rows.where((c) => c.agentId == agentId).toList();
        }
        rows.sort(_compareCollecteDate);

        setState(() {
          _collectes = rows;
          _error = null;
          _errorStatusCode = null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message ??
              ApiErrorHelper.userFacingMessage(
                statusCode: response.statusCode,
              );
          _errorStatusCode = response.statusCode;
          if (reset) _collectes = [];
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('CollecteHistorique', e, stackTrace, false);
      if (!mounted) return;
      setState(() {
        if (reset || _collectes.isEmpty) {
          _error = ApiErrorHelper.userFacingNetwork();
        }
        _isLoading = false;
      });
    }
  }

  static int _compareCollecteDate(
    AffiliePaiementHistoriqueModel a,
    AffiliePaiementHistoriqueModel b,
  ) {
    final da = a.dateCollecte ?? a.dateCreation;
    final db = b.dateCollecte ?? b.dateCreation;
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return db.compareTo(da);
  }

  String get _emptySubtitle {
    switch (_tabController.index) {
      case 1:
        return 'Aucun frais collecté pour le moment.';
      case 2:
        return 'Aucune souscription collectée pour le moment.';
      case 3:
        return 'Aucune cotisation collectée pour le moment.';
      default:
        return 'Les collectes que vous enregistrez apparaîtront ici.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: const Text(
          'Historique des collectes',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: DashboardSegmentTabBar(
            controller: _tabController,
            tabs: [
              for (final label in _tabLabels)
                DashboardSegmentTabItem(label: label),
            ],
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _collectes.isEmpty) {
      return const ProsocLoadingShimmer.list(itemCount: 6);
    }

    if (_error != null && _collectes.isEmpty) {
      return ProsocResourceErrorView(
        message: _error!,
        statusCode: _errorStatusCode,
        onRetry: () => _loadCollectes(reset: true),
      );
    }

    if (_collectes.isEmpty) {
      return RefreshIndicator(
        color: AppColors.prosocGreen,
        onRefresh: () => _loadCollectes(reset: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.18),
            EmptyStateWidget(
              icon: Icons.payments_outlined,
              title: 'Aucune collecte',
              subtitle: _emptySubtitle,
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          color: AppColors.prosocGreen,
          onRefresh: () => _loadCollectes(reset: true),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: _collectes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _CollecteCard(
              collecte: _collectes[index],
            ),
          ),
        ),
        if (_isLoading)
          const Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: ProsocLoadingShimmer.inline(size: 28),
            ),
          ),
      ],
    );
  }
}

class _CollecteCard extends StatelessWidget {
  final AffiliePaiementHistoriqueModel collecte;

  const _CollecteCard({required this.collecte});

  Color _statutColor(String statut) {
    final normalized = statut.trim().toUpperCase();
    if (normalized.contains('REJET') ||
        normalized.contains('REFUS') ||
        normalized.contains('ECHEC')) {
      return Colors.red.shade700;
    }
    if (normalized.contains('VALID') ||
        normalized.contains('OK') ||
        normalized.contains('PAYE')) {
      return AppColors.prosocGreen;
    }
    if (normalized.contains('ATTENTE') || normalized.contains('PENDING')) {
      return Colors.orange.shade800;
    }
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final statutColor = _statutColor(collecte.statutPaiement);
    final date = collecte.dateCollecte ?? collecte.dateCreation;
    const tileColor = Colors.white;

    return Material(
      color: tileColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: AppColors.prosocGreen.withValues(alpha: 0.08),
          highlightColor: AppColors.prosocGreen.withValues(alpha: 0.04),
        ),
        child: ExpansionTile(
          backgroundColor: tileColor,
          collapsedBackgroundColor: tileColor,
          tilePadding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: AppColors.prosocGreen,
          collapsedIconColor: Colors.grey.shade600,
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collecte.formattedMontant,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      collecte.displayTitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (collecte.statutPaiement.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statutColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    collecte.statutPaiement,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statutColor,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collecte.typeCollecteLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (collecte.affilieNom.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    collecte.affilieNom,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
                if (date != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    AppFormatters.formatDateTime(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          children: [
            if (collecte.modePaiement.isNotEmpty)
              _detailRow('Mode', _formatModePaiement(collecte.modePaiement)),
            if (collecte.deviseCode.isNotEmpty)
              _detailRow(
                'Devise',
                collecte.deviseNom.isNotEmpty
                    ? '${collecte.deviseCode} — ${collecte.deviseNom}'
                    : collecte.deviseCode,
              ),
            if (collecte.montantRecu > 0)
              _detailRow('Montant reçu', collecte.formattedMontant),
            if (collecte.montantAttendu > 0 &&
                collecte.montantAttendu != collecte.montantRecu)
              _detailRow(
                'Montant attendu',
                CurrencyFormatter.formatMovementAmount(
                  amount: collecte.montantAttendu,
                  deviseId: collecte.deviseId > 0 ? collecte.deviseId : null,
                  deviseCode: collecte.deviseCode.isNotEmpty
                      ? collecte.deviseCode
                      : null,
                ),
              ),
            if (collecte.referencePaiement.isNotEmpty)
              _detailRow('Référence', collecte.referencePaiement),
            if (collecte.operateur.isNotEmpty)
              _detailRow('Opérateur', collecte.operateur),
            if (collecte.observation.isNotEmpty)
              _detailRow('Observation', collecte.observation),
            if (collecte.idCollecte > 0)
              _detailRow('N° collecte', '#${collecte.idCollecte}'),
          ],
        ),
      ),
    );
  }

  String _formatModePaiement(String mode) {
    switch (mode.trim().toUpperCase()) {
      case 'VIRTUAL_ACCOUNT':
        return 'Compte virtuel';
      case 'MOBILE_MONEY':
        return 'Mobile money';
      case 'CARTE_BANCAIRE':
        return 'Carte bancaire';
      default:
        return mode.replaceAll('_', ' ');
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
