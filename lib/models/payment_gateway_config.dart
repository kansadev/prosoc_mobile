/// Configuration passerelle de paiement (login + réponses d'initiation / 409).
class PaymentGatewayConfig {
  final String? provider;
  final String? cardProvider;
  final double commissionPercentage;

  const PaymentGatewayConfig({
    this.provider,
    this.cardProvider,
    this.commissionPercentage = 0,
  });

  factory PaymentGatewayConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PaymentGatewayConfig();
    }
    return PaymentGatewayConfig(
      provider: json['provider']?.toString(),
      cardProvider: json['cardProvider']?.toString(),
      commissionPercentage:
          (json['commissionPercentage'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'provider': provider,
        'cardProvider': cardProvider,
        'commissionPercentage': commissionPercentage,
      };

  bool get hasProvider =>
      (provider != null && provider!.trim().isNotEmpty) ||
      (cardProvider != null && cardProvider!.trim().isNotEmpty);

  String get displayProvider {
    final p = provider?.trim();
    if (p != null && p.isNotEmpty) return p;
    final c = cardProvider?.trim();
    if (c != null && c.isNotEmpty) return c;
    return 'Passerelle alternative';
  }

  String get commissionLabel {
    final value = commissionPercentage;
    if (value <= 0) return '0 %';
    final isWhole = value == value.roundToDouble();
    final formatted = isWhole
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1).replaceAll('.', ',');
    return '~$formatted %';
  }
}

/// Corps HTTP 409 — canal de paiement inactif / bascule proposée.
class PaymentChannelConflict {
  static const codeInactive = 'PAYMENT_CHANNEL_INACTIVE';

  final String message;
  final String? code;
  final String? modePaiement;
  final PaymentGatewayConfig? paymentGateway;

  const PaymentChannelConflict({
    required this.message,
    this.code,
    this.modePaiement,
    this.paymentGateway,
  });

  bool get isChannelInactive =>
      code == codeInactive ||
      (message.toLowerCase().contains('canal') &&
          message.toLowerCase().contains('pas actif'));

  factory PaymentChannelConflict.fromJson(Map<String, dynamic> json) {
    PaymentGatewayConfig? gateway;
    final rawGateway = json['paymentGateway'];
    if (rawGateway is Map<String, dynamic>) {
      gateway = PaymentGatewayConfig.fromJson(rawGateway);
    } else if (rawGateway is Map) {
      gateway = PaymentGatewayConfig.fromJson(
        Map<String, dynamic>.from(rawGateway),
      );
    }

    return PaymentChannelConflict(
      message: (json['message'] ?? json['Message'] ?? '').toString(),
      code: (json['code'] ?? json['Code'])?.toString(),
      modePaiement: (json['modePaiement'] ?? json['ModePaiement'])?.toString(),
      paymentGateway: gateway,
    );
  }
}
