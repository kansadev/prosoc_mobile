import 'package:flutter_test/flutter_test.dart';
import 'package:prosoc/models/medical/catalogue_medical_model.dart';
import 'package:prosoc/models/medical/paiement_medical_model.dart';
import 'package:prosoc/models/medical/prise_en_charge_medicale_model.dart';
import 'package:prosoc/models/medical/souscription_medicale_model.dart';
import 'package:prosoc/utils/guid.dart';

Map<String, dynamic> _periode({
  num montantValide = 0,
  num soldeRestant = 20,
  bool droitsOuverts = false,
  String? debut,
  String? fin = '2026-10-31T23:00:00Z',
}) => {
  'id': 62,
  'souscriptionMedicaleId': 40,
  'versionOffreMedicaleId': 25,
  'annee': 2026,
  'mois': 10,
  'montantDu': 20,
  'montantValide': montantValide,
  'soldeRestant': soldeRestant,
  'deviseId': 1,
  'dateDebutDroitsUtc': debut,
  'dateFinExclusiveUtc': fin,
  'droitsOuverts': droitsOuverts,
};

void main() {
  group('Catalogue', () {
    test('parse l\'offre du guide (entiers, champs nullable)', () {
      final offre = OffreMedicale.fromJson({
        'id': 12,
        'nom': 'Soins ambulatoires',
        'hopitalPartenaireId': 4,
        'hopitalNom': 'Hôpital exemple',
        'categorieHopitalId': null,
        'categorieHopitalNom': null,
        'categorieSoinId': 3,
        'categorieSoinNom': 'Ambulatoire',
        'statut': true,
        'periodicite': 'Mensuel',
        'version': {
          'id': 25,
          'montantMensuel': 20,
          'deviseId': 1,
          'deviseCode': 'USD',
          'datePublicationUtc': '2026-10-28T10:00:00Z',
          'soins': [
            {'soinId': 7, 'nom': 'Consultation générale', 'description': null},
          ],
          'tauxCommissionAT': 20,
          'tauxCommissionAA': 10,
          'tauxCommissionAAMash': 5,
          'tauxCommissionAAStructure': 3,
        },
      });
      expect(offre.categorieHopitalId, isNull);
      expect(offre.version!.montantMensuel, 20.0);
      expect(offre.version!.soins.single.soinId, 7);
      expect(offre.version!.soins.single.description, isNull);
      expect(offre.version!.datePublicationUtc!.isUtc, isTrue);
    });

    test('les chemins de référentiels sont exactement ceux de l\'API', () {
      expect(
        ReferentielMedicalType.values.map((t) => t.path),
        ['categories-hopitaux', 'categories-soins', 'soins'],
      );
    });
  });

  group('Période — état dérivé', () {
    final avantFin = DateTime.utc(2026, 10, 15);

    test('à payer tant que rien n\'est validé', () {
      final p = PeriodeCouvertureMedicale.fromJson(_periode());
      expect(p.etat(now: avantFin), EtatPeriodeMedicale.aPayer);
    });

    test('paiement partiel : pas de droits', () {
      final p = PeriodeCouvertureMedicale.fromJson(
        _periode(montantValide: 8, soldeRestant: 12),
      );
      expect(p.etat(now: avantFin), EtatPeriodeMedicale.paiementPartiel);
    });

    test('mois futur soldé : payé — à venir', () {
      final p = PeriodeCouvertureMedicale.fromJson(
        _periode(
          montantValide: 20,
          soldeRestant: 0,
          debut: '2026-11-01T00:00:00Z',
          fin: '2026-11-30T23:00:00Z',
        ),
      );
      expect(p.etat(now: avantFin), EtatPeriodeMedicale.payeAVenir);
    });

    test('couvert seulement si le serveur ouvre les droits', () {
      final p = PeriodeCouvertureMedicale.fromJson(
        _periode(montantValide: 20, soldeRestant: 0, droitsOuverts: true),
      );
      expect(p.etat(now: avantFin), EtatPeriodeMedicale.couvert);
    });

    test('la fin est exclusive', () {
      final p = PeriodeCouvertureMedicale.fromJson(_periode());
      expect(
        p.etat(now: DateTime.utc(2026, 10, 31, 23)),
        EtatPeriodeMedicale.expire,
      );
      expect(
        p.etat(now: DateTime.utc(2026, 10, 31, 22, 59)),
        EtatPeriodeMedicale.aPayer,
      );
    });

    test('soldée sans droits ni cause lisible : droits indisponibles', () {
      final p = PeriodeCouvertureMedicale.fromJson(
        _periode(montantValide: 20, soldeRestant: 0),
      );
      expect(p.etat(now: avantFin), EtatPeriodeMedicale.droitsIndisponibles);
    });
  });

  group('Paiement', () {
    test('corps guichet stable pour une reprise à l\'identique', () {
      const request = PaiementMedicalGuichetRequest(
        idPaiement: 'd1c13f65-b77a-4cc2-9233-fbe5f47bd843',
        periodeCouvertureMedicaleId: 62,
        montant: 8,
        deviseId: 1,
        modePaiement: PaiementMedicalModes.espece,
      );
      expect(request.toJson(), {
        'idPaiement': 'd1c13f65-b77a-4cc2-9233-fbe5f47bd843',
        'periodeCouvertureMedicaleId': 62,
        'montant': 8.0,
        'deviseId': 1,
        'modePaiement': 'ESPECE',
      });
    });

    test('parse la réponse 201 du guichet', () {
      final read = PaiementMedicalRead.fromJson({
        'idPaiement': 'd1c13f65-b77a-4cc2-9233-fbe5f47bd843',
        'collecteId': 150,
        'periodeCouvertureMedicaleId': 62,
        'montant': 8,
        'deviseId': 1,
        'montantCredite': 8,
        'deviseTarifId': 1,
      });
      expect(read.collecteId, 150);
      expect(read.montantCredite, 8.0);
    });

    test('Moko n\'est pas proposé', () {
      expect(
        PaiementMedicalModes.electronique.keys,
        isNot(contains('CARTE_BANCAIRE_MOKO')),
      );
    });
  });

  group('Prise en charge — badges dérivés', () {
    Map<String, dynamic> json({
      String statut = 'VALIDEE',
      bool estUtilise = false,
      String? expiration = '2026-10-31T23:00:00Z',
    }) => {
      'id': 90,
      'periodeCouvertureMedicaleId': 62,
      'affilieId': 31,
      'hopitalPartenaireId': 4,
      'soinId': 7,
      'statut': statut,
      'estUtilise': estUtilise,
      'dateExpirationUtc': expiration,
    };
    final now = DateTime.utc(2026, 10, 28);

    test('statuts serveur', () {
      expect(
        PriseEnChargeMedicale.fromJson(json(statut: 'EN_ATTENTE')).badge(now: now),
        BadgePriseEnCharge.enAttente,
      );
      expect(
        PriseEnChargeMedicale.fromJson(json(statut: 'REJETEE')).badge(now: now),
        BadgePriseEnCharge.rejetee,
      );
      expect(
        PriseEnChargeMedicale.fromJson(json()).badge(now: now),
        BadgePriseEnCharge.validee,
      );
    });

    test('consommée : reste VALIDEE côté serveur, badge « Utilisée »', () {
      final p = PriseEnChargeMedicale.fromJson(json(estUtilise: true));
      expect(p.statut, 'VALIDEE');
      expect(p.badge(now: now), BadgePriseEnCharge.utilisee);
    });

    test('expirée à la date d\'expiration', () {
      final p = PriseEnChargeMedicale.fromJson(json());
      expect(
        p.badge(now: DateTime.utc(2026, 10, 31, 23)),
        BadgePriseEnCharge.expiree,
      );
    });

    test('champs de création nullable', () {
      final p = PriseEnChargeMedicale.fromJson(json(statut: 'EN_ATTENTE'));
      expect(p.numeroBon, isNull);
      expect(p.qrCodePayload, isNull);
      expect(p.agentId, isNull);
    });
  });

  test('GUID v4 conforme et distinct', () {
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    final a = Guid.v4();
    final b = Guid.v4();
    expect(pattern.hasMatch(a), isTrue);
    expect(pattern.hasMatch(b), isTrue);
    expect(a, isNot(b));
  });
}
