import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../config/colors.dart';
import '../../../../models/dashboard_agent_graphs_model.dart';

class DashboardAgentChartsSection extends StatelessWidget {
  final DashboardAgentGraphsModel graphs;
  final String Function(double) formatMontant;

  const DashboardAgentChartsSection({
    super.key,
    required this.graphs,
    required this.formatMontant,
  });

  @override
  Widget build(BuildContext context) {
    if (!graphs.hasData) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (graphs.collectesMensuelles.isNotEmpty) ...[
          _sectionTitle('Évolution des collectes'),
          const SizedBox(height: 10),
          _chartCard(
            child: _BarChartPanel(
              items: graphs.collectesMensuelles
                  .map(
                    (e) => _BarChartItem(
                      label: _shortMonthLabel(e.mois),
                      value: e.montant,
                      badge: e.nombreCollectes > 0
                          ? '${e.nombreCollectes}'
                          : null,
                    ),
                  )
                  .toList(),
              color: AppColors.prosocGreen,
            ),
            footer: graphs.collectesMensuelles
                .map(
                  (e) =>
                      '${_shortMonthLabel(e.mois)} : ${formatMontant(e.montant)} (${e.nombreCollectes} op.)',
                )
                .join(' · '),
          ),
          const SizedBox(height: 20),
        ],
        if (graphs.adhesionsMensuelles.isNotEmpty) ...[
          _sectionTitle('Adhésions mensuelles'),
          const SizedBox(height: 10),
          _chartCard(
            child: _BarChartPanel(
              items: graphs.adhesionsMensuelles
                  .map(
                    (e) => _BarChartItem(
                      label: _shortMonthLabel(e.mois),
                      value: e.nombreAdhesions.toDouble(),
                      badge: e.nombreAdhesions > 0
                          ? '${e.nombreAdhesions}'
                          : null,
                    ),
                  )
                  .toList(),
              color: const Color(0xFF5C6BC0),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (graphs.commissionsMensuelles.isNotEmpty) ...[
          _sectionTitle('Commissions mensuelles'),
          const SizedBox(height: 10),
          _chartCard(
            child: _BarChartPanel(
              items: graphs.commissionsMensuelles
                  .map(
                    (e) => _BarChartItem(
                      label: _shortMonthLabel(e.mois),
                      value: e.montant,
                      badge: e.montant > 0 ? formatMontant(e.montant) : null,
                    ),
                  )
                  .toList(),
              color: const Color(0xFF2196F3),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (graphs.repartitionPrestations.isNotEmpty) ...[
          _sectionTitle('Répartition des prestations'),
          const SizedBox(height: 10),
          _chartCard(
            child: Column(
              children: graphs.repartitionPrestations.map(_prestationRow).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (graphs.activiteQuotidienne.isNotEmpty) ...[
          _sectionTitle('Activité des 30 derniers jours'),
          const SizedBox(height: 10),
          _chartCard(
            child: _BarChartPanel(
              items: graphs.activiteQuotidienne
                  .map(
                    (e) => _BarChartItem(
                      label: e.date != null
                          ? DateFormat('dd/MM').format(e.date!)
                          : '—',
                      value: e.montantCollectes,
                      badge: e.nombreCollectes > 0
                          ? '${e.nombreCollectes}'
                          : null,
                    ),
                  )
                  .toList(),
              color: const Color(0xFF26A69A),
              dense: true,
            ),
            footer: _activiteSummary(),
          ),
        ],
      ],
    );
  }

  String _activiteSummary() {
    final totalCollectes = graphs.activiteQuotidienne.fold<int>(
      0,
      (sum, e) => sum + e.nombreCollectes,
    );
    final totalMontant = graphs.activiteQuotidienne.fold<double>(
      0,
      (sum, e) => sum + e.montantCollectes,
    );
    final totalAdhesions = graphs.activiteQuotidienne.fold<int>(
      0,
      (sum, e) => sum + e.nombreAdhesions,
    );
    return '$totalCollectes collecte(s) · ${formatMontant(totalMontant)} · $totalAdhesions adhésion(s)';
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

  Widget _chartCard({required Widget child, String? footer}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child,
          if (footer != null && footer.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              footer,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _prestationRow(DashboardAgentRepartitionPrestation item) {
    final ratio = (item.pourcentage / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.nomPrestation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '${item.pourcentage.toStringAsFixed(1)} %',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.prosocGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${item.nombreSouscriptions} souscription(s)'
            '${item.montantTotal > 0 ? ' · ${formatMontant(item.montantTotal)}' : ''}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio > 0 ? ratio : null,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              color: AppColors.prosocGreen,
            ),
          ),
        ],
      ),
    );
  }

  static String _shortMonthLabel(String mois) {
    final trimmed = mois.trim();
    if (trimmed.isEmpty) return '—';

    final iso = DateTime.tryParse('$trimmed-01');
    if (iso != null) {
      return DateFormat('MMM', 'fr_FR').format(iso);
    }

    if (trimmed.length <= 5) return trimmed;
    return trimmed.length > 7 ? trimmed.substring(0, 7) : trimmed;
  }
}

class _BarChartItem {
  final String label;
  final double value;
  final String? badge;

  const _BarChartItem({
    required this.label,
    required this.value,
    this.badge,
  });
}

class _BarChartPanel extends StatelessWidget {
  final List<_BarChartItem> items;
  final Color color;
  final bool dense;

  const _BarChartPanel({
    required this.items,
    required this.color,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = items.fold<double>(
      0,
      (max, item) => item.value > max ? item.value : max,
    );

    if (maxValue <= 0) {
      return Text(
        'Aucune activité sur la période',
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      );
    }

    final height = dense ? 110.0 : 140.0;
    final maxBar = dense ? 80.0 : 100.0;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: items.map((item) {
          final ratio = item.value / maxValue;
          final barHeight = item.value > 0
              ? (maxBar * ratio).clamp(8.0, maxBar)
              : 2.0;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: dense ? 1 : 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (item.badge != null)
                    Text(
                      item.badge!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: dense ? 7 : 9,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    SizedBox(height: dense ? 10 : 14),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    height: barHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          color,
                          color.withValues(alpha: 0.65),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(dense ? 4 : 8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: dense ? 7 : 9,
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
}
