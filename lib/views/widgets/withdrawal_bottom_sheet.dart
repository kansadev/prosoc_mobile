import 'package:flutter/material.dart';

import '../../models/wallet_agent_model.dart';
import '../screens/at/withdrawal_screen.dart';

/// Ouvre l'écran dédié de demande de retrait (remplace l'ancien bottom sheet).
class WithdrawalBottomSheet extends StatelessWidget {
  final int? initialDeviseId;
  final Map<int, WalletAgentModel>? initialWalletsByDevise;

  const WithdrawalBottomSheet({
    super.key,
    this.initialDeviseId,
    this.initialWalletsByDevise,
  });

  static Future<bool?> show(
    BuildContext context, {
    int? initialDeviseId,
    Map<int, WalletAgentModel>? initialWalletsByDevise,
  }) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => WithdrawalScreen(
          initialDeviseId: initialDeviseId,
          initialWalletsByDevise: initialWalletsByDevise,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WithdrawalScreen(
      initialDeviseId: initialDeviseId,
      initialWalletsByDevise: initialWalletsByDevise,
    );
  }
}
