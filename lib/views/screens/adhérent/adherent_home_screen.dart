import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/dashboard_affilie_model.dart';
import '../../../services/auth_service.dart';
import '../../../utils/api_error_helper.dart';
import '../../../utils/formatters.dart';
import '../../widgets/adherent_cotisations_chart.dart';
import '../../widgets/year_picker_sheet.dart';

/// Accueil / dashboard affilié — données `/api/DashboardAffilie/resume/{affilieId}`.
class AdherentHomeScreen extends StatefulWidget {
  final VoidCallback? onPayCotisation;
  final VoidCallback? onOpenDemandeBon;
  final VoidCallback? onOpenDependants;

  const AdherentHomeScreen({
    super.key,
    this.onPayCotisation,
    this.onOpenDemandeBon,
    this.onOpenDependants,
  });

  @override
  State<AdherentHomeScreen> createState() => _AdherentHomeScreenState();
}

class _AdherentHomeScreenState extends State<AdherentHomeScreen> {
  DashboardAffilieResumeModel? _data;
  List<DashboardAffilieCotisation> _cotisationsRecentes = [];
  List<DashboardAffilieCotisation> _cotisationsPeriode = [];
  bool _isLoading = true;
  bool _loadingCotisations = false;
  String? _errorMessage;
  late int _selectedYear;
  int? _filterMois;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    _loadDashboard();
  }

  Future<void> _loadDashboard({bool silent = false}) async {
    final affilieId = AuthService.affilieId;
    if (affilieId == null || affilieId <= 0) {
      setState(() {
        _errorMessage =
            'Profil affilié introuvable. Reconnectez-vous ou contactez le support.';
        _isLoading = false;
      });
      return;
    }

    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait([
        ApiService.getDashboardAffilieResume(affilieId, annee: _selectedYear),
        ApiService.getDashboardAffilieCotisationsRecentes(affilieId, limit: 10),
        ApiService.getDashboardAffilieCotisations(
          affilieId,
          annee: _selectedYear,
          mois: _filterMois,
        ),
      ]);

      if (!mounted) return;

      final resumeResponse =
          results[0] as ApiResponse<DashboardAffilieResumeModel>;
      final recentesResponse =
          results[1] as ApiResponse<List<DashboardAffilieCotisation>>;
      final periodeResponse =
          results[2] as ApiResponse<List<DashboardAffilieCotisation>>;

      if (resumeResponse.success && resumeResponse.data != null) {
        setState(() {
          _data = resumeResponse.data;
          _cotisationsRecentes = recentesResponse.success
              ? (recentesResponse.data ?? [])
              : _cotisationsRecentes;
          _cotisationsPeriode = periodeResponse.success
              ? (periodeResponse.data ?? [])
              : _cotisationsPeriode;
          _errorMessage = null;
          _isLoading = false;
          _loadingCotisations = false;
        });
      } else {
        setState(() {
          if (!silent || _data == null) {
            _errorMessage =
                resumeResponse.message ??
                ApiErrorHelper.userFacingMessage(
                  statusCode: resumeResponse.statusCode,
                );
          }
          _isLoading = false;
          _loadingCotisations = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('AdherentHome', e, stackTrace, false);
      if (!mounted) return;
      setState(() {
        if (!silent || _data == null) {
          _errorMessage = ApiErrorHelper.userFacingNetwork();
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _onYearChanged(int year) async {
    setState(() {
      _selectedYear = year;
      _filterMois = null;
    });
    await _loadDashboard();
  }

  Future<void> _reloadCotisationsPeriode(int? mois) async {
    final affilieId = AuthService.affilieId;
    if (affilieId == null) return;

    setState(() {
      _filterMois = mois;
      _loadingCotisations = true;
    });

    try {
      final response = await ApiService.getDashboardAffilieCotisations(
        affilieId,
        annee: _selectedYear,
        mois: mois,
      );
      if (!mounted) return;
      setState(() {
        if (response.success && response.data != null) {
          _cotisationsPeriode = response.data!;
        }
        _loadingCotisations = false;
      });
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'AdherentHome/cotisations',
        e,
        stackTrace,
        false,
      );
      if (mounted) setState(() => _loadingCotisations = false);
    }
  }

  String _displayName() {
    final fromApi = _data?.informations.nomComplet.trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    return AuthService.userName ?? 'Adhérent';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenue,',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            Text(
              _displayName(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          YearPickerButton(
            selectedYear: _selectedYear,
            sheetTitle: 'Année du résumé',
            sheetSubtitle: 'Dashboard et cotisations affichés pour cette année',
            onYearSelected: _onYearChanged,
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textPrimary,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.prosocGreen,
        onRefresh: () => _loadDashboard(silent: _data != null),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _data == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [_buildShimmer()],
      );
    }

    if (_errorMessage != null && _data == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          _buildErrorState(),
        ],
      );
    }

    if (_data == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: _buildContent(_data!),
    );
  }

  Widget _buildContent(DashboardAffilieResumeModel data) {
    final kpis = data.kpis;
    final info = data.informations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (info.codeAdhesion.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'N° adhésion : ${info.codeAdhesion}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
        _buildBalanceCard(kpis),
        const SizedBox(height: 8),
        _buildSectionTitle('Actions rapides'),
        const SizedBox(height: 12),
        _buildQuickActions(),
        const SizedBox(height: 20),
        _buildKpiRow(kpis),
        if (kpis.montantPlafond > 0) ...[
          const SizedBox(height: 16),
          _buildPlafondCard(kpis),
        ],
        const SizedBox(height: 24),
        _buildCotisationsChartSection(data),
        const SizedBox(height: 24),
        _buildCotisationsSection(),

        if (data.documentsEnAttente.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionTitle('Documents en attente'),
          const SizedBox(height: 8),
          ...data.documentsEnAttente.take(3).map(_buildDocumentTile),
        ],
        if (data.prestationsRecentes.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionTitle('Prestations récentes'),
          const SizedBox(height: 8),
          ...data.prestationsRecentes.take(5).map(_buildPrestationTile),
        ],
        if (data.notificationsRecentes.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionTitle('Notifications'),
          const SizedBox(height: 8),
          ...data.notificationsRecentes.take(5).map(_buildNotificationTile),
        ],
        if (data.beneficiaires.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionTitle('Bénéficiaires (${data.beneficiaires.length})'),
          const SizedBox(height: 8),
          ...data.beneficiaires.take(4).map(_buildBeneficiaireChip),
        ],
      ],
    );
  }

  Widget _buildBalanceCard(DashboardAffilieKpis kpis) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.prosocGreen,
            AppColors.prosocGreen.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Solde disponible',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            AppFormatters.formatCurrencyDollar(kpis.soldeDisponible),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Solde total : ${AppFormatters.formatCurrencyDollar(kpis.soldeTotal)}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (kpis.nombreBeneficiaires > 0)
                _chip(
                  Icons.people_outline,
                  '${kpis.nombreBeneficiaires} bénéficiaire(s)',
                ),
              if (kpis.ancienneteMois > 0)
                _chip(Icons.schedule, '${kpis.ancienneteMois} mois'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCotisationsChartSection(DashboardAffilieResumeModel data) {
    final mensuelles =
        data.graphiques?.forYear(_selectedYear) ??
        <DashboardAffilieCotisationMensuelle>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Évolution des cotisations'),
        const SizedBox(height: 12),
        AdherentCotisationsChart(data: mensuelles, annee: _selectedYear),
        if (data.graphiques?.resumeAnnuel != null &&
            data.graphiques!.resumeAnnuel!.annee == _selectedYear) ...[
          const SizedBox(height: 10),
          _buildResumeAnnuelChip(data.graphiques!.resumeAnnuel!),
        ],
      ],
    );
  }

  Widget _buildResumeAnnuelChip(DashboardAffilieResumeAnnuel resume) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.prosocGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Résumé ${resume.annee} · Cotisations '
        '${AppFormatters.formatCurrencyDollar(resume.totalCotisations)} · '
        'Utilisation moy. ${resume.tauxUtilisationMoyen.toStringAsFixed(0)}%',
        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildCotisationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Cotisations récentes'),
        const SizedBox(height: 4),
        Text(
          'Dernières opérations enregistrées',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),
        if (_cotisationsRecentes.isEmpty)
          _buildEmptyCotisations('Aucune cotisation récente.')
        else
          ..._cotisationsRecentes.map(_buildCotisationTile),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildSectionTitle(
                _filterMois == null
                    ? 'Cotisations $_selectedYear'
                    : 'Cotisations — ${_monthLabel(_filterMois!)} $_selectedYear',
              ),
            ),
            if (_loadingCotisations)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _buildMonthFilterChips(),
        const SizedBox(height: 10),
        if (_cotisationsPeriode.isEmpty && !_loadingCotisations)
          _buildEmptyCotisations(
            _filterMois == null
                ? 'Aucune cotisation pour $_selectedYear.'
                : 'Aucune cotisation pour ce mois.',
          )
        else
          ..._cotisationsPeriode.map(_buildCotisationTile),
      ],
    );
  }

  Widget _buildEmptyCotisations(String message) {
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
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildMonthFilterChips() {
    const moisLabels = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('Toute l\'année'),
            selected: _filterMois == null,
            onSelected: (_) => _reloadCotisationsPeriode(null),
            selectedColor: AppColors.prosocGreen.withValues(alpha: 0.2),
            checkmarkColor: AppColors.prosocGreen,
          ),
          const SizedBox(width: 6),
          for (var m = 1; m <= 12; m++)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(moisLabels[m - 1]),
                selected: _filterMois == m,
                onSelected: (_) => _reloadCotisationsPeriode(m),
                selectedColor: AppColors.prosocGreen.withValues(alpha: 0.2),
                checkmarkColor: AppColors.prosocGreen,
              ),
            ),
        ],
      ),
    );
  }

  String _monthLabel(int mois) {
    const labels = [
      '',
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    if (mois >= 1 && mois <= 12) return labels[mois];
    return '$mois';
  }

  Widget _buildKpiRow(DashboardAffilieKpis kpis) {
    return Row(
      children: [
        Expanded(
          child: _miniStat(
            'Cotisations',
            AppFormatters.formatCurrencyDollar(kpis.totalCotisations),
            Icons.payments_outlined,
            AppColors.prosocGreen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniStat(
            'Prestations',
            AppFormatters.formatCurrencyDollar(kpis.totalPrestations),
            Icons.medical_services_outlined,
            const Color(0xFF2196F3),
          ),
        ),
      ],
    );
  }

  Widget _miniStat(String title, String value, IconData icon, Color color) {
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
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlafondCard(DashboardAffilieKpis kpis) {
    final used = kpis.montantPlafond - kpis.restePlafond;
    final ratio = kpis.montantPlafond > 0
        ? (used / kpis.montantPlafond).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plafond annuel',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: AppColors.prosocGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reste : ${AppFormatters.formatCurrencyDollar(kpis.restePlafond)} / '
            '${AppFormatters.formatCurrencyDollar(kpis.montantPlafond)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          if (kpis.tauxCouverture > 0)
            Text(
              'Couverture : ${kpis.tauxCouverture.toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _quickAction(
            Icons.add_circle_outline,
            'Payer',
            AppColors.prosocGreen,
            widget.onPayCotisation,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickAction(
            Icons.receipt_long_outlined,
            'Demande Bon',
            Colors.blue,
            widget.onOpenDemandeBon,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickAction(
            Icons.people,
            'Dépendants',
            Colors.orange,
            () => widget.onOpenDependants?.call(),
          ),
        ),
      ],
    );
  }

  Widget _quickAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback? onTap,
  ) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCotisationTile(DashboardAffilieCotisation c) {
    return _listTile(
      icon: Icons.receipt_long_outlined,
      title: c.typeCotisation.isNotEmpty ? c.typeCotisation : 'Cotisation',
      subtitle: [
        if (c.reference.isNotEmpty) c.reference,
        if (c.dateCotisation != null)
          AppFormatters.formatDate(c.dateCotisation),
        if (c.modePaiement.isNotEmpty) c.modePaiement,
        if (c.agentCollecteur.isNotEmpty) c.agentCollecteur,
        if (c.statut.isNotEmpty) c.statut,
        if (c.estEnRetard) 'Retard ${c.joursRetard} j',
      ].where((s) => s.isNotEmpty).join(' · '),
      trailing: AppFormatters.formatCurrencyDollar(c.montant),
      trailingColor: c.estEnRetard
          ? AppColors.errorColor
          : AppColors.prosocGreen,
    );
  }

  Widget _buildPrestationTile(DashboardAffiliePrestation p) {
    return _listTile(
      icon: Icons.local_hospital_outlined,
      title: p.prestationNom.isNotEmpty ? p.prestationNom : p.typePrestation,
      subtitle: [
        if (p.beneficiaire.isNotEmpty) p.beneficiaire,
        if (p.datePrestation != null)
          AppFormatters.formatDate(p.datePrestation),
        p.statut,
      ].where((s) => s.isNotEmpty).join(' · '),
      trailing: AppFormatters.formatCurrencyDollar(p.montantPriseEnCharge),
      trailingColor: const Color(0xFF2196F3),
    );
  }

  Widget _buildNotificationTile(DashboardAffilieNotification n) {
    return _listTile(
      icon: n.estLue ? Icons.notifications_none : Icons.notifications_active,
      title: n.titre.isNotEmpty ? n.titre : n.typeNotification,
      subtitle: n.message,
      trailing: n.dateNotification != null
          ? AppFormatters.formatDate(n.dateNotification)
          : null,
      trailingColor: Colors.grey.shade600,
    );
  }

  Widget _buildDocumentTile(DashboardAffilieDocument d) {
    return _listTile(
      icon: Icons.description_outlined,
      title: d.nomDocument.isNotEmpty ? d.nomDocument : d.typeDocument,
      subtitle: d.estObligatoire ? 'Obligatoire' : 'Facultatif',
      trailing: d.estValide ? 'Validé' : 'En attente',
      trailingColor: d.estValide
          ? AppColors.prosocGreen
          : AppColors.warningColor,
    );
  }

  Widget _buildBeneficiaireChip(DashboardAffilieBeneficiaire b) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _listTile(
        icon: Icons.person_outline,
        title: b.nomComplet,
        subtitle: [
          if (b.lienParente.isNotEmpty) b.lienParente,
          b.typeBeneficiaire,
          if (!b.estActif) 'Inactif',
        ].where((s) => s.isNotEmpty).join(' · '),
        trailing: b.estPrincipal ? 'Principal' : null,
        trailingColor: AppColors.prosocGreen,
      ),
    );
  }

  Widget _listTile({
    required IconData icon,
    required String title,
    required String subtitle,
    String? trailing,
    Color? trailingColor,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.prosocGreen, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Text(
              trailing,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: trailingColor ?? AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Erreur',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loadDashboard,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.prosocGreen,
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
