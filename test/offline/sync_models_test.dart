import 'package:flutter_test/flutter_test.dart';
import 'package:prosoc/offline/sync_models.dart';

void main() {
  test('référentiels relus depuis Hive (Map<dynamic, dynamic> imbriquées)', () {
    // Forme renvoyée par Hive après redémarrage : aucune Map<String, dynamic>.
    final Map<dynamic, dynamic> stocke = <dynamic, dynamic>{
      'typeAdhesions': [
        <dynamic, dynamic>{
          'id': 1,
          'libelle': 'Solo',
          'categorie': <dynamic, dynamic>{'id': 2, 'nom': 'Standard'},
        },
      ],
      'devises': [
        <dynamic, dynamic>{'idDevise': 1, 'code': 'CDF'},
      ],
      'frais': <dynamic>[],
      'prestations': <dynamic>[],
      'provinces': <dynamic>[],
      'tarifsCotisation': <dynamic>[],
      'snapshot': 'abc',
    };

    final refs = SyncReferentials.fromMap(deepStringMap(stocke))!;
    expect(refs.typeAdhesions.single['libelle'], 'Solo');
    expect(refs.typeAdhesions.single['categorie'], isA<Map<String, dynamic>>());
    expect(refs.devises.single['code'], 'CDF');
  });

  test('payload de file imbriqué converti en profondeur', () {
    final entry = SyncQueueEntry.fromMap({
      'clientRequestId': 'a1',
      'type': 'ADHESION_WITH_AFFILIE',
      'payload': <dynamic, dynamic>{
        'adhesion': <dynamic, dynamic>{
          'nom': 'Test',
          'collectes': [
            <dynamic, dynamic>{'montant': 10},
          ],
        },
      },
    });
    expect(entry, isNotNull);
    final adhesion = entry!.payload['adhesion'];
    expect(adhesion, isA<Map<String, dynamic>>());
    expect((adhesion as Map<String, dynamic>)['collectes'], isA<List>());
  });

  test('delta de référentiels fusionné par id (jamais remplacé)', () {
    SyncReferentials refs({
      List<Map<String, dynamic>> frais = const [],
      List<Map<String, dynamic>> types = const [],
    }) => SyncReferentials(
      typeAdhesions: types,
      devises: const [],
      provinces: const [],
      frais: frais,
      prestations: const [],
      tarifsCotisation: const [],
      snapshot: '',
    );

    final local = refs(
      frais: [
        {'idFrais': 1, 'code': 'FRAIS_ADHESION', 'montant': 5},
        {'idFrais': 2, 'code': 'CARTE_MEMBRE', 'montant': 2},
      ],
      types: [
        {'id': 1, 'libelle': 'Solo'},
      ],
    );
    // Delta : seul le frais 2 a changé ; types et frais 1 absents.
    final delta = refs(
      frais: [
        {'idFrais': 2, 'code': 'CARTE_MEMBRE', 'montant': 3},
      ],
    );

    final merged = local.mergedWith(delta);
    expect(merged.frais, hasLength(2));
    expect(
      merged.frais.firstWhere((f) => f['idFrais'] == 2)['montant'],
      3,
    );
    expect(merged.frais.any((f) => f['code'] == 'FRAIS_ADHESION'), isTrue);
    expect(merged.typeAdhesions, hasLength(1));
  });
}
