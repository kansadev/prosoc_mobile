/// Modèles du contrat offline/sync — voir
/// `Prosoc_FRONTEND_INTEGRATION_OFFLINE_SYNC.md` (source : SyncController).
///
/// Tous les modèles exposent [toMap]/`fromJson` afin d'être persistés
/// manuellement dans Hive (pas de dépendance à un générateur de code).

/// Les deux seuls types d'écritures acceptés dans la file offline.
enum SyncWriteKind {
  collecte('COLLECTE'),
  adhesion('ADHESION_WITH_AFFILIE'),
  souscriptionPrestation('SOUSCRIPTION_PRESTATION');

  const SyncWriteKind(this.wire);

  final String wire;

  static SyncWriteKind? fromWire(String? value) {
    if (value == null) return null;
    for (final kind in SyncWriteKind.values) {
      if (kind.wire == value) return kind;
    }
    return null;
  }
}

/// Wallet virtuel synchronisé (scope de l'agent connecté).
class SyncWalletRow {
  final int idWalletVirtuelAgent;
  final int agentId;
  final String agentNom;
  final String agentMatricule;
  final int deviseId;
  final String deviseCode;
  final double soldeVirtuel;
  final bool statut;
  final String? updatedAt;

  const SyncWalletRow({
    required this.idWalletVirtuelAgent,
    required this.agentId,
    required this.agentNom,
    required this.agentMatricule,
    required this.deviseId,
    required this.deviseCode,
    required this.soldeVirtuel,
    required this.statut,
    this.updatedAt,
  });

