import 'package:flutter_test/flutter_test.dart';
import 'package:prosoc/offline/offline_database.dart';

void main() {
  test('adhésion : débits par devise des collectes de l\'agent', () {
    final debits = OfflineDatabase.debitsDePayload({
      'adhesion': <dynamic, dynamic>{
        'agentId': 3,
        'collectes': [
          <dynamic, dynamic>{'montant': 10, 'deviseId': 2},
          <dynamic, dynamic>{'montant': 5.5, 'deviseId': 2},
          <dynamic, dynamic>{'montant': 20000, 'deviseId': 1},
        ],
      },
    }, agentId: 3);
    expect(debits, {2: 15.5, 1: 20000.0});
  });

  test('adhésion d\'un autre agent : aucun débit', () {
    final debits = OfflineDatabase.debitsDePayload({
      'adhesion': {
        'agentId': 9,
        'collectes': [
          {'montant': 10, 'deviseId': 2},
        ],
      },
    }, agentId: 3);
    expect(debits, isEmpty);
  });

  test('collecte : montant et devise de la collecte', () {
    final debits = OfflineDatabase.debitsDePayload({
      'agentId': 3,
      'montant': 7,
      'deviseId': 1,
    }, agentId: 3);
    expect(debits, {1: 7.0});
  });
}
