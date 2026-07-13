import 'package:flutter/material.dart';

import '../../../../config/colors.dart';
import '../../../../models/bon_envoi_model.dart';
import '../../../../utils/formatters.dart';
import '../../../widgets/bon_envoi_qr_view.dart';

/// Détail d'un bon d'envoi (numéro, dates, QR).
class BonEnvoiDetailSheet extends StatelessWidget {
  final BonEnvoiModel bon;

  const BonEnvoiDetailSheet({super.key, required this.bon});

  static Future<void> show(BuildContext context, BonEnvoiModel bon) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BonEnvoiDetailSheet(bon: bon),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  bon.numeroBon.isNotEmpty
                      ? 'Bon ${bon.numeroBon}'
                      : 'Bon #${bon.idBonEnvoi}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (bon.prestationNom.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    bon.prestationNom,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
                const SizedBox(height: 16),
                _row(
                  'Statut',
                  bon.statutLabel,
                  color: bon.estUtilise
                      ? Colors.grey.shade700
                      : AppColors.prosocGreen,
                ),
                if (bon.dateEmission != null)
                  _row('Émission', AppFormatters.formatDate(bon.dateEmission)),
                if (bon.dateUtilisation != null)
                  _row(
                    'Utilisation',
                    AppFormatters.formatDate(bon.dateUtilisation),
                  ),
                if (bon.hasJetonLie) ...[
                  _row(
                    'Jeton médical',
                    bon.jetonMedicalCode.isNotEmpty
                        ? bon.jetonMedicalCode
                        : '#${bon.jetonMedicalId}',
                    color: AppColors.prosocGreen,
                  ),
                ],
                const SizedBox(height: 20),
                Center(
                  child: BonEnvoiQrView(
                    qrCodeImageBase64: bon.qrCodeImageBase64,
                    qrCodePayload: bon.qrCodePayload,
                    size: 220,
                    showLabel: true,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.prosocGreen,
                  ),
                  child: const Text('Fermer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
