import 'package:flutter/material.dart';

import '../models/collecte_receipt_data.dart';
import '../views/widgets/collecte_receipt_screen.dart';

/// Ouverture standardisée du reçu après une opération de collecte.
abstract final class CollecteReceiptHelper {
  static Future<T?> open<T>(
    BuildContext context, {
    required CollecteReceiptData receipt,
    T? popResult,
  }) {
    return CollecteReceiptScreen.show<T>(
      context,
      receipt: receipt,
      popResult: popResult,
    );
  }

  static int? parseId(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw > 0 ? raw : null;
    if (raw is num) {
      final v = raw.toInt();
      return v > 0 ? v : null;
    }
    return int.tryParse(raw.toString());
  }
}
