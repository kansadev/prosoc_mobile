import 'package:flutter_test/flutter_test.dart';
import 'package:prosoc/models/arriere_affilie_model.dart';
import 'package:prosoc/models/cotisation_periode_model.dart';
import 'package:prosoc/utils/collecte_montant_helper.dart';

void main() {
  test('parsing de la réponse du guide', () {
    final periode = ResumePeriodeCotisation.fromJson({
      'affilieId': 34,
      'cotisationAffilieId': 2,
      'mois': 11,
      'annee': 2026,
      'periodicite': 'Mensuel',
      'montantAttendu': 200,
      'montantPaye': 50,
      'restAPayer': 150,
      'montantReserve': 20,
      'resteDisponible': 130,
      'deviseId': 1,
      'deviseCode': 'CDF',
      'statutPaiement': 'PARTIEL',
      'estCompletementPaye': false,
    });
    expect(periode.cotisationAffilieId, 2);
    expect(periode.restAPayer, 150);
    expect(periode.montantReserve, 20);
    expect(periode.resteDisponible, 130);
    expect(periode.deviseCode, 'CDF');
    expect(periode.messageBlocage, isNull);
  });

  ResumePeriodeCotisation periode({
    double reste = 100,
    double disponible = 100,
    bool solde = false,
  }) => ResumePeriodeCotisation(
    affilieId: 1,
    cotisationAffilieId: 2,
    mois: 11,
    annee: 2026,
    montantAttendu: 200,
    montantPaye: 200 - reste,
    restAPayer: reste,
    resteDisponible: disponible,
    deviseId: 1,
    estCompletementPaye: solde,
  );

  test('période soldée ou entièrement réservée : versement bloqué', () {
    expect(periode(solde: true).messageBlocage, contains('déjà entièrement'));
    expect(periode(reste: 0, disponible: 0).estSoldee, isTrue);
    expect(periode(disponible: 0).messageBlocage, contains('réservé'));
    expect(periode().messageBlocage, isNull);
  });

  test('agent : arriéré du même tarif et de la même période seulement', () {
    final arrieres = [
      ArriereAffilieModel.fromJson({
        'idArrieresAffilie': 1,
        'affilieId': 34,
        'typeObligation': 'Cotisation',
        'cotisationAffilieId': 2,
        'mois': 10,
        'annee': 2026,
        'montantAttendu': 200,
        'montantPaye': 0,
        'restAPayer': 200,
        'deviseId': 1,
      }),
      ArriereAffilieModel.fromJson({
        'idArrieresAffilie': 2,
        'affilieId': 34,
        'typeObligation': 'Cotisation',
        'cotisationAffilieId': 2,
        'mois': 11,
        'annee': 2026,
        'montantAttendu': 200,
        'montantPaye': 50,
        'restAPayer': 150,
        'deviseId': 1,
      }),
    ];

    final trouvee = ResumePeriodeCotisation.depuisArrieres(
      arrieres,
      cotisationAffilieId: 2,
      mois: 11,
      annee: 2026,
    )!;
    expect(trouvee.montantPaye, 50);
    expect(trouvee.resteDisponible, 150);

    expect(
      ResumePeriodeCotisation.depuisArrieres(
        arrieres,
        cotisationAffilieId: 9,
        mois: 11,
        annee: 2026,
      ),
      isNull,
    );
    expect(
      ResumePeriodeCotisation.depuisArrieres(
        arrieres,
        cotisationAffilieId: 2,
        mois: 12,
        annee: 2026,
      ),
      isNull,
    );
  });

  test('libellé : mention du partiel réservée à la cotisation', () {
    expect(
      CollecteMontantHelper.montantAttenduLibelle(montantAttendu: 130),
      'Montant attendu : 130.00',
    );
    expect(
      CollecteMontantHelper.montantAttenduLibelle(
        montantAttendu: 130,
        partielAutorise: true,
      ),
      contains('partiel'),
    );
  });
}
