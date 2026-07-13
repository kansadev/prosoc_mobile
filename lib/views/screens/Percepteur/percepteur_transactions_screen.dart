import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/api.dart';
import '../../../config/colors.dart';
import '../../../models/dashboard_percepteur_model.dart';
import '../../../utils/api_error_helper.dart';
import '../../widgets/dashboard_segment_tab_bar.dart';

// ============================================
// TRANSACTIONS PERCEPTEUR
// GET /api/DashboardPercepteur/transactions
// GET /api/DashboardPercepteur/evolution-transactions
// ============================================
class PercepteurTransactionsScreen extends StatefulWidget {
  /// Masque le bouton retour lorsque l'écran est un onglet de navigation.
  final bool embeddedInNavigation;

  const PercepteurTransactionsScreen({
    super.key,
    this.embeddedInNavigation = false,
  });

  @override
  State<PercepteurTransactionsScreen> createState() =>
      _PercepteurTransactionsScreenState();
}

class _PercepteurTransactionsScreenState
    extends State<PercepteurTransactionsScreen>
    with SingleTickerProviderStateMixin {
  static const int _pageLimit = 50;
  static const List<int> _moisOptions = [3, 6, 12];

  late final TabController _tabController;

  List<PercepteurTransaction> _transactions = [];
  List<PercepteurEvolutionTransaction> _evolution = [];
  bool _isLoading = true;
  bool _isLoadingEvolution = false;
  String? _errorMessage;
  String _deviseCode = 'CDF';
  int _selectedMois = 6;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _isLoadingEvolution = true;
      _errorMessage = null;
    });

    try {
      final txResponse = await ApiService.getDashboardPercepteurTransactions(
        limit: _pageLimit,
      );
      final evolutionResponse =
          await ApiService.getDashboardPercepteurEvolutionTransactions(
        mois: _selectedMois,
      );
      final summaryResponse = await ApiService.getDashboardPercepteurSummary();

      if (!mounted) return;

      final devise = summaryResponse.data?.kpis?.devisePrincipaleCode;

      if (txResponse.success && txResponse.data != null) {
        setState(() {
          _transactions = txResponse.data!;
          if (evolutionResponse.success && evolutionResponse.data != null) {
            _evolution = evolutionResponse.data!;
          }
          if (devise != null && devise.isNotEmpty) _deviseCode = devise;
          _isLoading = false;
          _isLoadingEvolution = false;
        });
      } else {
        setState(() {
          _errorMessage = ApiErrorHelper.messageForApiFailure(
            statusCode: txResponse.statusCode,
            serverDetail: txResponse.message,
            fallback: 'Impossible de charger les transactions.',
          );
          _isLoading = false;
          _isLoadingEvolution = false;
        });
      }
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'PercepteurTransactions/load',
        e,
        stackTrace,
        false,
      );
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiErrorHelper.userFacingNetwork();
        _isLoading = false;
        _isLoadingEvolution = false;
      });
    }
  }

  Future<void> _loadEvolutionOnly() async {
    setState(() => _isLoadingEvolution = true);

    try {
      final response = await ApiService.getDashboardPercepteurEvolutionTransactions(
        mois: _selectedMois,
      );

      if (!mounted) return;

      setState(() {
        if (response.success && response.data != null) {
          _evolution = response.data!;
        }
        _isLoadingEvolution = false;
      });
    } catch (e, stackTrace) {
      ApiErrorHelper.logException(
        'PercepteurTransactions/evolution',
        e,
        stackTrace,
        false,
      );
      if (mounted) setState(() => _isLoadingEvolution = false);
    }
  }

  void _onMoisChanged(int mois) {
    if (_selectedMois == mois) return;
    setState(() => _selectedMois = mois);
    _loadEvolutionOnly();
  }

  String _formatMontant(double value) =>
      '${value.toStringAsFixed(0)} $_deviseCode';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embeddedInNavigation,
        leading: widget.embeddedInNavigation
            ? null
            : IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
              ),
        title: const Text(
          'Transactions',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _transactions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.prosocGreen),
      );
    }

    if (_errorMessage != null && _transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.prosocGreen,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        DashboardSegmentTabBar(
          controller: _tabController,
          tabs: [
            const DashboardSegmentTabItem(label: 'Évolution'),
            DashboardSegmentTabItem(
              label: 'Historique',
              badgeCount: _transactions.length,
              showBadgeOnlyIfPositive: true,
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              RefreshIndicator(
                color: AppColors.prosocGreen,
                onRefresh: _loadData,
                child: _buildEvolutionTab(),
              ),
              RefreshIndicator(
                color: AppColors.prosocGreen,
                onRefresh: _loadData,
                child: _buildHistoriqueTab(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEvolutionTab() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        _EvolutionSection(
          evolution: _evolution,
          isLoading: _isLoadingEvolution,
          selectedMois: _selectedMois,
          moisOptions: _moisOptions,
          formatMontant: _formatMontant,
          onMoisChanged: _onMoisChanged,
        ),
      ],
    );
  }

  Widget _buildHistoriqueTab() {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    if (_transactions.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'Aucune transaction',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: _transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _TransactionTile(
          transaction: _transactions[index],
          dateFormat: dateFormat,
          formatMontant: _formatMontant,
        );
      },
    );
  }
}

class _EvolutionSection extends StatelessWidget {
  final List<PercepteurEvolutionTransaction> evolution;
  final bool isLoading;
  final int selectedMois;
  final List<int> moisOptions;
  final String Function(double) formatMontant;
  final ValueChanged<int> onMoisChanged;

  const _EvolutionSection({
    required this.evolution,
    required this.isLoading,
    required this.selectedMois,
    required this.moisOptions,
    required this.formatMontant,
    required this.onMoisChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Période',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              ...moisOptions.map((mois) {
                final selected = mois == selectedMois;
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: ChoiceChip(
                    label: Text('$mois mois'),
                    selected: selected,
                    onSelected: (_) => onMoisChanged(mois),
                    selectedColor: AppColors.prosocGreen.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? AppColors.prosocGreen
                          : Colors.grey.shade700,
                    ),
                    side: BorderSide(
                      color: selected
                          ? AppColors.prosocGreen.withValues(alpha: 0.4)
                          : Colors.grey.shade300,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading && evolution.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.prosocGreen,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (evolution.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Aucune donnée d\'évolution sur la période.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            )
          else ...[
            _EvolutionBarChart(
              evolution: evolution,
              formatMontant: formatMontant,
            ),
            const SizedBox(height: 16),
            ...evolution.map(
              (item) => _EvolutionPeriodTile(
                item: item,
                formatMontant: formatMontant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EvolutionBarChart extends StatelessWidget {
  final List<PercepteurEvolutionTransaction> evolution;
  final String Function(double) formatMontant;

  const _EvolutionBarChart({
    required this.evolution,
    required this.formatMontant,
  });

  @override
  Widget build(BuildContext context) {
    final maxMontant = evolution
        .map((e) => e.montantTotal)
        .fold<double>(0, (a, b) => a > b ? a : b);

    if (maxMontant <= 0) return const SizedBox.shrink();

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: evolution.map((item) {
          final ratio = item.montantTotal / maxMontant;
          final barHeight = (100 * ratio).clamp(8.0, 100.0);
          final label = _shortPeriode(item.periode);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    item.nombreTransactions > 0
                        ? '${item.nombreTransactions}'
                        : '',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    height: barHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.prosocGreen,
                          AppColors.prosocGreen.withValues(alpha: 0.65),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _shortPeriode(String periode) {
    if (periode.length <= 6) return periode;
    return periode.length > 8 ? periode.substring(0, 8) : periode;
  }
}

class _EvolutionPeriodTile extends StatelessWidget {
  final PercepteurEvolutionTransaction item;
  final String Function(double) formatMontant;

  const _EvolutionPeriodTile({
    required this.item,
    required this.formatMontant,
  });

  @override
  Widget build(BuildContext context) {
    final croissance = item.tauxCroissance;
    final croissanceColor = croissance >= 0 ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.periode.isNotEmpty ? item.periode : 'Période',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                formatMontant(item.montantTotal),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.prosocGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _miniLabel('${item.nombreTransactions} tx'),
              _miniLabel('Moy. ${formatMontant(item.montantMoyen)}'),
              if (item.netAPercevoir > 0)
                _miniLabel('Net ${formatMontant(item.netAPercevoir)}'),
              if (croissance != 0)
                Text(
                  '${croissance >= 0 ? '+' : ''}${croissance.toStringAsFixed(1)} %',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: croissanceColor.shade700,
                  ),
                ),
              if (item.tauxSucces > 0)
                _miniLabel('Succès ${item.tauxSucces.toStringAsFixed(0)} %'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniLabel(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final PercepteurTransaction transaction;
  final DateFormat dateFormat;
  final String Function(double) formatMontant;

  const _TransactionTile({
    required this.transaction,
    required this.dateFormat,
    required this.formatMontant,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = transaction.dateTransaction != null
        ? dateFormat.format(transaction.dateTransaction!.toLocal())
        : '—';
    final subtitle = transaction.buildSubtitle();
    final displayAmount = transaction.netAPercevoir > 0
        ? transaction.netAPercevoir
        : transaction.montant;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.prosocGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: AppColors.prosocGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  dateLabel,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                if (transaction.statut.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.prosocGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      transaction.statut,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.prosocGreen,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (displayAmount > 0) ...[
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatMontant(displayAmount),
                  style: const TextStyle(
                    color: AppColors.prosocGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (transaction.commission > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Com. ${formatMontant(transaction.commission)}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
