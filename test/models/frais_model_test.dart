import 'package:flutter_test/flutter_test.dart';
import 'package:prosoc/models/frais_model.dart';

void main() {
  test('frais API camelCase : frais d\'adhésion reconnu par son code', () {
    final frais = Frais.fromJson({
      'idFrais': 3,
      'code': 'FRAIS_ADHESION',
      'libelle': 'Frais d\'adhésion',
      'montant': 5,
      'deviseId': 2,
      'statut': true,
    });
    expect(frais.idFrais, 3);
    expect(frais.montant, 5.0);
    expect(frais.isFraisAdhesion, isTrue);
  });

  test('référentiel sync PascalCase, valeurs texte, sans code', () {
    final frais = Frais.fromJson({
      'IdFrais': '7',
      'Libelle': 'Frais d\'adhésion',
      'Montant': '10.5',
      'DeviseId': 1,
    });
    expect(frais.idFrais, 7);
    expect(frais.montant, 10.5);
    expect(frais.deviseId, 1);
    expect(frais.statut, isTrue);
    expect(frais.isFraisAdhesion, isTrue);
  });

  test('carte membre exclue du frais d\'adhésion', () {
    final frais = Frais.fromJson({'idFrais': 4, 'code': 'CARTE_MEMBRE'});
    expect(frais.isFraisAdhesion, isFalse);
  });
}
