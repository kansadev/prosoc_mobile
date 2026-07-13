import 'dart:async';

/// Abstraction SignalR FlexPay (`/flexPayHub`).
///
/// MVP : implémentation no-op. Pour activer le temps réel, ajouter
/// `signalr_netcore` et implémenter [FlexPaySignalRService.connect].
abstract class FlexPaySignalRService {
  static final FlexPaySignalRService instance = _NoOpFlexPaySignalRService();

  /// Connexion au hub et abonnement au paiement en cours.
  Future<void> connect({
    required String idCollecteEnAttente,
    required void Function(FlexPayPaymentUpdate update) onUpdated,
  });

  Future<void> disconnect();
}

class FlexPayPaymentUpdate {
  final bool success;
  final String? message;
  final int? idAdhesion;
  final String? referenceFlexPay;

  const FlexPayPaymentUpdate({
    required this.success,
    this.message,
    this.idAdhesion,
    this.referenceFlexPay,
  });
}

class _NoOpFlexPaySignalRService implements FlexPaySignalRService {
  @override
  Future<void> connect({
    required String idCollecteEnAttente,
    required void Function(FlexPayPaymentUpdate update) onUpdated,
  }) async {
    // Phase 2 : JoinFlexPayPayment + écoute FlexPayPaymentUpdated
  }

  @override
  Future<void> disconnect() async {}
}
