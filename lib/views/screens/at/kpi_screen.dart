import 'package:flutter/material.dart';
import 'package:prosoc/config/api.dart';
import 'package:prosoc/config/colors.dart';
import 'package:prosoc/models/kpi_agent_model.dart';
import 'package:prosoc/utils/api_error_helper.dart';
import 'package:shimmer/shimmer.dart';

class KpiScreen extends StatefulWidget {
  const KpiScreen({super.key});

  @override
  State<KpiScreen> createState() => _KpiScreenState();
}

class _KpiScreenState extends State<KpiScreen> {
  KpiAgentModel? _kpiData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadKpis();
  }

  Future<void> _loadKpis({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final response = await ApiService.getAgentKpis();

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _kpiData = response.data;
          _error = null;
          _isLoading = false;
        });
      } else {
        setState(() {
          if (!silent || _kpiData == null) {
            _error = response.message ??
                ApiErrorHelper.userFacingMessage(
                  statusCode: response.statusCode,
                );
          }
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException('KpiScreen', e, stackTrace, false);
      if (!mounted) return;
      setState(() {
        if (!silent || _kpiData == null) {
          _error = ApiErrorHelper.userFacingNetwork();
        }
        _isLoading = false;
      });
    }
  }

  Widget _shimmerBlock({
    double? width,
    required double height,
    double radius = 12,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBlock(height: 180, radius: 20),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _shimmerBlock(height: 130, radius: 16)),
              const SizedBox(width: 16),
              Expanded(child: _shimmerBlock(height: 130, radius: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _shimmerBlock(height: 130, radius: 16)),
              const SizedBox(width: 16),
              Expanded(child: _shimmerBlock(height: 130, radius: 16)),
            ],
          ),
          const SizedBox(height: 20),
          _shimmerBlock(height: 200, radius: 16),
          const SizedBox(height: 16),
          _shimmerBlock(height: 110, radius: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        ),
        title: const Text(
          'Indicateurs KPI',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: AppColors.prosocGreen,
        onRefresh: () => _loadKpis(silent: _kpiData != null),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _kpiData == null) {
      return _buildShimmerLoading();
    }

    if (_error != null && _kpiData == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          _buildErrorView(),
        ],
      );
    }

    if (_kpiData == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          _buildEmptyView(),
        ],
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildObjectiveHeader(),
          const SizedBox(height: 24),
          _buildSectionTitle('Vue d\'ensemble'),
          const SizedBox(height: 12),
          _buildMainKpisGrid(),
          const SizedBox(height: 24),
          _buildSectionTitle('Détails'),
          const SizedBox(height: 12),
          _buildDetailedCards(),
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

  Widget _buildObjectiveHeader() {
    final progress = _kpiData!.progressionBarValue;
    final progressionLabel = _kpiData!.progressionLabel;
    final progressionPercent = progress * 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.prosocGreen.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Objectif du mois',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Progression actuelle',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _kpiData!.formattedObjectif,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$progressionLabel atteint',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Reste ${(100 - progressionPercent).clamp(0, 100).toStringAsFixed(1)} %',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainKpisGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'Total affiliés',
                value: _kpiData!.totalAffilies.toString(),
                icon: Icons.people_outline_rounded,
                color: AppColors.prosocGreen,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildKpiCard(
                title: 'Nouvelles adhésions',
                value: _kpiData!.nouvellesAdhesionsMois.toString(),
                icon: Icons.person_add_alt_1_rounded,
                color: const Color(0xFF2196F3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'Collectes',
                value: _kpiData!.collectesMois.toString(),
                icon: Icons.payments_outlined,
                color: const Color(0xFFFF9800),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildKpiCard(
                title: 'En attente',
                value: _kpiData!.collectesEnAttente.toString(),
                icon: Icons.hourglass_top_rounded,
                color: const Color(0xFF9C27B0),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedCards() {
    return Column(
      children: [
        _buildFinancialSummaryCard(),
        const SizedBox(height: 14),
        _buildConversionRateCard(),
      ],
    );
  }

  Widget _buildFinancialSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.prosocGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.prosocGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Résumé financier',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildFinancialItem(
            'Total collecté',
            _kpiData!.formattedTotalCollectes,
            highlighted: true,
          ),
          const Divider(height: 24),
          _buildFinancialItem(
            'Commissions',
            _kpiData!.formattedCommissions,
          ),
          const Divider(height: 24),
          _buildFinancialItem(
            'Moyenne / collecte',
            _kpiData!.formattedMoyenneCollecte,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialItem(
    String label,
    String value, {
    bool highlighted = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: highlighted ? AppColors.textPrimary : Colors.grey.shade600,
            fontWeight: highlighted ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: highlighted ? AppColors.prosocGreen : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildConversionRateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.prosocGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.prosocGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: AppColors.prosocGreen,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Taux de conversion',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _kpiData!.formattedTauxConversion,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.prosocGreen,
                  ),
                ),
              ],
            ),
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
            'Impossible de charger les KPI',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Une erreur est survenue',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _loadKpis(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.prosocGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return const Column(
      children: [
        Icon(Icons.bar_chart_rounded, size: 56, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          'Aucune donnée KPI disponible',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
      ],
    );
  }
}
