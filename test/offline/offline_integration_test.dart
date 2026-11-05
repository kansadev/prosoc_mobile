import 'package:flutter_test/flutter_test.dart';
import 'package:prosoc/offline/offline_database.dart';
import 'package:prosoc/offline/offline_mode.dart';
import 'package:prosoc/offline/sync_models.dart';
import 'package:prosoc/services/sync_service.dart';

SyncQueueEntry _entree(SyncWriteKind kind, Map<String, dynamic> payload) {
  return SyncQueueEntry(
    clientRequestId: 'id-1',
    kind: kind,
    payload: payload,
    deviceId: 'android-1',
    dateOperationUtc: '2026-11-05T10:00:00Z',
    localStatus: 'failed',
    attempts: 2,
    createdAt: '2026-11-05T10:00:00Z',
    lastError: 'erreur locale',
    label: 'libellé local',
  );
}

const _clesCommunes = {'clientRequestId', 'type', 'deviceId', 'dateOperationUtc'};

void main() {
  group('toWire : corps du batch', () {
    test('collecte : payload sous la clé collecte, sans champ local', () {
      final wire = _entree(SyncWriteKind.collecte, {'montant': 10}).toWire();
      expect(wire.keys.toSet(), {..._clesCommunes, 'collecte'});
      expect(wire['type'], 'COLLECTE');
      expect(wire['collecte'], {'montant': 10});
    });

    test('adhésion : seul le contenu de payload.adhesion part', () {
      final wire = _entree(SyncWriteKind.adhesion, {
        'adhesion': {'nom': 'Test'},
      }).toWire();
      expect(wire.keys.toSet(), {..._clesCommunes, 'adhesion'});
      expect(wire['type'], 'ADHESION_WITH_AFFILIE');
      expect(wire['adhesion'], {'nom': 'Test'});
    });

    test('achat : affilieId et achat, sans agentId local', () {
      final achat = {
        'prestationId': 258,
        'statut': true,
        'collecte': {'montant': 200, 'deviseId': 1},
      };
      final wire = _entree(SyncWriteKind.souscriptionPrestation, {
        'agentId': 3,
        'affilieId': 10,
        'achat': achat,
      }).toWire();
      expect(wire.keys.toSet(), {..._clesCommunes, 'souscriptionPrestation'});
      expect(wire['type'], 'SOUSCRIPTION_PRESTATION');
      expect(wire['souscriptionPrestation'], {'affilieId': 10, 'achat': achat});
    });
  });

  group('debitsDePayload : achat de souscription', () {
    final payload = {
      'agentId': 3,
      'affilieId': 10,
      'achat': <dynamic, dynamic>{
        'prestationId': 258,
        'collecte': <dynamic, dynamic>{'montant': 200, 'deviseId': 1},
      },
    };

    test('débite la collecte de l\'achat', () {
      expect(OfflineDatabase.debitsDePayload(payload, agentId: 3), {1: 200.0});
    });

    test('achat d\'un autre agent : aucun débit', () {
      expect(OfflineDatabase.debitsDePayload(payload, agentId: 4), isEmpty);
    });
  });

  test('SyncSouscriptionRow : parsing camelCase, PascalCase et aller-retour', () {
    final row = SyncSouscriptionRow.fromJson({
      'IdSouscriptionPrestation': 7,
      'affilieId': 10,
      'PrestationId': 258,
      'dateSouscription': '2026-11-01T00:00:00Z',
      'statut': false,
      'updatedAt': '2026-11-02T00:00:00Z',
    });
    expect(row.idSouscriptionPrestation, 7);
    expect(row.affilieId, 10);
    expect(row.prestationId, 258);
    expect(row.statut, isFalse);
    expect(SyncSouscriptionRow.fromJson(row.toMap()).prestationId, 258);
  });

  test('SyncState : l\'erreur survit aux mises à jour, null l\'efface', () {
    const initial = SyncState(
      isOnline: true,
      isSyncing: false,
      isFlushing: true,
      pendingCount: 2,
    );
    final enErreur = initial.copyWith(lastError: 'Lot refusé');
    expect(enErreur.copyWith(isFlushing: false).lastError, 'Lot refusé');
    expect(enErreur.copyWith(pendingCount: 1).lastError, 'Lot refusé');
    expect(enErreur.copyWith(lastError: null).lastError, isNull);
  });

  test('détection réseau : seule l\'absence de réponse signifie hors ligne', () {
    expect(SyncService.reponseRecue(null), isFalse);
    expect(SyncService.reponseRecue(200), isTrue);
    expect(SyncService.reponseRecue(403), isTrue);
    expect(SyncService.reponseRecue(500), isTrue);
  });

  group('OfflineMode', () {
    test('hors ligne : compte virtuel seul, rien pour un membre', () {
      expect(
        OfflineMode.modesDisponibles(allowVirtualAccount: true, offline: true)
            .keys,
        ['VIRTUAL_ACCOUNT'],
      );
      expect(
        OfflineMode.modesDisponibles(allowVirtualAccount: false, offline: true),
        isEmpty,
      );
      expect(
        OfflineMode.modeParDefaut(allowVirtualAccount: false, offline: true),
        isNull,
      );
      expect(
        OfflineMode.modesDisponibles(allowVirtualAccount: true, offline: false)
            .length,
        3,
      );
    });

    test('sansReseau : échec sans statut HTTP uniquement', () {
      expect(OfflineMode.sansReseau(success: false), isTrue);
      expect(OfflineMode.sansReseau(success: false, statusCode: 500), isFalse);
      expect(OfflineMode.sansReseau(success: true), isFalse);
    });

    test('tarifs : filtrés par type, identifiant et libellé normalisés', () {
      final tarifs = OfflineMode.tarifsPourType(
        tarifs: [
          {'idCotisationAffilie': 2, 'typeAdhesionId': 5, 'montant': 200},
          {'id': 3, 'typeAdhesionId': 6, 'montant': 300},
          {'id': 4, 'montant': 400},
          {'typeAdhesionId': 5, 'montant': 500},
        ],
        typeAdhesions: [
          {'idTypeAdhesion': 5, 'libelle': 'Famille'},
        ],
        typeAdhesionId: 5,
      );
      expect(tarifs, hasLength(1));
      expect(tarifs.single['id'], 2);
      expect(tarifs.single['typeAdhesionLibelle'], 'Famille');
      expect(tarifs.single['montant'], 200);
    });

    test('membreDepuis : champs lus par Mon réseau et la fiche', () {
      final membre = OfflineMode.membreDepuis(
        SyncAffilieRow.fromJson({
          'idAffilie': 10,
          'nom': 'Kabila',
          'prenom': 'Marie',
          'telephone': '0822222222',
          'codeAdhesion': 'AF-10',
          'typeAdhesionId': 5,
          'statutDossier': 'Validé',
          'statut': true,
        }),
        typeAdhesions: [
          {'id': 5, 'libelle': 'Solo'},
        ],
      );
      expect(membre['affilieId'], 10);
      expect(membre['phone'], '0822222222');
      expect(membre['matricule'], 'AF-10');
      expect(membre['typeAdhesion'], 'Solo');
      expect(membre['statutAffilie'], isTrue);
    });
  });
}
