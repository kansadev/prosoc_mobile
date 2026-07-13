import 'package:flutter/material.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/souscription_prestation_model.dart';
import '../../../services/auth_service.dart';
import '../../../utils/api_error_helper.dart';
import '../../../utils/formatters.dart';
import '../../widgets/dashboard_segment_tab_bar.dart';
import '../../widgets/year_picker_sheet.dart';
import '../../../widgets/souscription_bottom_sheet.dart';

/// Souscriptions prestation affilié — GET /api/SouscriptionPrestation/by-affilie/{affilieId}.
class AdherentPrestationScreen extends StatefulWidget {
  const AdherentPrestationScreen({super.key});

  @override
  State<AdherentPrestationScreen> createState() =>
      _AdherentPrestationScreenState();
}

class _AdherentPrestationScreenState extends State<AdherentPrestationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  List<SouscriptionPrestationModel> _all = [];
  List<SouscriptionPrestationModel> _recentes = [];
  List<SouscriptionPrestationModel> _periode = [];

  bool _loading = false;
  String? _error;

  int _selectedYear = DateTime.now().year;
  int? _selectedMonth;

  static const _moisLabels = [
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSouscriptions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int? get _affilieId => AuthService.affilieId;

  void _applyFilters() {
    final now = DateTime.now();
    final recentCutoff = now.subtract(const Duration(days: 90));

    bool inYear(SouscriptionPrestationModel s) {
      final d = s.dateSouscription ?? s.dateCreation;
      if (d == null) return false;
      if (d.year != _selectedYear) return false;
      if (_selectedMonth != null && d.month != _selectedMonth) return false;
      return true;
    }

    final sorted = List<SouscriptionPrestationModel>.from(_all)
      ..sort((a, b) {
        final da = a.dateSouscription ?? a.dateCreation;
        final db = b.dateSouscription ?? b.dateCreation;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });

    _recentes = sorted.where((s) {
      final d = s.dateSouscription ?? s.dateCreation;
      return d != null && !d.isBefore(recentCutoff);
    }).toList();

    _periode = sorted.where(inYear).toList();
  }

  Future<void> _loadSouscriptions() async {
    final affilieId = _affilieId;
    if (affilieId == null || affilieId <= 0) {
      setState(() {
        _error =
            'Profil affilié introuvable. Reconnectez-vous ou contactez le support.';
        _loading = false;
        _all = [];
        _recentes = [];
        _periode = [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response =
          await ApiService.getSouscriptionsPrestationByAffilie(affilieId);
      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _all = response.data!;
          _applyFilters();
          _loading = false;
        });
      } else {
        setState(() {
          _error =
              response.message ??
              ApiErrorHelper.userFacingMessage(
                statusCode: response.statusCode,
              );
          _all = [];
          _recentes = [];
          _periode = [];
          _loading = false;
        });
      }
    } catch (e, st) {
      ApiErrorHelper.logException('SouscriptionPrestation', e, st, false);
      if (!mounted) return;
      setState(() {
        _error = ApiErrorHelper.userFacingNetwork();
        _all = [];
        _recentes = [];
        _periode = [];
        _loading = false;
      });
    }
  }

  void _onYearChanged(int year) {
    setState(() {
      _selectedYear = year;
      _selectedMonth = null;
      _applyFilters();
    });
  }

  void _onMonthChanged(int? month) {
    setState(() {
      _selectedMonth = month;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Mes souscriptions',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          YearPickerButton(
            selectedYear: _selectedYear,
            sheetTitle: 'Année des souscriptions',
            sheetSubtitle: 'Filtrer l\'onglet Période par année',
            onYearSelected: _onYearChanged,
          ),
        ],
      ),
      body: DashboardSegmentTabScaffold(
        controller: _tabController,
        indicatorColor: AppColors.prosocGreen,
        tabs: [
          DashboardSegmentTabItem(
            label: 'Récentes',
            badgeCount: _recentes.length,
          ),
          DashboardSegmentTabItem(
            label: 'Période',
            badgeCount: _periode.length,
          ),
        ],
        children: [_buildRecentesTab(), _buildPeriodeTab()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNouvelleSouscription,
        backgroundColor: AppColors.prosocGreen,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Souscrire'),
      ),
    );
  }

  Future<void> _openNouvelleSouscription() async {
    final affilieId = _affilieId;
    if (affilieId == null || affilieId <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil affilié introuvable.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    final utilisateur = AuthService.currentUser?.utilisateur;
    final nomComplet = utilisateur?.nomComplet ?? '';
    final parts = nomComplet.trim().split(RegExp(r'\s+'));
    final prenom = parts.isNotEmpty ? parts.first : '';
    final nom = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    final created = await SouscriptionBottomSheet.show(
      context,
      affilieId: affilieId,
      affilieNom: nom,
      affiliePrenom: prenom,
      affilieTelephone: utilisateur?.telephone,
      allowVirtualAccount: false,
    );

    if (created == true && mounted) {
      await _loadSouscriptions();
    }
  }

  Widget _buildRecentesTab() {
    return _buildListTab(
      items: _recentes,
      emptyTitle: 'Aucune souscription récente',
      emptySubtitle:
          'Les souscriptions des 90 derniers jours apparaîtront ici.',
    );
  }

  Widget _buildPeriodeTab() {
    return Column(
      children: [
        _buildMonthChips(),
        Expanded(
          child: _buildListTab(
            items: _periode,
            emptyTitle: 'Aucune souscription',
            emptySubtitle: _selectedMonth == null
                ? 'Aucune souscription pour $_selectedYear.'
                : 'Aucune souscription pour ${_moisLabels[_selectedMonth! - 1]} $_selectedYear.',
          ),
        ),
      ],
    );
  }

  Widget _buildListTab({
    required List<SouscriptionPrestationModel> items,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (_loading && _all.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.prosocGreen),
      );
    }

    if (_error != null && _all.isEmpty) {
      return _buildErrorState(_error!, _loadSouscriptions);
    }

    if (items.isEmpty) {
      return RefreshIndicator(
        color: AppColors.prosocGreen,
        onRefresh: _loadSouscriptions,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.35,
              child: _buildEmptyState(
                title: emptyTitle,
                subtitle: emptySubtitle,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.prosocGreen,
      onRefresh: _loadSouscriptions,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _buildSouscriptionCard(items[i]),
      ),
    );
  }

  Widget _buildMonthChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Toute l\'année'),
            selected: _selectedMonth == null,
            onSelected: (_) => _onMonthChanged(null),
            selectedColor: AppColors.prosocGreen.withValues(alpha: 0.2),
            checkmarkColor: AppColors.prosocGreen,
          ),
          const SizedBox(width: 6),
          for (var m = 1; m <= 12; m++)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(_moisLabels[m - 1]),
                selected: _selectedMonth == m,
                onSelected: (_) => _onMonthChanged(m),
                selectedColor: AppColors.prosocGreen.withValues(alpha: 0.2),
                checkmarkColor: AppColors.prosocGreen,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 56,
              color: AppColors.prosocGreen.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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

  Widget _buildSouscriptionCard(SouscriptionPrestationModel s) {
    final title = s.prestationNom.trim().isNotEmpty
        ? s.prestationNom.trim()
        : 'Prestation #${s.prestationId}';
    final description = s.prestationDescription.trim();
    final date = s.dateSouscription ?? s.dateCreation;

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
              color: AppColors.prosocGreen.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  color: AppColors.prosocGreen,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (date != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Souscrit le ${AppFormatters.formatDate(date)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildStatutBadge(s.statut),
              ],
            ),
          ),
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.35,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                _detailRow(
                  Icons.payments_outlined,
                  'Collectes',
                  '${s.nombreCollectes}',
                ),
                _detailRow(
                  Icons.account_balance_wallet_outlined,
                  'Total collecté',
                  AppFormatters.formatCurrencyDollar(s.totalCollectes),
                ),
                if (s.affilieNom.isNotEmpty || s.affiliePrenom.isNotEmpty)
                  _detailRow(
                    Icons.person_outline,
                    'Affilié',
                    '${s.affiliePrenom} ${s.affilieNom}'.trim(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
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
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatutBadge(bool actif) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: actif
            ? AppColors.prosocGreen.withValues(alpha: 0.12)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        actif ? 'Actif' : 'Inactif',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: actif ? AppColors.prosocGreen : Colors.red,
        ),
      ),
    );
  }
}
