import 'package:flutter/material.dart';

import '../config/api.dart';
import '../views/widgets/flex_pay_payment_error_dialog.dart';
import '../views/widgets/payment_channel_inactive_dialog.dart';

/// Routage des erreurs d'initiation paiement électronique.
abstract final class ElectronicPaymentErrorHandler {
  /// Affiche le dialogue adapté.
  ///
  /// Retourne `true` si l'utilisateur doit revenir au sélecteur de mode
  /// (`PAYMENT_CHANNEL_INACTIVE` + « Changer de mode »).
  static Future<bool> show<T>(
    BuildContext context,
    ApiResponse<T> response, {
    VoidCallback? onChooseOtherMode,
  }) async {
    if (response.success) return false;

    if (response.isPaymentChannelInactive &&
        response.paymentConflict != null) {
      final changeMode = await PaymentChannelInactiveDialog.show(
        context,
        conflict: response.paymentConflict!,
      );
      if (changeMode) {
        onChooseOtherMode?.call();
      }
      return changeMode;
    }

    await FlexPayPaymentErrorDialog.show(
      context,
      message: response.message,
      statusCode: response.statusCode,
    );
    return false;
  }
}
