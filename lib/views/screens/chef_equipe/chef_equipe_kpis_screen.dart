import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/colors.dart';
import '../../../controllers/chef_equipe_controller.dart';
import '../../../models/chef_equipe_model.dart';
import '../../../utils/currency_formatter.dart';
import '../../widgets/prosoc_resource_error_view.dart';

class ChefEquipeKpisScreen extends StatelessWidget {
  final ChefEquipeController controller;

  const ChefEquipeKpisScreen({super.key, required this.controller});

  /// Période des indicateurs : le DTO ne porte que des agrégats mensuels.
  String get _moisEnCoursLabel {
    final now = DateTime.now();
    final mois = DateFormat.MMMM('fr_FR').format(now);
    return '${mois.substring(0, 1).toUpperCase()}${mois.substring(1)} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.isLoading && !controller.hasLoaded) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.prosocGreen),
          );
        }

        if (controller.errorMessage != null) {
          return ProsocResourceErrorView(
            message: controller.errorMessage!,
            statusCode: controller.errorStatusCode,
            onRetry: () => controller.load(force: true),
          );
        }

        final kpis = controller.kpis;
        if (kpis == null) {
          return const Center(child: Text('Aucune donnée KPI disponible.'));
        }

        return RefreshIndicator(
          color: AppColors.prosocGreen,
          onRefresh: () => controller.load(force: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Vue analytique de votre zone',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _KpiSummaryCard(kpis: kpis)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Indicateurs clés',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.prosocGreen.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  size: 13,
                                  color: AppColors.prosocGreen,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _moisEnCoursLabel,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.prosocGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Les indicateurs de collecte sont calculés sur le '
                        'mois civil en cours. La plateforme n\'expose pas de '
                        'période personnalisée (jour, semaine ou autre mois).',
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _AnalyticsTile(
                        icon: Icons.groups_rounded,
                        label: 'Agents AT dans votre zone',
                        value: '${kpis.nombreAgentsAt}',
                      ),
                      const SizedBox(height: 8),
                      _AnalyticsTile(
                        icon: Icons.payments_rounded,
                        label: 'Nombre de collectes du mois',
                        value: '${kpis.collectesMoisZone}',
                      ),
                      const SizedBox(height: 8),
                      _AnalyticsTile(
                        icon: Icons.stacked_bar_chart_rounded,
                        label: 'Montant total des collectes du mois',
                        value: CurrencyFormatter.format(
                          amount: kpis.totalCollectesMoisZone,
                          deviseCode: kpis.devisePrincipaleCode,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _AnalyticsTile(
                        icon: Icons.pending_actions_rounded,
                        label: 'Collectes en attente de validation',
                        value: '${kpis.collectesEnAttenteZone}',
                      ),
                      const SizedBox(height: 8),
                      _AnalyticsTile(
                        icon: Icons.verified_rounded,
                        label: 'Transactions validées du mois',
                        value: '${kpis.transactionsValidesMoisZone}',
                      ),
                      const SizedBox(height: 8),
                      _AnalyticsTile(
                        icon: Icons.attach_money_rounded,
                        label: 'Devise principale de la zone',
                        value: kpis.devisePrincipaleCode?.toString() ?? '—',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnalyticsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AnalyticsTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.prosocGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.prosocGreen, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiSummaryCard extends StatelessWidget {
  final ChefEquipeKpisDto kpis;

  const _KpiSummaryCard({required this.kpis});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.prosocGreen.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              kpis.zoneSocialeNom?.toString().isNotEmpty == true
                  ? 'Zone ${kpis.zoneSocialeNom}'
                  : 'Zone ID ${kpis.zoneSocialeId}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Mois en cours · collectes en attente et transactions validées',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _summaryMetric(
                    '${kpis.collectesEnAttenteZone}',
                    'En attente',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _summaryMetric(
                    '${kpis.transactionsValidesMoisZone}',
                    'Validées',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryMetric(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
