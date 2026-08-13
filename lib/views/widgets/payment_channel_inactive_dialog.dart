import 'package:flutter/material.dart';

import '../../models/payment_gateway_config.dart';
import 'prosoc_message_dialog.dart';

/// Dialogue 409 `PAYMENT_CHANNEL_INACTIVE` : proposer un autre mode.
///
/// Retourne `true` si l'utilisateur choisit de changer de mode.
class PaymentChannelInactiveDialog {
  PaymentChannelInactiveDialog._();

  static Future<bool> show(
    BuildContext context, {
    required PaymentChannelConflict conflict,
  }) async {
    final gateway = conflict.paymentGateway;
    final buffer = StringBuffer(
      conflict.message.trim().isNotEmpty
          ? conflict.message.trim()
          : 'Ce mode de paiement n\'est pas disponible pour ce marchand.',
    );

    if (gateway != null && gateway.hasProvider) {
      buffer.writeln();
      buffer.writeln();
      buffer.write('Passerelle proposée : ${gateway.displayProvider}');
    }

    final commission = gateway?.commissionPercentage ?? 0;
    final hint = commission > 0
        ? 'Attention : des frais supplémentaires estimés à '
            '${gateway!.commissionLabel} peuvent s\'appliquer '
            'selon le mode choisi.'
        : 'Choisissez un autre mode de paiement pour continuer.';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ProsocMessageDialog(
        variant: ProsocMessageVariant.warning,
        title: 'Mode de paiement indisponible',
        message: buffer.toString(),
        hint: hint,
        statusCode: 409,
        icon: Icons.swap_horiz_rounded,
        accentColor: Colors.orange.shade800,
        confirmLabel: 'Changer de mode',
        secondaryLabel: 'Annuler',
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        onSecondary: () => Navigator.of(dialogContext).pop(false),
      ),
    );

    return result == true;
  }
}
