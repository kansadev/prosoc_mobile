import 'package:flutter/material.dart';
import '../screens/at/withdrawal_screen.dart';

/// Ouvre l'écran dédié de demande de retrait (remplace l'ancien bottom sheet).
class WithdrawalBottomSheet extends StatelessWidget {
  final double? soldeDisponible;

  const WithdrawalBottomSheet({super.key, this.soldeDisponible});

  static Future<bool?> show(
    BuildContext context, {
    double? soldeDisponible,
  }) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => WithdrawalScreen(
          soldeDisponible: soldeDisponible,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WithdrawalScreen(soldeDisponible: soldeDisponible);
  }
}
