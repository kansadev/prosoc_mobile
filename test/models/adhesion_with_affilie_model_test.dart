import 'package:flutter_test/flutter_test.dart';
import 'package:prosoc/models/adhesion_partner_model.dart';
import 'package:prosoc/models/adhesion_with_affilie_model.dart';

AdhesionWithAffilieRequest _request({
  int categorieAdhesionId = 3,
  int typeAdhesionId = 5,
  int? entreprisePartenaireId,
  int? structurePartenaireId,
}) {
  return AdhesionWithAffilieRequest(
    nom: 'Exemple',
    prenom: 'Aline',
    postnom: '',
    dateNaissance: DateTime(1990, 3, 15),
    telephone: '+243000000000',
    provinceResidence: 'Kinshasa',
    affilieStatut: true,
    categorieAdhesionId: categorieAdhesionId,
    typeAdhesionId: typeAdhesionId,
    entreprisePartenaireId: entreprisePartenaireId,
    structurePartenaireId: structurePartenaireId,
    adhesionStatut: true,
  );
}

void main() {
  test('payload STRUCTURE transmet sa catégorie et son seul partenaire', () {
    final payload = _request(structurePartenaireId: 12).toJson();

    expect(payload['categorieAdhesionId'], 3);
    expect(payload['typeAdhesionId'], 5);
    expect(payload['structurePartenaireId'], 12);
    expect(payload.containsKey('entreprisePartenaireId'), isFalse);
  });

  test('payload Particulier omet les deux rattachements partenaire', () {
    final payload = _request(categorieAdhesionId: 1).toJson();

    expect(payload['categorieAdhesionId'], 1);
    expect(payload.containsKey('entreprisePartenaireId'), isFalse);
    expect(payload.containsKey('structurePartenaireId'), isFalse);
  });

  test('référentiels actifs lisent leurs identifiants documentés', () {
    final category = AdhesionCategory.fromJson({
      'idCategorieAdhesion': 3,
      'code': 'STRUCTURE',
      'libelle': 'Structure',
      'statut': true,
    });
    final partner = AdhesionPartner.fromJson({
      'idStructurePartenaire': 12,
      'nom': 'Structure Exemple',
    });

    expect(category.id, 3);
    expect(category.code, 'STRUCTURE');
    expect(partner.id, 12);
    expect(partner.nom, 'Structure Exemple');
  });
}
