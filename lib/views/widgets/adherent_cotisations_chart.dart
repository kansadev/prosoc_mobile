import 'package:flutter/material.dart';

import '../../config/colors.dart';
import '../../models/dashboard_affilie_model.dart';
import '../../utils/formatters.dart';

/// Histogramme des cotisations mensuelles (données `graphiques.cotisationsMensuelles`).
class AdherentCotisationsChart extends StatelessWidget {
  final List<DashboardAffilieCotisationMensuelle> data;
  final int annee;

  const AdherentCotisationsChart({
    super.key,
    required this.data,
    required this.annee,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          'Aucune donnée de cotisation pour $annee.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
      );
    }

    final maxMontant = data
        .map((e) => e.montantCotise)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final maxBar = maxMontant > 0 ? maxMontant : 1.0;
    final totalAnnee = data.fold<double>(0, (s, e) => s + e.montantCotise);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
              const Expanded(
                child: Text(
                  'Cotisations mensuelles',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$annee',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.prosocGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Total : ${AppFormatters.formatCurrencyDollar(totalAnnee)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((point) {
                final ratio = (point.montantCotise / maxBar).clamp(0.0, 1.0);
                final barHeight = 120 * ratio + (ratio > 0 ? 8 : 0);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (point.montantCotise > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              _shortAmount(point.montantCotise),
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: AppColors.prosocGreen.withValues(
                              alpha: point.montantCotise > 0 ? 1 : 0.25,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          point.labelCourt,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  static String _shortAmount(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }
}
