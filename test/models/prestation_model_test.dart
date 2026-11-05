import 'package:flutter_test/flutter_test.dart';
import 'package:prosoc/models/prestation_model.dart';

void main() {
  test('nom lu quelle que soit la source', () {
    for (final cle in const [
      'nomPrestation',
      'NomPrestation',
      'nom',
      'libellePrestation',
      'libelle',
      'Libelle',
      'designation',
    ]) {
      final prestation = Prestation.fromJson({
        'id': 258,
        cle: 'Consultation',
        'montant': 200,
      });
      expect(prestation.nomPrestation, 'Consultation', reason: cle);
    }
  });

  test('nom vide ignoré au profit du champ suivant', () {
    final prestation = Prestation.fromJson({
      'idPrestation': 258,
      'nomPrestation': '  ',
      'libelle': 'Consultation',
    });
    expect(prestation.nomPrestation, 'Consultation');
  });

  test('sans aucun nom : ligne identifiable par son numéro', () {
    final prestation = Prestation.fromJson({'id': 258, 'montant': 200});
    expect(prestation.nomPrestation, 'Prestation n°258');
  });
}
