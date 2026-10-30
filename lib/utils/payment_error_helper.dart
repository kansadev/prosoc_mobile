import 'api_error_helper.dart';

/// Classification des erreurs API paiement électronique (FlexPay).
enum PaymentErrorKind {
  /// 409 / message serveur : un paiement est déjà en attente.
  paymentAlreadyInProgress,

  /// 409 `PAYMENT_CHANNEL_INACTIVE` : canal marchand inactif.
  paymentChannelInactive,

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
    this.errorCode,
  });

  final PaymentErrorKind kind;
  final String userMessage;
  final int? statusCode;
  final String? errorCode;

  bool get isPaymentAlreadyInProgress =>
      kind == PaymentErrorKind.paymentAlreadyInProgress;

  bool get isPaymentChannelInactive =>
      kind == PaymentErrorKind.paymentChannelInactive;
}

class PaymentErrorHelper {
  PaymentErrorHelper._();

  static PaymentErrorInfo resolve({
    String? message,
    int? statusCode,
    String? errorCode,
  }) {
    // Contenu technique (HTML, exception) : on retombe sur les messages par défaut.
    final raw = ApiErrorHelper.isTechnicalContent(message)
        ? ''
        : message?.trim() ?? '';
    final lower = raw.toLowerCase();
    final code = errorCode?.trim().toUpperCase();

    if (code == 'PAYMENT_CHANNEL_INACTIVE' ||
        (lower.contains('canal') && lower.contains('pas actif'))) {
      return PaymentErrorInfo(
        kind: PaymentErrorKind.paymentChannelInactive,
        userMessage: raw.isNotEmpty
            ? raw
            : 'Ce mode de paiement n\'est pas actif pour ce marchand. '
                'Choisissez un autre mode de paiement.',
        statusCode: statusCode,
        errorCode: code,
      );
    }

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
        errorCode: code,
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
        errorCode: code,
      );
    }

    return PaymentErrorInfo(
      kind: PaymentErrorKind.generic,
      userMessage: raw.isNotEmpty
          ? raw
          : 'Le paiement n\'a pas pu être initié. Veuillez réessayer.',
      statusCode: statusCode,
      errorCode: code,
    );
  }
}
