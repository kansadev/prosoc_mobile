import 'package:flutter/material.dart';

import '../../utils/payment_error_helper.dart';
import 'prosoc_message_dialog.dart';

/// Dialogue paiement FlexPay (erreurs API, dont paiement déjà en cours).
class FlexPayPaymentErrorDialog extends StatelessWidget {
  const FlexPayPaymentErrorDialog({
    super.key,
    required this.error,
    this.onAcknowledged,
  });

  final PaymentErrorInfo error;
  final VoidCallback? onAcknowledged;

  static Future<void> show(
    BuildContext context, {
    String? message,
    int? statusCode,
    VoidCallback? onAcknowledged,
  }) {
    final info = PaymentErrorHelper.resolve(
      message: message,
      statusCode: statusCode,
    );
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => FlexPayPaymentErrorDialog(
        error: info,
        onAcknowledged: onAcknowledged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPending = error.isPaymentAlreadyInProgress;
    final isPhone = error.kind == PaymentErrorKind.invalidPhone;

    final ProsocMessageVariant variant = isPending
        ? ProsocMessageVariant.warning
        : ProsocMessageVariant.error;

    final Color accent = isPending
        ? Colors.orange.shade700
        : isPhone
        ? Colors.amber.shade800
        : Colors.red.shade600;

    final IconData icon = isPending
        ? Icons.hourglass_top_rounded
        : isPhone
        ? Icons.phone_missed_outlined
        : Icons.error_outline_rounded;

    final String title = isPending
        ? 'Paiement déjà en cours'
        : isPhone
        ? 'Numéro invalide'
        : error.statusCode != null && error.statusCode! >= 500
        ? 'Erreur serveur'
        : 'Paiement impossible';

    final String? hint = isPending
        ? 'Aucun nouveau paiement ne peut être lancé tant que le précédent '
              'n\'est pas confirmé ou expiré. Si l\'affilié vient de valider sur '
              'son téléphone, patientez quelques instants avant de réessayer.'
        : isPhone
        ? 'Utilisez le format 243XXXXXXXXX (12 chiffres, indicatif RDC).'
        : error.statusCode != null && error.statusCode! >= 500
        ? 'Le serveur n\'a pas pu traiter la demande. Vérifiez le solde du '
              'compte virtuel, la devise du tarif, puis réessayez. '
              'Contactez le support si le problème persiste.'
        : null;

    return ProsocMessageDialog(
      variant: variant,
      title: title,
      message: error.userMessage,
      hint: hint,
      statusCode: error.statusCode,
      confirmLabel: isPending ? 'Compris' : 'OK',
      onConfirm: onAcknowledged,
      icon: icon,
      accentColor: accent,
    );
  }
}
