import 'package:flutter/material.dart';

import '../../config/colors.dart';
import '../../models/adhesion_with_affilie_model.dart';
import '../../utils/formatters.dart';

/// Bottom sheet récapitulatif avant ouverture du paiement carte (WebView).
class FlexPayCardPaymentBottomSheet extends StatelessWidget {
  const FlexPayCardPaymentBottomSheet({
    super.key,
    required this.payment,
    required this.onPay,
    required this.onCancel,
  });

  final AdhesionElectronicPaymentResponse payment;
  final VoidCallback onPay;
  final VoidCallback onCancel;

  static Future<void> show(
    BuildContext context, {
    required AdhesionElectronicPaymentResponse payment,
    required VoidCallback onPay,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(sheetContext).bottom + 16,
        ),
        child: FlexPayCardPaymentBottomSheet(
          payment: payment,
          onPay: () {
            Navigator.of(sheetContext).pop();
            onPay();
          },
          onCancel: () => Navigator.of(sheetContext).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final message = payment.message?.trim();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            const SizedBox(height: 20),
            const Icon(
              Icons.credit_card,
              color: AppColors.prosocGreen,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message?.isNotEmpty == true
                  ? message!
                  : 'Paiement par carte',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous allez être redirigé vers la page sécurisée de paiement.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            if (payment.montantFlexPay > 0)
              _row(
                'Montant',
                '${payment.montantFlexPay.toStringAsFixed(2)} '
                    '${payment.codeDevisePaiement ?? payment.codeDeviseTarif ?? ''}',
              ),
            if (payment.referenceFlexPay?.isNotEmpty == true)
              _row('Référence', payment.referenceFlexPay!),
            if (payment.holdExpireAt != null)
              _row(
                'Expire le',
                AppFormatters.formatDateTime(payment.holdExpireAt),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onPay,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.prosocGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Payer'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.prosocGreen,
                side: const BorderSide(color: AppColors.prosocGreen),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