  factory SyncWalletRow.fromJson(Map<String, dynamic> json) {
    return SyncWalletRow(
      idWalletVirtuelAgent: _int(
        json['idWalletVirtuelAgent'] ?? json['IdWalletVirtuelAgent'],
      ),
      agentId: _int(json['agentId'] ?? json['AgentId']),
      agentNom: _str(json['agentNom'] ?? json['AgentNom']),
      agentMatricule: _str(json['agentMatricule'] ?? json['AgentMatricule']),
      deviseId: _int(json['deviseId'] ?? json['DeviseId']),
      deviseCode: _str(json['deviseCode'] ?? json['DeviseCode']),
      soldeVirtuel: _dbl(json['soldeVirtuel'] ?? json['SoldeVirtuel']),
      statut: _bool(json['statut'] ?? json['Statut']),
      updatedAt: _nullableStr(json['updatedAt'] ?? json['UpdatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'idWalletVirtuelAgent': idWalletVirtuelAgent,
    'agentId': agentId,
    'agentNom': agentNom,
    'agentMatricule': agentMatricule,
    'deviseId': deviseId,
    'deviseCode': deviseCode,
    'soldeVirtuel': soldeVirtuel,
    'statut': statut,
    'updatedAt': updatedAt,
  };
}

/// Souscription de prestation synchronisée. Les lignes inactives
/// (`statut = false`) sont transmises pour répercuter les désactivations.
class SyncSouscriptionRow {
  final int idSouscriptionPrestation;
  final int affilieId;
  final int prestationId;
  final String? dateSouscription;
  final bool statut;
  final String? updatedAt;

  const SyncSouscriptionRow({
    required this.idSouscriptionPrestation,
    required this.affilieId,
    required this.prestationId,
    this.dateSouscription,
    required this.statut,
    this.updatedAt,
  });

  factory SyncSouscriptionRow.fromJson(Map<String, dynamic> json) {
    return SyncSouscriptionRow(
      idSouscriptionPrestation: _int(
        json['idSouscriptionPrestation'] ?? json['IdSouscriptionPrestation'],
      ),
      affilieId: _int(json['affilieId'] ?? json['AffilieId']),
      prestationId: _int(json['prestationId'] ?? json['PrestationId']),
      dateSouscription: _nullableStr(
        json['dateSouscription'] ?? json['DateSouscription'],
      ),
      statut: _bool(json['statut'] ?? json['Statut']),
      updatedAt: _nullableStr(json['updatedAt'] ?? json['UpdatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'idSouscriptionPrestation': idSouscriptionPrestation,
    'affilieId': affilieId,
    'prestationId': prestationId,
    'dateSouscription': dateSouscription,
    'statut': statut,
    'updatedAt': updatedAt,
  };
}

/// Affilié synchronisé (lecture seule offline).
class SyncAffilieRow {
  final int idAffilie;
  final String codeAdhesion;
  final String nom;
  final String prenom;
  final String nomComplet;
  final String? dateNaissance;
  final String? sexe;
  final String telephone;
  final String provinceResidence;
  final int adhesionId;
  final int agentGestionnaireId;
  final int typeAdhesionId;
  final String statutDossier;
  final bool statut;
  final String? updatedAt;
  final bool isDeleted;

  const SyncAffilieRow({
    required this.idAffilie,
    required this.codeAdhesion,
    required this.nom,
    required this.prenom,
    required this.nomComplet,
    this.dateNaissance,
    this.sexe,
    required this.telephone,
    required this.provinceResidence,
    required this.adhesionId,
    required this.agentGestionnaireId,
    required this.typeAdhesionId,
    required this.statutDossier,
    required this.statut,
    this.updatedAt,
    required this.isDeleted,
  });

  factory SyncAffilieRow.fromJson(Map<String, dynamic> json) {
    final nom = _str(json['nom'] ?? json['Nom']);
    final prenom = _str(json['prenom'] ?? json['Prenom']);
    return SyncAffilieRow(
      idAffilie: _int(json['idAffilie'] ?? json['IdAffilie']),
      codeAdhesion: _str(json['codeAdhesion'] ?? json['CodeAdhesion']),
      nom: nom,
      prenom: prenom,
      nomComplet: _str(json['nomComplet'] ?? json['NomComplet']).isNotEmpty
          ? _str(json['nomComplet'] ?? json['NomComplet'])
          : [prenom, nom].where((e) => e.isNotEmpty).join(' '),
      dateNaissance: _nullableStr(
        json['dateNaissance'] ?? json['DateNaissance'],
      ),
      sexe: _nullableStr(json['sexe'] ?? json['Sexe']),
      telephone: _str(json['telephone'] ?? json['Telephone']),
      provinceResidence: _str(
        json['provinceResidence'] ?? json['ProvinceResidence'],
      ),
      adhesionId: _int(json['adhesionId'] ?? json['AdhesionId']),
      agentGestionnaireId: _int(
        json['agentGestionnaireId'] ?? json['AgentGestionnaireId'],
      ),
      typeAdhesionId: _int(json['typeAdhesionId'] ?? json['TypeAdhesionId']),
      statutDossier: _str(json['statutDossier'] ?? json['StatutDossier']),
      statut: _bool(json['statut'] ?? json['Statut']),
      updatedAt: _nullableStr(json['updatedAt'] ?? json['UpdatedAt']),
      isDeleted: _bool(json['isDeleted'] ?? json['IsDeleted']),
    );
  }

  Map<String, dynamic> toMap() => {
    'idAffilie': idAffilie,
    'codeAdhesion': codeAdhesion,
    'nom': nom,
    'prenom': prenom,
    'nomComplet': nomComplet,
    'dateNaissance': dateNaissance,
    'sexe': sexe,
    'telephone': telephone,
    'provinceResidence': provinceResidence,
    'adhesionId': adhesionId,
    'agentGestionnaireId': agentGestionnaireId,
    'typeAdhesionId': typeAdhesionId,
    'statutDossier': statutDossier,
    'statut': statut,
    'updatedAt': updatedAt,
    'isDeleted': isDeleted,
  };

  /// Recherche texte utilisé par les fiches offline.
  bool matchesQuery(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return nomComplet.toLowerCase().contains(q) ||
        codeAdhesion.toLowerCase().contains(q) ||
        telephone.toLowerCase().contains(q);
  }
}

/// Réponse `GET /api/sync/bootstrap`.
class SyncBootstrap {
  final String schemaVersion;
  final String watermark;
  final String snapshot;
  final int affiliesCount;
  final int walletsCount;
  final double? plafondWalletVirtuel;
  final List<SyncWalletRow> wallets;

  const SyncBootstrap({
    required this.schemaVersion,
    required this.watermark,
    required this.snapshot,
    required this.affiliesCount,
    required this.walletsCount,
    this.plafondWalletVirtuel,
    required this.wallets,
  });

  bool get hasWatermark => watermark.trim().isNotEmpty;

  factory SyncBootstrap.fromJson(Map<String, dynamic> json) {
    return SyncBootstrap(
      schemaVersion: _str(json['schemaVersion'] ?? json['SchemaVersion']),
      watermark: _str(json['watermark'] ?? json['Watermark']),
      snapshot: _str(json['snapshot'] ?? json['Snapshot']),
      affiliesCount: _int(json['affiliesCount'] ?? json['AffiliesCount']),
      walletsCount: _int(json['walletsCount'] ?? json['WalletsCount']),
      plafondWalletVirtuel: _nullableDouble(
        json['plafondWalletVirtuel'] ?? json['PlafondWalletVirtuel'],
      ),
      wallets: _mapList(
        json['wallets'] ?? json['Wallets'],
      ).map(SyncWalletRow.fromJson).toList(),
    );
  }
}

/// Page générique `items` / `nextCursor` / `hasMore` / `nextSince`.
class SyncPage<T> {
  final String snapshot;
  final List<T> items;
  final String? nextCursor;
  final bool hasMore;
  final String? nextSince;

  const SyncPage({
    required this.snapshot,
    required this.items,
    this.nextCursor,
    required this.hasMore,
    this.nextSince,
  });

  static SyncPage<SyncAffilieRow> affilies(Map<String, dynamic> json) {
    return SyncPage<SyncAffilieRow>(
      snapshot: _str(json['snapshot'] ?? json['Snapshot']),
      items: _mapList(
        json['items'] ?? json['Items'],
      ).map(SyncAffilieRow.fromJson).toList(),
      nextCursor: _nullableStr(json['nextCursor'] ?? json['NextCursor']),
      hasMore: _bool(json['hasMore'] ?? json['HasMore']),
      nextSince: _nullableStr(json['nextSince'] ?? json['NextSince']),
    );
  }

  static SyncPage<SyncSouscriptionRow> souscriptions(Map<String, dynamic> json) {
    return SyncPage<SyncSouscriptionRow>(
      snapshot: _str(json['snapshot'] ?? json['Snapshot']),
      items: _mapList(
        json['items'] ?? json['Items'],
      ).map(SyncSouscriptionRow.fromJson).toList(),
      nextCursor: _nullableStr(json['nextCursor'] ?? json['NextCursor']),
      hasMore: _bool(json['hasMore'] ?? json['HasMore']),
      nextSince: _nullableStr(json['nextSince'] ?? json['NextSince']),
    );
  }

  static SyncPage<SyncWalletRow> wallets(Map<String, dynamic> json) {
    return SyncPage<SyncWalletRow>(
      snapshot: _str(json['snapshot'] ?? json['Snapshot']),
      items: _mapList(
        json['items'] ?? json['Items'],
      ).map(SyncWalletRow.fromJson).toList(),
      nextCursor: _nullableStr(json['nextCursor'] ?? json['NextCursor']),
      hasMore: _bool(json['hasMore'] ?? json['HasMore']),
      nextSince: _nullableStr(json['nextSince'] ?? json['NextSince']),
    );
  }
}

/// Catalogue métier `GET /api/sync/referentials`.
class SyncReferentials {
  final List<Map<String, dynamic>> typeAdhesions;
  final List<Map<String, dynamic>> devises;
  final List<Map<String, dynamic>> provinces;
  final List<Map<String, dynamic>> frais;
  final List<Map<String, dynamic>> prestations;
  final List<Map<String, dynamic>> tarifsCotisation;
  final double? plafondWalletVirtuel;
  final String? nextSince;
  final String snapshot;

  const SyncReferentials({
    required this.typeAdhesions,
    required this.devises,
    required this.provinces,
    required this.frais,
    required this.prestations,
    required this.tarifsCotisation,
    this.plafondWalletVirtuel,
    this.nextSince,
    required this.snapshot,
  });

  Map<String, dynamic> toMap() => {
    'typeAdhesions': typeAdhesions,
    'devises': devises,
    'provinces': provinces,
    'frais': frais,
    'prestations': prestations,
    'tarifsCotisation': tarifsCotisation,
    'plafondWalletVirtuel': plafondWalletVirtuel,
    'nextSince': nextSince,
    'snapshot': snapshot,
  };

  /// Aucune donnée utile au formulaire d'adhésion.
  bool get isEmpty =>
      typeAdhesions.isEmpty && devises.isEmpty && frais.isEmpty;

  /// Applique un delta (`since`) : upsert par identifiant, liste par liste,
  /// comme le prévoit le contrat de synchronisation.
  SyncReferentials mergedWith(SyncReferentials delta) {
    List<Map<String, dynamic>> merge(
      List<Map<String, dynamic>> base,
      List<Map<String, dynamic>> changes,
    ) {
      if (changes.isEmpty) return base;
      final byId = <String, Map<String, dynamic>>{
        for (final row in base) _referentialId(row) ?? '${row.hashCode}': row,
      };
      for (final row in changes) {
        byId[_referentialId(row) ?? '${row.hashCode}'] = row;
      }
      return byId.values.toList();
    }

    return SyncReferentials(
      typeAdhesions: merge(typeAdhesions, delta.typeAdhesions),
      devises: merge(devises, delta.devises),
      provinces: merge(provinces, delta.provinces),
      frais: merge(frais, delta.frais),
      prestations: merge(prestations, delta.prestations),
      tarifsCotisation: merge(tarifsCotisation, delta.tarifsCotisation),
      plafondWalletVirtuel:
          delta.plafondWalletVirtuel ?? plafondWalletVirtuel,
      nextSince: delta.nextSince ?? nextSince,
      snapshot: delta.snapshot.isNotEmpty ? delta.snapshot : snapshot,
    );
  }

  /// Identifiant d'une ligne de référentiel : `id`, sinon le premier champ
  /// `idXxx` (idFrais, idDevise, idPrestation…).
  static String? _referentialId(Map<String, dynamic> row) {
    final direct = row['id'] ?? row['Id'];
    if (direct != null) return direct.toString();
    for (final entry in row.entries) {
      final key = entry.key;
      if (key.length > 2 &&
          key.toLowerCase().startsWith('id') &&
          key[2] == key[2].toUpperCase() &&
          entry.value != null) {
        return '$key:${entry.value}';
      }
    }
    return null;
  }

  static SyncReferentials? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    return SyncReferentials(
      typeAdhesions: _mapList(map['typeAdhesions']),
      devises: _mapList(map['devises']),
      provinces: _mapList(map['provinces']),
      frais: _mapList(map['frais']),
      prestations: _mapList(map['prestations']),
      tarifsCotisation: _mapList(map['tarifsCotisation']),
      plafondWalletVirtuel: _nullableDouble(map['plafondWalletVirtuel']),
      nextSince: _nullableStr(map['nextSince']),
      snapshot: _str(map['snapshot']),
    );
  }

  factory SyncReferentials.fromJson(Map<String, dynamic> json) {
    return SyncReferentials(
      typeAdhesions: _mapList(json['typeAdhesions'] ?? json['TypeAdhesions']),
      devises: _mapList(json['devises'] ?? json['Devises']),
      provinces: _mapList(json['provinces'] ?? json['Provinces']),
      frais: _mapList(json['frais'] ?? json['Frais']),
      prestations: _mapList(json['prestations'] ?? json['Prestations']),
      tarifsCotisation: _mapList(
        json['tarifsCotisation'] ?? json['TarifsCotisation'],
      ),
      plafondWalletVirtuel: _nullableDouble(
        json['plafondWalletVirtuel'] ?? json['PlafondWalletVirtuel'],
      ),
      nextSince: _nullableStr(json['nextSince'] ?? json['NextSince']),
      snapshot: _str(json['snapshot'] ?? json['Snapshot']),
    );
  }
}

/// Purge incrémentale `GET /api/sync/deletions`.
class SyncDeletions {
  final List<int> deletedAffilieIds;
  final List<int> deactivatedAffilieIds;
  final List<int> removedAdhesionIds;
  final String? nextSince;
  final String snapshot;

  const SyncDeletions({
    required this.deletedAffilieIds,
    required this.deactivatedAffilieIds,
    required this.removedAdhesionIds,
    this.nextSince,
    required this.snapshot,
  });

  factory SyncDeletions.fromJson(Map<String, dynamic> json) {
    return SyncDeletions(
      deletedAffilieIds: _intList(
        json['deletedAffilieIds'] ?? json['DeletedAffilieIds'],
      ),
      deactivatedAffilieIds: _intList(
        json['deactivatedAffilieIds'] ?? json['DeactivatedAffilieIds'],
      ),
      removedAdhesionIds: _intList(
        json['removedAdhesionIds'] ?? json['RemovedAdhesionIds'],
      ),
      nextSince: _nullableStr(json['nextSince'] ?? json['NextSince']),
      snapshot: _str(json['snapshot'] ?? json['Snapshot']),
    );
  }
}

/// Résultat d'une écriture de la file.
class SyncWriteResult {
  final String clientRequestId;
  final String status; // created | duplicate | rejected | error
  final int? entityId;
  final int? affilieId;
  final int? walletAgentId;
  final double? nouveauSoldeWallet;
  final String? message;
  final String? errorCode;

  const SyncWriteResult({
    required this.clientRequestId,
    required this.status,
    this.entityId,
    this.affilieId,
    this.walletAgentId,
    this.nouveauSoldeWallet,
    this.message,
    this.errorCode,
  });

  bool get isCreated => status.toLowerCase() == 'created';
  bool get isDuplicate => status.toLowerCase() == 'duplicate';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isError => status.toLowerCase() == 'error';

  factory SyncWriteResult.fromJson(Map<String, dynamic> json) {
    return SyncWriteResult(
      clientRequestId: _str(json['clientRequestId'] ?? json['ClientRequestId']),
      status: _str(json['status'] ?? json['Status']),
      entityId: _nullableInt(json['entityId'] ?? json['EntityId']),
      affilieId: _nullableInt(json['affilieId'] ?? json['AffilieId']),
      walletAgentId: _nullableInt(
        json['walletAgentId'] ?? json['WalletAgentId'],
      ),
      nouveauSoldeWallet: _nullableDouble(
        json['nouveauSoldeWallet'] ?? json['NouveauSoldeWallet'],
      ),
      message: _nullableStr(json['message'] ?? json['Message']),
      errorCode: _nullableStr(json['errorCode'] ?? json['ErrorCode']),
    );
  }
}

class SyncWriteSummary {
  final int total;
  final int created;
  final int duplicates;
  final int rejected;
  final int errors;

  const SyncWriteSummary({
    required this.total,
    required this.created,
    required this.duplicates,
    required this.rejected,
    required this.errors,
  });

  factory SyncWriteSummary.fromJson(Map<String, dynamic> json) {
    return SyncWriteSummary(
      total: _int(json['total'] ?? json['Total']),
      created: _int(json['created'] ?? json['Created']),
      duplicates: _int(json['duplicates'] ?? json['Duplicates']),
      rejected: _int(json['rejected'] ?? json['Rejected']),
      errors: _int(json['errors'] ?? json['Errors']),
    );
  }
}

/// Réponse `POST /api/sync/writes/batch`.
class SyncWriteBatchResult {
  final List<SyncWriteResult> results;
  final SyncWriteSummary summary;

  const SyncWriteBatchResult({required this.results, required this.summary});

  factory SyncWriteBatchResult.fromJson(Map<String, dynamic> json) {
    return SyncWriteBatchResult(
      results: _mapList(
        json['results'] ?? json['Results'],
      ).map(SyncWriteResult.fromJson).toList(),
      summary: SyncWriteSummary.fromJson(
        (json['summary'] ?? json['Summary']) is Map
            ? Map<String, dynamic>.from(
                (json['summary'] ?? json['Summary']) as Map,
              )
            : <String, dynamic>{},
      ),
    );
  }
}

/// Élément de la file locale (payload + idempotence + cycle de vie).
class SyncQueueEntry {
  final String clientRequestId;
  final SyncWriteKind kind;
  final Map<String, dynamic> payload;
  final String deviceId;
  final String dateOperationUtc;
  final String localStatus; // pending | syncing | failed
  final int attempts;
  final String createdAt;
  final String? lastError;
  final String? label;

  const SyncQueueEntry({
    required this.clientRequestId,
    required this.kind,
    required this.payload,
    required this.deviceId,
    required this.dateOperationUtc,
    this.localStatus = 'pending',
    this.attempts = 0,
    required this.createdAt,
    this.lastError,
    this.label,
  });

  SyncQueueEntry copyWith({
    String? localStatus,
    int? attempts,
    String? lastError,
  }) {
    return SyncQueueEntry(
      clientRequestId: clientRequestId,
      kind: kind,
      payload: payload,
      deviceId: deviceId,
      dateOperationUtc: dateOperationUtc,
      localStatus: localStatus ?? this.localStatus,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt,
      lastError: lastError ?? this.lastError,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toMap() => {
    'clientRequestId': clientRequestId,
    'type': kind.wire,
    'deviceId': deviceId,
    'dateOperationUtc': dateOperationUtc,
    'localStatus': localStatus,
    'attempts': attempts,
    'createdAt': createdAt,
    'lastError': lastError,
    'label': label,
    'payload': payload,
  };

  /// Élément du corps de `POST /api/sync/writes/batch`. [toMap] sert au stockage
  /// local : ses champs de suivi ne doivent pas partir au serveur.
  Map<String, dynamic> toWire() => {
    'clientRequestId': clientRequestId,
    'type': kind.wire,
    'deviceId': deviceId,
    'dateOperationUtc': dateOperationUtc,
    ...switch (kind) {
      SyncWriteKind.collecte => {'collecte': payload},
      SyncWriteKind.adhesion => {'adhesion': payload['adhesion']},
      SyncWriteKind.souscriptionPrestation => {
        'souscriptionPrestation': {
          'affilieId': payload['affilieId'],
          'achat': payload['achat'],
        },
      },
    },
  };

  static SyncQueueEntry? fromMap(Map<String, dynamic> map) {
    final id = _str(map['clientRequestId']);
    if (id.isEmpty) return null;
    final kind = SyncWriteKind.fromWire(_str(map['type']));
    if (kind == null) return null;
    final payload = map['payload'];
    return SyncQueueEntry(
      clientRequestId: id,
      kind: kind,
      payload: payload is Map ? deepStringMap(payload) : <String, dynamic>{},
      deviceId: _str(map['deviceId']),
      dateOperationUtc: _str(map['dateOperationUtc']),
      localStatus: _str(map['localStatus'], fallback: 'pending'),
      attempts: _int(map['attempts']),
      createdAt: _str(map['createdAt']),
      lastError: _nullableStr(map['lastError']),
      label: _nullableStr(map['label']),
    );
  }
}

// ---------- Helpers de parsing tolérants (camelCase / PascalCase) ----------

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _nullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double _dbl(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _nullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

bool _bool(dynamic value) {
  if (value is bool) return value;
  final normalized = value?.toString().toLowerCase();
  return normalized == 'true' || normalized == '1';
}

String _str(dynamic value, {String fallback = ''}) {
  final text = value?.toString();
  if (text == null || text.trim().isEmpty) return fallback;
  return text.trim();
}

String? _nullableStr(dynamic value) {
  final text = value?.toString().trim();
  return (text == null || text.isEmpty) ? null : text;
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map(deepStringMap).toList();
}

/// Convertit récursivement une map relue depuis Hive (`Map<dynamic, dynamic>`,
/// y compris les maps et listes imbriquées) en `Map<String, dynamic>`.
Map<String, dynamic> deepStringMap(Map raw) =>
    raw.map((key, value) => MapEntry(key.toString(), _deepValue(value)));

dynamic _deepValue(dynamic value) {
  if (value is Map) return deepStringMap(value);
  if (value is List) return value.map(_deepValue).toList();
  return value;
}

List<int> _intList(dynamic value) {
  if (value is! List) return const [];
  return value.map((e) => _int(e)).toList();
}
