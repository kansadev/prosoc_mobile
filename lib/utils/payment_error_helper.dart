/// Classification des erreurs API paiement électronique (FlexPay).
enum PaymentErrorKind {
  /// 409 / message serveur : un paiement est déjà en attente.
  paymentAlreadyInProgress,

  /// Numéro de téléphone invalide.
  invalidPhone,

  /// Autre erreur.
  generic,
}

class PaymentErrorInfo {
  const PaymentErrorInfo({
    required this.kind,
    required this.userMessage,
    this.statusCode,
  });

  final PaymentErrorKind kind;
  final String userMessage;
  final int? statusCode;

  bool get isPaymentAlreadyInProgress =>
      kind == PaymentErrorKind.paymentAlreadyInProgress;
}

class PaymentErrorHelper {
  PaymentErrorHelper._();

  static PaymentErrorInfo resolve({
    String? message,
    int? statusCode,
  }) {
    final raw = message?.trim() ?? '';
    final lower = raw.toLowerCase();

    if (statusCode == 409 ||
        lower.contains('paiement électronique est déjà en cours') ||
        lower.contains('paiement electronique est deja en cours') ||
        lower.contains('déjà en cours') ||
        lower.contains('deja en cours')) {
      return PaymentErrorInfo(
        kind: PaymentErrorKind.paymentAlreadyInProgress,
        userMessage: raw.isNotEmpty
            ? raw
            : 'Un paiement électronique est déjà en cours pour cette période '
                'ou cet affilié. Veuillez attendre la confirmation ou '
                'l\'expiration du délai.',
        statusCode: statusCode,
      );
    }

    if (lower.contains('taille') && lower.contains('téléphone') ||
        lower.contains('telephone') && lower.contains('invalide')) {
      return PaymentErrorInfo(
        kind: PaymentErrorKind.invalidPhone,
        userMessage: raw.isNotEmpty
            ? raw
            : 'Le numéro de téléphone n\'est pas valide.',
        statusCode: statusCode,
      );
    }

    return PaymentErrorInfo(
      kind: PaymentErrorKind.generic,
      userMessage: raw.isNotEmpty
          ? raw
          : 'Le paiement n\'a pas pu être initié. Veuillez réessayer.',
      statusCode: statusCode,
    );
  }
}
