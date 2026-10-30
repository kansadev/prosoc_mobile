import 'package:intl/intl.dart';

import '../utils/currency_formatter.dart';

double _previewDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

/// Réponse de `GET /api/Devise/preview-conversion`.
///
/// Source = devise du tarif, cible = devise de paiement. Le montant à
/// soumettre en collecte est [montantConverti], tel que calculé par le serveur.
class ConversionPreview {
  final String codeDeviseSource;
  final String codeDeviseCible;
  final double taux;
  final double montantSource;
  final double montantConverti;

  const ConversionPreview({
    required this.codeDeviseSource,
    required this.codeDeviseCible,
    required this.taux,
    required this.montantSource,
    required this.montantConverti,
  });

  factory ConversionPreview.fromJson(Map<String, dynamic> json) {
    return ConversionPreview(
      codeDeviseSource: (json['codeDeviseSource'] ?? '').toString(),
      codeDeviseCible: (json['codeDeviseCible'] ?? '').toString(),
      taux: _previewDouble(json['taux']),
      montantSource: _previewDouble(json['montantSource']),
      montantConverti: _previewDouble(json['montantConverti']),
    );
  }

  static final NumberFormat _tauxFormatter = NumberFormat('#,##0.##', 'en_US');

  /// « 1 USD = 2 800 CDF », exprimé depuis la devise la plus forte et dérivé
  /// des montants serveur (indépendant du sens de stockage du taux).
  String get tauxLabel {
    if (montantSource <= 0 || montantConverti <= 0) {
      return '1 $codeDeviseSource = ${_tauxFormatter.format(taux)} $codeDeviseCible';
    }
    final ratio = montantConverti / montantSource;
    return ratio >= 1
        ? '1 $codeDeviseSource = ${_tauxFormatter.format(ratio)} $codeDeviseCible'
        : '1 $codeDeviseCible = ${_tauxFormatter.format(1 / ratio)} $codeDeviseSource';
  }

  String get montantSourceLabel =>
      CurrencyFormatter.format(amount: montantSource, deviseCode: codeDeviseSource);

  String get montantConvertiLabel => CurrencyFormatter.format(
    amount: montantConverti,
    deviseCode: codeDeviseCible,
  );

  /// « Tarif : 10 USD · Taux : 1 USD = 2 800 CDF · À payer : 28 000 CDF ».
  String get recapLabel =>
      'Tarif : $montantSourceLabel · Taux : $tauxLabel · '
      'À payer : $montantConvertiLabel';
}
