import 'package:hive_flutter/hive_flutter.dart';

import 'sync_models.dart';

/// Nom des boxes Hive utilisées par le mode offline.
abstract final class OfflineBoxes {
  static const String meta = 'offline_meta';
  static const String affilies = 'offline_affilies';
  static const String wallets = 'offline_wallets';
  static const String referentials = 'offline_referentials';
  static const String writeQueue = 'offline_write_queue';
  static const String journal = 'offline_journal';
}

/// Clés de la box `offline_meta`.
abstract final class OfflineMetaKeys {
  static const String schemaVersion = 'schemaVersion';
  static const String watermark = 'watermark';
  static const String snapshot = 'snapshot';
  static const String plafondWalletVirtuel = 'plafondWalletVirtuel';
  static const String lastSyncAt = 'lastSyncAt';
  static const String lastSyncError = 'lastSyncError';
  static const String lastSyncErrorAt = 'lastSyncErrorAt';
  static const String dbVersion = 'dbVersion';
  static const String deviceId = 'deviceId';
}

/// Statuts locaux d'un élément de la file d'écritures.
abstract final class SyncLocalStatus {
  static const String pending = 'pending';
  static const String syncing = 'syncing';
  static const String failed = 'failed';
}

/// Accès centralisé à la base locale Hive.
///
/// Les boxes sont ouvertes en mode « dynamic » et les valeurs sont
/// (dé)sérialisées manuellement via [toMap]/`fromMap` : aucune dépendance à
/// un générateur de code ni à un TypeAdapter.
class OfflineDatabase {
  OfflineDatabase._();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<dynamic>(OfflineBoxes.meta),
      Hive.openBox<dynamic>(OfflineBoxes.affilies),
      Hive.openBox<dynamic>(OfflineBoxes.wallets),
      Hive.openBox<dynamic>(OfflineBoxes.referentials),
      Hive.openBox<dynamic>(OfflineBoxes.writeQueue),
      Hive.openBox<dynamic>(OfflineBoxes.journal),
    ]);
    _initialized = true;
    await _migrateIfNeeded();
  }

  /// Vide les données de sync (déconnexion / changement de compte).
  static Future<void> clearSyncData() async {
    if (!_initialized) return;
    await Future.wait([
      _box(OfflineBoxes.affilies).clear(),
      _box(OfflineBoxes.wallets).clear(),
      _box(OfflineBoxes.referentials).clear(),
      _box(OfflineBoxes.writeQueue).clear(),
      _box(OfflineBoxes.journal).clear(),
    ]);
    final meta = _box(OfflineBoxes.meta);
    await meta.delete(OfflineMetaKeys.watermark);
    await meta.delete(OfflineMetaKeys.snapshot);
    await meta.delete(OfflineMetaKeys.plafondWalletVirtuel);
    await meta.delete(OfflineMetaKeys.lastSyncAt);
    await meta.delete(OfflineMetaKeys.lastSyncError);
    await meta.delete(OfflineMetaKeys.lastSyncErrorAt);
  }

  /// Version de schéma de la base locale.
  static Future<void> _migrateIfNeeded() async {
    final meta = _box(OfflineBoxes.meta);
    const current = 1;
    final stored = meta.get(OfflineMetaKeys.dbVersion);
    if (stored == current) return;
    await meta.put(OfflineMetaKeys.dbVersion, current);
  }

  // ---------- Meta ----------

  static Box<dynamic> _box(String name) => Hive.box<dynamic>(name);

  static Box<dynamic> get metaBox => _box(OfflineBoxes.meta);

  static String? get watermark =>
      metaBox.get(OfflineMetaKeys.watermark)?.toString();

  static String? get snapshot =>
      metaBox.get(OfflineMetaKeys.snapshot)?.toString();

  static double? get plafondWalletVirtuel =>
      (metaBox.get(OfflineMetaKeys.plafondWalletVirtuel) as num?)?.toDouble();

  static DateTime? get lastSyncAt {
    final raw = metaBox.get(OfflineMetaKeys.lastSyncAt)?.toString();
    return raw == null ? null : DateTime.tryParse(raw)?.toLocal();
  }

  static Future<void> saveWatermark(String? value) async {
    final meta = metaBox;
    if (value == null || value.trim().isEmpty) {
      await meta.delete(OfflineMetaKeys.watermark);
    } else {
      await meta.put(OfflineMetaKeys.watermark, value.trim());
    }
  }

  static Future<void> saveSnapshot(String? value) async {
    final meta = metaBox;
    if (value == null || value.trim().isEmpty) {
      await meta.delete(OfflineMetaKeys.snapshot);
    } else {
      await meta.put(OfflineMetaKeys.snapshot, value.trim());
    }
  }

  static Future<void> savePlafond(double? value) async {
    final meta = metaBox;
    if (value == null) {
      await meta.delete(OfflineMetaKeys.plafondWalletVirtuel);
    } else {
      await meta.put(OfflineMetaKeys.plafondWalletVirtuel, value);
    }
  }

  static Future<void> markSyncedNow() async {
    await metaBox.put(
      OfflineMetaKeys.lastSyncAt,
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  static Future<void> saveSyncError(String message) async {
    await metaBox.put(OfflineMetaKeys.lastSyncError, message);
    await metaBox.put(
      OfflineMetaKeys.lastSyncErrorAt,
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  static Future<void> clearSyncError() async {
    await metaBox.delete(OfflineMetaKeys.lastSyncError);
    await metaBox.delete(OfflineMetaKeys.lastSyncErrorAt);
  }

  // ---------- Affiliés ----------

  static List<SyncAffilieRow> get affilies {
    final box = _box(OfflineBoxes.affilies);
    final rows = <SyncAffilieRow>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is Map) {
        final row = SyncAffilieRow.fromJson(Map<String, dynamic>.from(raw));
        if (row.idAffilie > 0 && !row.isDeleted) rows.add(row);
      }
    }
    rows.sort((a, b) => a.nomComplet.compareTo(b.nomComplet));
    return rows;
  }

  static SyncAffilieRow? affilieById(int id) {
    final raw = _box(OfflineBoxes.affilies).get(id.toString());
    if (raw is Map) {
      final row = SyncAffilieRow.fromJson(Map<String, dynamic>.from(raw));
      return row.isDeleted ? null : row;
    }
    return null;
  }

  static Future<void> upsertAffilies(List<SyncAffilieRow> rows) async {
    if (rows.isEmpty) return;
    final box = _box(OfflineBoxes.affilies);
    await box.putAll({
      for (final row in rows) row.idAffilie.toString(): row.toMap(),
    });
  }

  // ---------- Wallets ----------

  static List<SyncWalletRow> get wallets {
    final box = _box(OfflineBoxes.wallets);
    final rows = <SyncWalletRow>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is Map) {
        final row = SyncWalletRow.fromJson(Map<String, dynamic>.from(raw));
        if (row.agentId > 0) rows.add(row);
      }
    }
    rows.sort((a, b) => a.agentNom.compareTo(b.agentNom));
    return rows;
  }

  static SyncWalletRow? walletByAgent(int agentId) {
    final box = _box(OfflineBoxes.wallets);
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is Map) {
        final row = SyncWalletRow.fromJson(Map<String, dynamic>.from(raw));
        if (row.agentId == agentId) return row;
      }
    }
    return null;
  }

  static Future<void> upsertWallets(List<SyncWalletRow> rows) async {
    if (rows.isEmpty) return;
    final box = _box(OfflineBoxes.wallets);
    await box.putAll({
      for (final row in rows) 'agent:${row.agentId}': row.toMap(),
    });
  }

  /// Applique le solde serveur renvoyé par le batch (source de vérité).
  static Future<void> applyServerSolde(
    int? walletAgentId,
    double? solde,
  ) async {
    if (walletAgentId == null || solde == null) return;
    final box = _box(OfflineBoxes.wallets);
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      if ((map['agentId'] as num?)?.toInt() == walletAgentId) {
        map['soldeVirtuel'] = solde;
        await box.put(key, map);
        return;
      }
    }
  }

  // ---------- Référentiels ----------

  static SyncReferentials? get referentials =>
      SyncReferentials.fromMap(_box(OfflineBoxes.referentials).get('data'));

  static Future<void> saveReferentials(SyncReferentials value) async {
    await _box(OfflineBoxes.referentials).put('data', value.toMap());
  }

  // ---------- Deletions ----------

  static Future<void> applyDeletions(SyncDeletions deletions) async {
    final affilies = _box(OfflineBoxes.affilies);

    Future<void> deactivate(List<int> ids) async {
      for (final id in ids) {
        final raw = affilies.get(id.toString());
        if (raw is Map) {
          final map = Map<String, dynamic>.from(raw);
          map['statut'] = false;
          await affilies.put(id.toString(), map);
        }
      }
    }

    await deactivate(deletions.deactivatedAffilieIds);
    for (final id in deletions.deletedAffilieIds) {
      await affilies.delete(id.toString());
    }
    // removedAdhesionIds : les adhésions ne sont pas cachées localement en v1,
    // l'information est journalisée pour le support.
    if (deletions.removedAdhesionIds.isNotEmpty) {
      await addJournalEntry({
        'at': DateTime.now().toUtc().toIso8601String(),
        'kind': 'removed_adhesions',
        'ids': deletions.removedAdhesionIds,
      });
    }
  }

  // ---------- File d'écritures ----------

  static List<SyncQueueEntry> get writeQueue {
    final box = _box(OfflineBoxes.writeQueue);
    final entries = <SyncQueueEntry>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is Map) {
        final entry = SyncQueueEntry.fromMap(Map<String, dynamic>.from(raw));
        if (entry != null) entries.add(entry);
      }
    }
    entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return entries;
  }

  static int get pendingWriteCount => writeQueue.length;

  static List<SyncQueueEntry> get pendingWrites => writeQueue
      .where((e) => e.localStatus != SyncLocalStatus.syncing)
      .toList();

  static Future<void> enqueueWrite(SyncQueueEntry entry) async {
    await _box(
      OfflineBoxes.writeQueue,
    ).put(entry.clientRequestId, entry.toMap());
  }

  static Future<void> updateWriteStatus(
    String clientRequestId, {
    required String localStatus,
    int? attempts,
    String? lastError,
  }) async {
    final box = _box(OfflineBoxes.writeQueue);
    final raw = box.get(clientRequestId);
    if (raw is! Map) return;
    final entry = SyncQueueEntry.fromMap(Map<String, dynamic>.from(raw));
    if (entry == null) return;
    await box.put(
      clientRequestId,
      entry
          .copyWith(
            localStatus: localStatus,
            attempts: attempts,
            lastError: lastError,
          )
          .toMap(),
    );
  }

  static Future<void> removeWrite(String clientRequestId) async {
    await _box(OfflineBoxes.writeQueue).delete(clientRequestId);
  }

  static Future<void> addJournalEntry(Map<String, dynamic> entry) async {
    await _box(OfflineBoxes.journal).add(entry);
  }

  static List<Map<String, dynamic>> get journalEntries {
    final box = _box(OfflineBoxes.journal);
    return box.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Identifiant d'appareil stable pour la traçabilité des écritures.
  static String get deviceId {
    final existing = metaBox.get(OfflineMetaKeys.deviceId)?.toString();
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = 'dev-${DateTime.now().millisecondsSinceEpoch}';
    metaBox.put(OfflineMetaKeys.deviceId, generated);
    return generated;
  }
}
