import 'package:flutter/material.dart';
import 'package:prosoc/config/api.dart';
import 'package:prosoc/config/colors.dart';
import 'package:prosoc/models/affilie_paiement_historique_model.dart';
import 'package:prosoc/models/dashboard_affilie_model.dart';
import 'package:prosoc/utils/api_error_helper.dart';
import 'package:prosoc/utils/formatters.dart';
import 'package:prosoc/utils/paginated_response_helper.dart';
import 'package:prosoc/views/screens/adh%C3%A9rent/widgets/payer_contributionScreen.dart';
import 'package:prosoc/views/widgets/dashboard_segment_tab_bar.dart';
import 'package:prosoc/views/widgets/empty_state_widget.dart';
import 'package:prosoc/views/widgets/year_picker_sheet.dart';

/// Cotisations affilié :
/// - GET /api/DashboardAffilie/cotisations/{affilieId}?annee= (retards)
/// - GET /api/Affilie/paiements/historique
class ContributionsScreen extends StatefulWidget {
  final int affilieId;
  final String affilieNom;
  final String affiliePrenom;
  final String screenTitle;
  final String paymentFabLabel;
  final bool showBackButton;

  const ContributionsScreen({
    super.key,
    required this.affilieId,
    required this.affilieNom,
    required this.affiliePrenom,
    this.screenTitle = 'Mes cotisations',
    this.paymentFabLabel = 'Payer',
    this.showBackButton = false,
  });

  @override
  State<ContributionsScreen> createState() => _ContributionsScreenState();
}

