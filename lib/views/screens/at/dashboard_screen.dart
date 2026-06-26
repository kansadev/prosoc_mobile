import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/dashboard_agent_model.dart';
import '../../../models/dashboard_agent_graphs_model.dart';
import '../../../navigation/app_route_observer.dart';
import '../../../services/auth_service.dart';
import '../../../utils/api_error_helper.dart';
import 'widgets/dashboard_agent_charts_section.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with RouteAware, WidgetsBindingObserver {
  DashboardAgentModel? _dashboardData;
  DashboardAgentGraphsModel? _graphsData;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  DateTime? _lastUpdatedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadDashboardData(silent: _dashboardData != null);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _loadDashboardData(silent: _dashboardData != null);
    }
  }

  Future<void> _loadDashboardData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else if (_dashboardData != null) {
      setState(() => _isRefreshing = true);
    }

    try {
      if (AuthService.userId == null) {
        setState(() {
          _errorMessage = 'Utilisateur non connecté';
          _isLoading = false;
          _isRefreshing = false;
        });
        return;
      }

      final results = await Future.wait([
        ApiService.getDashboardAgentTerrain(),
        ApiService.getDashboardAgentGraphs(),
      ]);
      final terrainResponse =
          results[0] as ApiResponse<DashboardAgentModel>;
      final graphsResponse =
          results[1] as ApiResponse<DashboardAgentGraphsModel>;

      if (!mounted) return;

      if (terrainResponse.success && terrainResponse.data != null) {
        setState(() {
          _dashboardData = terrainResponse.data;
          _graphsData = graphsResponse.success ? graphsResponse.data : null;
          _errorMessage = null;
          _isLoading = false;
          _isRefreshing = false;
          _lastUpdatedAt = DateTime.now();
        });
      } else {
        final message =
            terrainResponse.message ??
            ApiErrorHelper.userFacingMessage(
              statusCode: terrainResponse.statusCode,
            );
        setState(() {
          if (!silent || _dashboardData == null) {
            _errorMessage = message;
          }
          _isLoading = false;
          _isRefreshing = false;
        });
        if (silent && _dashboardData != null) {
          _showRefreshSnackBar(message, isError: true);
        }
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('DashboardScreen', e, stackTrace, false);
      if (!mounted) return;
      final message = ApiErrorHelper.userFacingNetwork();
      setState(() {
        if (!silent || _dashboardData == null) {
          _errorMessage = message;
        }
        _isLoading = false;
        _isRefreshing = false;
      });
      if (silent && _dashboardData != null) {
        _showRefreshSnackBar(message, isError: true);
      }
    }
  }

  void _showRefreshSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : AppColors.prosocGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String? get _lastUpdatedLabel {
    final updatedAt = _lastUpdatedAt;
    if (updatedAt == null) return null;
    return 'Mis à jour à ${DateFormat('HH:mm').format(updatedAt)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '—';
    return DateFormat("dd MMM · HH:mm", 'fr_FR').format(date);
  }

  double _progressValue(double ratio) {
    if (ratio <= 0) return 0;
    if (ratio > 1) return (ratio / 100).clamp(0, 1);
    return ratio.clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        ),
        title: const Text(
          'Tableau de bord',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFFF4F6F8),
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.prosocGreen,
                  ),
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Actualiser',
              onPressed: () => _loadDashboardData(silent: _dashboardData != null),
              icon: const Icon(Icons.refresh_rounded, size: 22),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.prosocGreen,
        onRefresh: () async {
          await _loadDashboardData(silent: _dashboardData != null);
          if (mounted && _dashboardData != null && _errorMessage == null) {
            _showRefreshSnackBar('Dashboard actualisé', isError: false);
          }
        },
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _dashboardData == null) {
      return _buildShimmerLoading();
    }

    if (_errorMessage != null && _dashboardData == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.22),
          _buildErrorView(),
        ],
      );
    }

    if (_dashboardData == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.22),
          _buildEmptyView(),
        ],
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: _buildDashboardContent(_dashboardData!, graphs: _graphsData),
    );
  }

  Widget _buildDashboardContent(
    DashboardAgentModel dashboard, {
    DashboardAgentGraphsModel? graphs,
  }) {
    final kpis = dashboard.kpis;
    final commissions = dashboard.commissions;
    final primes = dashboard.primes;
    final objectifs = dashboard.objectifs;
    final devise = dashboard.devisePrincipaleCode.toUpperCase();
    final fmt = dashboard.formatMontant;

    final adherentsAlerte = dashboard.suiviAdherents
        .where((a) => a.hasAlerte || !a.cotisationAJour)
        .take(5)
        .toList();
    final mouvements = commissions.mouvementsRecents.take(6).toList();
    final primesRecentes = primes.details.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dashboard.nomAgent.isNotEmpty
                        ? 'Bonjour, ${dashboard.nomAgent.split(' ').first}'
                        : 'Bonjour',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (_lastUpdatedLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _lastUpdatedLabel!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _deviseChip(devise),
          ],
        ),
        const SizedBox(height: 14),
        _insightCard(dashboard.messageSynthese),
        const SizedBox(height: 16),
        _heroCard(
          dashboard: dashboard,
          soldeWallet: fmt(commissions.soldeWallet),
          collectesMois: fmt(kpis.totalCollectesMois),
          commissionsMois: fmt(kpis.totalCommissionsMois),
          operations: kpis.collectesMois,
        ),
        const SizedBox(height: 20),
        _sectionTitle('Indicateurs du mois'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _kpiTile(
                label: 'Affiliés',
                value: '${kpis.totalAffilies}',
                icon: Icons.people_alt_outlined,
                color: const Color(0xFF5C6BC0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiTile(
                label: 'Nouvelles adhésions',
                value: '${kpis.nouvellesAdhesionsMois}',
                icon: Icons.person_add_alt_1_outlined,
                color: AppColors.prosocGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _kpiTile(
                label: 'Moyenne / collecte',
                value: fmt(kpis.moyenneCollecte),
                icon: Icons.analytics_outlined,
                color: const Color(0xFF26A69A),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiTile(
                label: 'Taux conversion',
                value: DashboardAgentModel.formatRatioPercent(
                  kpis.tauxConversion,
                ),
                icon: Icons.trending_up_rounded,
                color: const Color(0xFFFF9800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionTitle(
          'Objectifs · ${DateFormat.MMMM('fr_FR').format(DateTime(objectifs.annee, objectifs.mois))} ${objectifs.annee}',
        ),
        const SizedBox(height: 10),
        _objectifCard(
          label: 'Collectes',
          valeur: fmt(kpis.totalCollectesMois),
          objectif: fmt(objectifs.objectifCollectes),
          progression: _progressValue(objectifs.progressionCollectes),
          progressionLabel: DashboardAgentModel.formatRatioPercent(
            objectifs.progressionCollectes,
          ),
        ),
        const SizedBox(height: 10),
        _objectifCard(
          label: 'Adhésions',
          valeur: '${objectifs.progressionAdhesions}',
          objectif: '${objectifs.objectifAdhesions}',
          progression: objectifs.objectifAdhesions > 0
              ? (objectifs.progressionAdhesions / objectifs.objectifAdhesions)
                  .clamp(0, 1)
              : 0,
          progressionLabel:
              '${objectifs.progressionAdhesions} / ${objectifs.objectifAdhesions}',
        ),
        const SizedBox(height: 10),
        _objectifCard(
          label: 'Commissions',
          valeur: fmt(commissions.totalCommissionsMois),
          objectif: fmt(objectifs.objectifCommissions),
          progression: _progressValue(objectifs.progressionCommissions),
          progressionLabel: DashboardAgentModel.formatRatioPercent(
            objectifs.progressionCommissions,
          ),
        ),
        if (graphs != null && graphs.hasData) ...[
          const SizedBox(height: 20),
          DashboardAgentChartsSection(
            graphs: graphs,
            formatMontant: fmt,
          ),
        ],
        const SizedBox(height: 20),
        _sectionTitle('Primes & souscriptions'),
        const SizedBox(height: 10),
        _primesSummaryCard(
          dashboard: dashboard,
          totalPrimes: fmt(primes.totalPrimesMois),
          mutuelle: fmt(primes.totalPrimesMutuelleMois),
          assurance: fmt(primes.totalPrimesAssuranceMois),
          nombre: primes.nombreSouscriptionsMois,
        ),
        if (primesRecentes.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...primesRecentes.map(
            (p) => _primeTile(dashboard: dashboard, prime: p),
          ),
        ],
        const SizedBox(height: 20),
        _sectionTitle('Commissions récentes'),
        const SizedBox(height: 10),
        if (mouvements.isEmpty)
          _emptySection('Aucun mouvement de commission ce mois')
        else
          ...mouvements.map(
            (m) => _mouvementTile(dashboard: dashboard, mouvement: m),
          ),
        const SizedBox(height: 20),
        _sectionTitle('Suivi adhérents'),
        const SizedBox(height: 10),
        if (adherentsAlerte.isEmpty)
          _emptySection('Tous vos adhérents sont à jour')
        else
          ...adherentsAlerte.map(
            (a) => _suiviTile(dashboard: dashboard, adherent: a),
          ),
        const SizedBox(height: 20),
        _sectionTitle('Affiliés récents'),
        const SizedBox(height: 10),
        if (dashboard.affiliesRecents.isEmpty)
          _emptySection('Aucun affilié récent')
        else
          ...dashboard.affiliesRecents.take(5).map(
            (a) => _affilieRecentTile(dashboard: dashboard, affilie: a),
          ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _deviseChip(String devise) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.prosocGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.prosocGreen.withValues(alpha: 0.3)),
      ),
      child: Text(
        devise,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.prosocGreen,
        ),
      ),
    );
  }

  Widget _insightCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.prosocGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.insights_rounded,
            color: AppColors.prosocGreen,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCard({
    required DashboardAgentModel dashboard,
    required String soldeWallet,
    required String collectesMois,
    required String commissionsMois,
    required int operations,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.prosocGreen,
            AppColors.prosocGreen.withValues(alpha: 0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.prosocGreen.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Solde commissions',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            soldeWallet,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _heroMetric(
                  label: 'Collectes',
                  value: collectesMois,
                  sub: '$operations op.',
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withValues(alpha: 0.25),
              ),
              Expanded(
                child: _heroMetric(
                  label: 'Commissions',
                  value: commissionsMois,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMetric({
    required String label,
    required String value,
    String? sub,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(
              sub,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kpiTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _objectifCard({
    required String label,
    required String valeur,
    required String objectif,
    required double progression,
    required String progressionLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                progressionLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.prosocGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$valeur / $objectif',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progression,
              minHeight: 7,
              backgroundColor: Colors.grey.shade200,
              color: AppColors.prosocGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _primesSummaryCard({
    required DashboardAgentModel dashboard,
    required String totalPrimes,
    required String mutuelle,
    required String assurance,
    required int nombre,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            totalPrimes,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$nombre souscription(s) · Mutuelle $mutuelle · Assurance $assurance',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _primeTile({
    required DashboardAgentModel dashboard,
    required DashboardAgentPrimeDetail prime,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prime.nomProduit,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  prime.nomAffilie,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (prime.dateCollecte != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatDateTime(prime.dateCollecte),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dashboard.formatMontant(prime.montantPrime),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.prosocGreen,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                prime.typeProduit,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mouvementTile({
    required DashboardAgentModel dashboard,
    required DashboardAgentMouvementCommission mouvement,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Color(0xFF2196F3),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mouvement.nomAffilie.isNotEmpty
                      ? mouvement.nomAffilie
                      : mouvement.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateTime(mouvement.dateOperation),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Text(
            dashboard.formatMontant(mouvement.montant, withSign: true),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF2196F3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _suiviTile({
    required DashboardAgentModel dashboard,
    required DashboardAgentSuiviAdherent adherent,
  }) {
    final alertColor = adherent.cotisationAJour
        ? Colors.orange.shade700
        : Colors.red.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: alertColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  adherent.nomComplet,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              _statusChip(
                adherent.cotisationAJour ? 'À jour' : 'Retard',
                adherent.cotisationAJour
                    ? AppColors.prosocGreen
                    : Colors.red.shade700,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${adherent.codeAdhesion} · ${adherent.typeAdhesion.trim()}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            'Total collecté : ${dashboard.formatMontant(adherent.totalCollectes)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          if (adherent.alerte.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              adherent.alerte,
              style: TextStyle(
                fontSize: 11,
                color: alertColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _affilieRecentTile({
    required DashboardAgentModel dashboard,
    required DashboardAgentAffilieRecent affilie,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.prosocGreen.withValues(alpha: 0.12),
            child: Text(
              affilie.prenom.isNotEmpty
                  ? affilie.prenom[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: AppColors.prosocGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  affilie.nomComplet,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${affilie.nombreCollectes} collecte(s) · ${_formatDate(affilie.dateAdhesion)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dashboard.formatMontant(affilie.derniereCollecte),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                'dernière',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _emptySection(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      ),
    );
  }

  Widget _shimmerBlock({double? width, required double height, double radius = 12}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _shimmerBlock(height: 28, radius: 6),
          const SizedBox(height: 14),
          _shimmerBlock(height: 72, radius: 14),
          const SizedBox(height: 14),
          _shimmerBlock(height: 140, radius: 18),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _shimmerBlock(height: 100)),
              const SizedBox(width: 10),
              Expanded(child: _shimmerBlock(height: 100)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 56, color: Colors.red.shade400),
          const SizedBox(height: 16),
          const Text(
            'Impossible de charger le dashboard',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Une erreur est survenue',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _loadDashboardData(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.prosocGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return const Column(
      children: [
        Icon(Icons.dashboard_outlined, size: 56, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          'Aucune donnée disponible',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
      ],
    );
  }
}
