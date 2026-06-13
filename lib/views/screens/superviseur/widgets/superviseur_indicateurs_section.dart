import 'package:flutter/material.dart';

import '../../../../config/colors.dart';
import '../../../../models/dashboard_superviseur_model.dart';

class SuperviseurIndicateursSection extends StatelessWidget {
  final SuperviseurIndicateursPerformance indicateurs;

  const SuperviseurIndicateursSection({
    super.key,
    required this.indicateurs,
  });

  Color _levelColor(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('élev') ||
        lower.contains('eleve') ||
        lower.contains('faible') ||
        lower.contains('amélior') ||
        lower.contains('amelior')) {
      if (lower.contains('risque') && lower.contains('élev')) {
        return Colors.red.shade700;
      }
      if (lower.contains('faible')) return Colors.orange.shade700;
      return Colors.orange.shade700;
    }
    if (lower.contains('bon') ||
        lower.contains('stable') ||
        lower.contains('élevée') ||
        lower.contains('elevee')) {
      return AppColors.prosocGreen;
    }
    return Colors.blueGrey;
  }

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
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: AppColors.prosocGreen),
              const SizedBox(width: 8),
              const Text(
                'Indicateurs de performance',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('Performance', indicateurs.performanceGlobale),
              _chip('Tendance', indicateurs.tendancePerformance),
              _chip('Efficacité', indicateurs.efficaciteEquipe),
              _chip('Activité', indicateurs.niveauActivite),
              _chip('Risque', indicateurs.niveauRisque, isRisk: true),
            ],
          ),
          if (indicateurs.recommandations.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Recommandations',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            ...indicateurs.recommandations.map(
              (rec) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: 16, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rec,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, String value, {bool isRisk = false}) {
    final color = isRisk ? _levelColor(value) : _levelColor(value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
