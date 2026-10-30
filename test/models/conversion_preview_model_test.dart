import 'package:flutter_test/flutter_test.dart';
import 'package:prosoc/models/conversion_preview_model.dart';

void main() {
  test('récapitulatif du guide : 10 USD payés en CDF à 2 800', () {
    final preview = ConversionPreview.fromJson({
      'codeDeviseSource': 'USD',
      'codeDeviseCible': 'CDF',
      'taux': 2800,
      'montantSource': 10,
      'montantConverti': 28000,
    });
    expect(preview.montantConverti, 28000);
    expect(
      preview.recapLabel,
      r'Tarif : $10.00 · Taux : 1 USD = 2,800 CDF · À payer : 28,000 CDF',
    );
  });

  test('le taux est exprimé depuis la devise la plus forte', () {
    final preview = ConversionPreview.fromJson({
      'codeDeviseSource': 'CDF',
      'codeDeviseCible': 'USD',
      'taux': 0.000357,
      'montantSource': 28000,
      'montantConverti': 10,
    });
    expect(preview.tauxLabel, '1 USD = 2,800 CDF');
  });
}