class _ContributionsScreenState extends State<ContributionsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _historiqueScrollController = ScrollController();

  List<DashboardAffilieCotisation> _enRetard = [];
  List<AffiliePaiementHistoriqueModel> _historique = [];

  bool _loadingRetards = false;
  bool _loadingHistorique = false;
  bool _loadingHistoriqueMore = false;
  String? _errorRetards;
  String? _errorHistorique;

  int _historiquePage = 1;
  bool _historiqueHasNext = false;

  int _selectedYear = DateTime.now().year;

  static const _historiquePageSize = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _historiqueScrollController.addListener(_onHistoriqueScroll);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _historiqueScrollController.dispose();
    super.dispose();
  }

  void _onHistoriqueScroll() {
    if (!_historiqueHasNext || _loadingHistoriqueMore || _loadingHistorique) {
      return;
    }
    if (_historiqueScrollController.position.pixels >=
        _historiqueScrollController.position.maxScrollExtent - 200) {
      _loadHistorique();
    }
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadRetards(),
      _loadHistorique(reset: true),
    ]);
  }

  List<AffiliePaiementHistoriqueModel> _filterHistoriqueForAffilie(
    List<AffiliePaiementHistoriqueModel> items,
  ) {
    return items
        .where(
          (p) =>
              p.affilieId == 0 || p.affilieId == widget.affilieId,
        )
        .where((p) => p.annee == 0 || p.annee == _selectedYear)
        .toList();
  }

  String _historiqueErrorMessage(ApiResponse<Map<String, dynamic>> response) {
    return ApiErrorHelper.historiquePaiementsUnavailable(
      statusCode: response.statusCode,
    );
  }

  Future<void> _loadHistorique({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loadingHistorique = true;
        _errorHistorique = null;
        _historiquePage = 1;
        _historiqueHasNext = false;
      });
    } else {
      if (!_historiqueHasNext) return;
      setState(() => _loadingHistoriqueMore = true);
    }

    try {
      final response = await ApiService.getAffiliePaiementsHistorique(
        page: reset ? 1 : _historiquePage,
        pageSize: _historiquePageSize,
      );

      if (!mounted) return;

      final payload = response.data;
      if (response.success && payload != null) {
        final rows = PaginatedResponseHelper.extractRows(payload);
        final parsed = <AffiliePaiementHistoriqueModel>[];
        for (final item in rows) {
          if (item is! Map) continue;
          try {
            final map = item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item);
            parsed.add(AffiliePaiementHistoriqueModel.fromJson(map));
          } catch (e, st) {
            ApiErrorHelper.logException('PaiementHistorique/json', e, st);
          }
        }

        final filtered = _filterHistoriqueForAffilie(parsed);

        setState(() {
          if (reset) {
            _historique = filtered;
          } else {
            _historique = [..._historique, ...filtered];
          }
          _historiqueHasNext = PaginatedResponseHelper.extractHasNext(payload);
          if (_historiqueHasNext) {
            _historiquePage =
                PaginatedResponseHelper.extractCurrentPage(payload) + 1;
          }
          _errorHistorique = null;
          _loadingHistorique = false;
          _loadingHistoriqueMore = false;
        });
      } else {
        setState(() {
          if (reset) {
            _historique = [];
            _errorHistorique = _historiqueErrorMessage(response);
          }
          _loadingHistorique = false;
          _loadingHistoriqueMore = false;
        });
      }
    } catch (e, st) {
      ApiErrorHelper.logException('Paiements/historique', e, st, false);
      if (!mounted) return;
      setState(() {
        if (reset) {
          _errorHistorique = ApiErrorHelper.userFacingNetwork();
          _historique = [];
        }
        _loadingHistorique = false;
        _loadingHistoriqueMore = false;
      });
    }
  }

  Future<void> _loadRetards() async {
    setState(() {
      _loadingRetards = true;
      _errorRetards = null;
    });

    try {
      final response = await ApiService.getDashboardAffilieCotisations(
        widget.affilieId,
        annee: _selectedYear,
      );
      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _enRetard =
              response.data!.where((c) => c.estEnRetard).toList()
                ..sort((a, b) => b.joursRetard.compareTo(a.joursRetard));
          _loadingRetards = false;
        });
      } else {
        setState(() {
          _errorRetards = response.message ??
              ApiErrorHelper.userFacingMessage(
                statusCode: response.statusCode,
              );
          _loadingRetards = false;
        });
      }
    } catch (e, st) {
      ApiErrorHelper.logException('Cotisations/retards', e, st, false);
      if (!mounted) return;
      setState(() {
        _errorRetards = ApiErrorHelper.userFacingNetwork();
        _loadingRetards = false;
      });
    }
  }

  Future<void> _onYearChanged(int year) async {
    setState(() => _selectedYear = year);
    await Future.wait([
      _loadRetards(),
      _loadHistorique(reset: true),
    ]);
  }

  Future<void> _openPaiement() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PayerContributionScreen(
          affilieId: widget.affilieId,
          affilieNom: widget.affilieNom,
          affiliePrenom: widget.affiliePrenom,
        ),
      ),
    );
    if (ok == true && mounted) await _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.screenTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: widget.showBackButton,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
        actions: [
          YearPickerButton(
            selectedYear: _selectedYear,
            sheetTitle: 'Année des cotisations',
            sheetSubtitle: 'Filtre Retards et Historique',
            onYearSelected: _onYearChanged,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_adherent_cotisations',
        onPressed: _openPaiement,
        backgroundColor: AppColors.prosocGreen,
        icon: const Icon(Icons.payment, color: Colors.white),
        label: Text(
          widget.paymentFabLabel,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: DashboardSegmentTabScaffold(
        controller: _tabController,
        tabs: [
          DashboardSegmentTabItem(
            label: 'Historique',
            badgeCount: _historique.length,
          ),
          DashboardSegmentTabItem(
            label: 'Retards',
            badgeCount: _enRetard.length,
            showBadgeOnlyIfPositive: true,
          ),
        ],
        children: [
          _buildHistoriqueTab(),
          _buildRetardsTab(),
        ],
      ),
    );
  }

  Widget _buildRetardsTab() {
    return _buildListTab(
      loading: _loadingRetards,
      error: _errorRetards,
      items: _enRetard,
      emptyIcon: Icons.check_circle_outline,
      emptyTitle: 'Aucun retard',
      emptySubtitle: 'Toutes vos cotisations $_selectedYear sont à jour.',
      onRefresh: _loadRetards,
      highlightRetard: true,
    );
  }

  Widget _buildHistoriqueTab() {
    if (_loadingHistorique && _historique.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.prosocGreen),
      );
    }

    if (_errorHistorique != null && _historique.isEmpty) {
      return _buildHistoriqueErrorState(
        _errorHistorique!,
        () => _loadHistorique(reset: true),
      );
    }

    if (_historique.isEmpty) {
      return RefreshIndicator(
        color: AppColors.prosocGreen,
        onRefresh: () => _loadHistorique(reset: true),
        child: EmptyStateScrollable(
          icon: Icons.history,
          title: 'Aucun paiement',
          subtitle: 'Aucun paiement enregistré pour $_selectedYear.',
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.prosocGreen,
      onRefresh: () => _loadHistorique(reset: true),
      child: ListView.separated(
        controller: _historiqueScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        itemCount:
            _historique.length + (_loadingHistoriqueMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= _historique.length) {
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
          return _buildPaiementHistoriqueCard(_historique[index]);
        },
      ),
    );
  }

  Widget _buildPaiementHistoriqueCard(AffiliePaiementHistoriqueModel p) {
    final statut = p.statutPaiement.toUpperCase();
    final isOk = statut == 'OK' ||
        statut == 'PAYE' ||
        statut == 'VALIDE' ||
        statut == 'SUCCESS' ||
        statut == 'REUSSI';
    final accent = isOk ? AppColors.prosocGreen : Colors.orange.shade800;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.history, color: accent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.displayTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (p.typeCollecte.isNotEmpty)
                        Text(
                          p.typeCollecte,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      if (p.dateCollecte != null)
                        Text(
                          AppFormatters.formatDateTime(p.dateCollecte),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppFormatters.formatCurrencyDollar(p.montant),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    if (p.statutPaiement.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _buildStatutBadge(p.statutPaiement, false),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                if (p.referencePaiement.isNotEmpty)
                  _detailRow(
                    Icons.tag_outlined,
                    'Référence',
                    p.referencePaiement,
                  ),
                if (p.modePaiement.isNotEmpty)
                  _detailRow(
                    Icons.payment_outlined,
                    'Mode',
                    _formatModePaiement(p.modePaiement),
                  ),
                if (p.operateur.isNotEmpty)
                  _detailRow(Icons.phone_android, 'Opérateur', p.operateur),
                if (p.montantAttendu > 0)
                  _detailRow(
                    Icons.account_balance_wallet_outlined,
                    'Montant attendu',
                    AppFormatters.formatCurrencyDollar(p.montantAttendu),
                  ),
                if (p.montantRecu > 0)
                  _detailRow(
                    Icons.payments_outlined,
                    'Montant reçu',
                    AppFormatters.formatCurrencyDollar(p.montantRecu),
                  ),
                if (p.deviseCode.isNotEmpty)
                  _detailRow(Icons.currency_exchange, 'Devise', p.deviseCode),
                if (p.agentNom.isNotEmpty)
                  _detailRow(Icons.person_outline, 'Agent', p.agentNom),
                if (p.cotisationPeriodicite.isNotEmpty)
                  _detailRow(
                    Icons.repeat,
                    'Périodicité',
                    p.cotisationPeriodicite,
                  ),
                if (p.observation.isNotEmpty)
                  _detailRow(
                    Icons.notes_outlined,
                    'Observation',
                    p.observation,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTab({
    required bool loading,
    required String? error,
    required List<DashboardAffilieCotisation> items,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
    required Future<void> Function() onRefresh,
    bool highlightRetard = false,
  }) {
    if (loading && items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.prosocGreen),
      );
    }

    if (error != null && items.isEmpty) {
      return _buildErrorState(error, onRefresh);
    }

    if (items.isEmpty) {
      return RefreshIndicator(
        color: AppColors.prosocGreen,
        onRefresh: onRefresh,
        child: EmptyStateScrollable(
          icon: emptyIcon,
          title: emptyTitle,
          subtitle: emptySubtitle,
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.prosocGreen,
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _buildCotisationDetailCard(
          items[i],
          highlightRetard: highlightRetard || items[i].estEnRetard,
        ),
      ),
    );
  }

  Widget _buildCotisationDetailCard(
    DashboardAffilieCotisation c, {
    required bool highlightRetard,
  }) {
    final accent = highlightRetard ? AppColors.errorColor : AppColors.prosocGreen;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlightRetard
              ? AppColors.errorColor.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.receipt_long_outlined, color: accent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.typeCotisation.isNotEmpty
                            ? c.typeCotisation
                            : 'Cotisation',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (c.dateCotisation != null)
                        Text(
                          AppFormatters.formatDateTime(c.dateCotisation),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppFormatters.formatCurrencyDollar(c.montant),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    if (c.statut.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _buildStatutBadge(c.statut, c.estEnRetard),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Détails
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                if (c.reference.isNotEmpty)
                  _detailRow(Icons.tag_outlined, 'Référence', c.reference),
                if (c.modePaiement.isNotEmpty)
                  _detailRow(
                    Icons.payment_outlined,
                    'Mode de paiement',
                    _formatModePaiement(c.modePaiement),
                  ),
                if (c.periodicite.isNotEmpty)
                  _detailRow(Icons.repeat, 'Périodicité', c.periodicite),
                if (c.agentCollecteur.isNotEmpty)
                  _detailRow(
                    Icons.person_outline,
                    'Agent collecteur',
                    c.agentCollecteur,
                  ),
                if (c.cumulMois > 0 || c.cumulAnnee > 0)
                  _detailRow(
                    Icons.stacked_line_chart,
                    'Cumuls',
                    'Mois : ${AppFormatters.formatCurrencyDollar(c.cumulMois)}'
                        ' · Année : ${AppFormatters.formatCurrencyDollar(c.cumulAnnee)}',
                  ),
                if (c.estEnRetard)
                  _detailRow(
                    Icons.warning_amber_rounded,
                    'Retard',
                    '${c.joursRetard} jour(s)',
                    valueColor: AppColors.errorColor,
                  ),
              ],
            ),
          ),

          if (c.estEnRetard)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openPaiement,
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text('Régulariser'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.prosocGreen,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatutBadge(String statut, bool enRetard) {
    final s = statut.toUpperCase();
    Color bg;
    Color fg;
    String label = statut;

    if (enRetard) {
      bg = AppColors.errorColor.withValues(alpha: 0.12);
      fg = AppColors.errorColor;
      label = 'En retard';
    } else if (s == 'OK' || s == 'PAYE' || s == 'VALIDE') {
      bg = AppColors.prosocGreen.withValues(alpha: 0.12);
      fg = AppColors.prosocGreen;
    } else if (s == 'EN_ATTENTE') {
      bg = Colors.orange.withValues(alpha: 0.12);
      fg = Colors.orange.shade800;
      label = 'En attente';
    } else {
      bg = Colors.grey.shade200;
      fg = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  String _formatModePaiement(String mode) {
    switch (mode.toUpperCase()) {
      case 'VIRTUAL_ACCOUNT':
        return 'Compte virtuel';
      case 'MOBILE_MONEY':
        return 'Mobile Money';
      case 'CARTE_BANCAIRE':
        return 'Carte bancaire';
      case 'ESPECE':
        return 'Espèces';
      default:
        return mode;
    }
  }

  Widget _buildHistoriqueErrorState(
    String message,
    Future<void> Function() onRetry,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: Colors.orange.shade700.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Historique indisponible',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.prosocGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, Future<void> Function() onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.prosocGreen,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
