import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../config/api.dart';
import 'auth_service.dart';
import '../offline/offline_database.dart';
import '../offline/sync_models.dart';

/// État observable du mode offline (bandeau / badge de l'UI).
class SyncState {
  final bool isOnline;
  final bool isSyncing;
  final bool isFlushing;
  final int pendingCount;
  final DateTime? lastSyncAt;
  final String? lastError;

  const SyncState({
    required this.isOnline,
    required this.isSyncing,
    required this.isFlushing,
    required this.pendingCount,
    this.lastSyncAt,
    this.lastError,
  });

  SyncState copyWith({
    bool? isOnline,
    bool? isSyncing,
    bool? isFlushing,
    int? pendingCount,
    DateTime? lastSyncAt,
    String? lastError,
  }) {
    return SyncState(
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      isFlushing: isFlushing ?? this.isFlushing,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastError: lastError,
    );
  }
}

/// Service central du mode hors ligne terrain.
///
/// Implémente le cycle décrit dans `Prosoc_FRONTEND_INTEGRATION_OFFLINE_SYNC.md` :
/// cold start (bootstrap → référentiels → pages affiliés / wallets), deltas
/// `since`/`cursor`, purge `deletions`, puis file d'écritures idempotentes
/// (`clientRequestId` figé à la création) rejouée via
/// `POST /api/sync/writes/batch`.
class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  /// Générateur d'UUID v4 local (aucune dépendance supplémentaire).
  static final Uuid _uuid = Uuid._();

  static const _maxBatchItems = 50;
  static const _maxAttempts = 6;
  static const _connectivityTimeout = Duration(seconds: 6);

  final ValueNotifier<SyncState> state = ValueNotifier(
    const SyncState(
      isOnline: true,
      isSyncing: false,
      isFlushing: false,
      pendingCount: 0,
    ),
  );

  Timer? _probeTimer;
  bool _started = false;

  bool get isOnline => state.value.isOnline;
  int get pendingCount => state.value.pendingCount;

  /// Initialise le service (base locale + premier test de connectivité).
  Future<void> start() async {
    if (_started) return;
    _started = true;
    await OfflineDatabase.init();
    _refreshPendingCount();
    state.value = state.value.copyWith(lastSyncAt: OfflineDatabase.lastSyncAt);
    await refreshOnlineStatus();
    _probeTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _backgroundTick(),
    );
  }

  void dispose() {
    _probeTimer?.cancel();
    _probeTimer = null;
    _started = false;
    state.dispose();
  }

  Future<void> _backgroundTick() async {
    await refreshOnlineStatus();
    if (state.value.isOnline) {
      if (state.value.pendingCount > 0) {
        await flushQueue();
      } else {
        await syncIfOnline();
      }
    }
  }

  void _refreshPendingCount() {
    state.value = state.value.copyWith(
      pendingCount: OfflineDatabase.pendingWriteCount,
    );
  }

  /// Teste la connectivité par une requête réelle (toute réponse = en ligne).
  Future<bool> refreshOnlineStatus() async {
    final online = await _probeOnline();
    if (state.value.isOnline != online) {
      state.value = state.value.copyWith(isOnline: online);
      if (online) {
        unawaited(_backgroundTick());
      }
    }
    return online;
  }

  Future<bool> _probeOnline() async {
    try {
      await ApiService.syncBootstrap().timeout(_connectivityTimeout);
      return true;
    } catch (_) {
      // Hors ligne : timeout, DNS, socket…
      return false;
    }
  }

  // ============================================================
  // LECTURE — synchronisation descendante
  // ============================================================

  /// Cold start complet : bootstrap → référentiels → affiliés → wallets.
  ///
  /// En delta (un [watermark] est déjà connu), seuls les changements depuis ce
  /// watermark sont rapatriés.
  Future<bool> syncAll() async {
    if (state.value.isSyncing) return false;
    if (!await refreshOnlineStatus()) return false;

    state.value = state.value.copyWith(isSyncing: true, lastError: null);

    try {
      final bootstrap = await ApiService.syncBootstrap();
      if (!bootstrap.success || bootstrap.data == null) {
        await OfflineDatabase.saveSyncError(
          bootstrap.message ?? 'Bootstrap sync impossible',
        );
        state.value = state.value.copyWith(
          lastError: bootstrap.message ?? 'Bootstrap sync impossible',
        );
        return false;
      }

      final data = bootstrap.data!;
      await OfflineDatabase.saveWatermark(
        data.hasWatermark ? data.watermark : null,
      );
      await OfflineDatabase.saveSnapshot(
        data.snapshot.isNotEmpty ? data.snapshot : null,
      );
      await OfflineDatabase.savePlafond(data.plafondWalletVirtuel);
      await OfflineDatabase.upsertWallets(data.wallets);

      await _syncReferentials();
      final affiliesOk = await _syncAffilies();
      final walletsOk = await _syncWallets();

      if (!affiliesOk || !walletsOk) return false;

      await _syncDeletions();
      await OfflineDatabase.clearSyncError();
      await OfflineDatabase.markSyncedNow();
      state.value = state.value.copyWith(
        lastSyncAt: OfflineDatabase.lastSyncAt,
      );
      _refreshPendingCount();
      return true;
    } catch (e) {
      await OfflineDatabase.saveSyncError('Sync impossible: $e');
      state.value = state.value.copyWith(lastError: 'Sync impossible');
      return false;
    } finally {
      state.value = state.value.copyWith(isSyncing: false);
    }
  }

  /// Synchronise uniquement si l'appareil est en ligne.
  Future<bool> syncIfOnline() async {
    if (!isOnline) return false;
    if (OfflineDatabase.lastSyncAt == null) return syncAll();
    return syncAll();
  }

  Future<void> _syncReferentials() async {
    final response = await ApiService.syncReferentials(
      since: OfflineDatabase.watermark,
      snapshot: OfflineDatabase.snapshot,
    );
    if (response.success && response.data != null) {
      final refs = response.data!;
      await OfflineDatabase.saveReferentials(refs);
      if (refs.nextSince != null) {
        await OfflineDatabase.saveWatermark(refs.nextSince);
      }
      await OfflineDatabase.savePlafond(refs.plafondWalletVirtuel);
    }
  }

  Future<bool> _syncAffilies() async {
    var cursor = '';
    var guard = 0;
    while (guard++ < 500) {
      final response = await ApiService.syncAffilies(
        since: OfflineDatabase.watermark,
        cursor: cursor.isEmpty ? null : cursor,
        snapshot: OfflineDatabase.snapshot,
      );
      if (!response.success || response.data == null) {
        await OfflineDatabase.saveSyncError(
          response.message ?? 'Sync affiliés impossible',
        );
        state.value = state.value.copyWith(
          lastError: response.message ?? 'Sync affiliés impossible',
        );
        return false;
      }
      final page = response.data!;
      await OfflineDatabase.upsertAffilies(page.items);
      if (page.snapshot.isNotEmpty) {
        await OfflineDatabase.saveSnapshot(page.snapshot);
      }
      if (!page.hasMore) break;
      final next = page.nextCursor;
      if (next == null || next.isEmpty) break;
      cursor = next;
    }
    return true;
  }

  Future<bool> _syncWallets() async {
    var cursor = '';
    var guard = 0;
    while (guard++ < 100) {
      final response = await ApiService.syncWallets(
        since: OfflineDatabase.watermark,
        cursor: cursor.isEmpty ? null : cursor,
        snapshot: OfflineDatabase.snapshot,
      );
      if (!response.success || response.data == null) {
        await OfflineDatabase.saveSyncError(
          response.message ?? 'Sync wallets impossible',
        );
        state.value = state.value.copyWith(
          lastError: response.message ?? 'Sync wallets impossible',
        );
        return false;
      }
      final page = response.data!;
      await OfflineDatabase.upsertWallets(page.items);
      if (page.snapshot.isNotEmpty) {
        await OfflineDatabase.saveSnapshot(page.snapshot);
      }
      if (!page.hasMore) break;
      final next = page.nextCursor;
      if (next == null || next.isEmpty) break;
      cursor = next;
    }
    return true;
  }

  Future<void> _syncDeletions() async {
    final since = OfflineDatabase.watermark;
    if (since == null || since.trim().isEmpty) return; // since obligatoire
    final response = await ApiService.syncDeletions(
      since: since,
      snapshot: OfflineDatabase.snapshot,
    );
    if (response.success && response.data != null) {
      await OfflineDatabase.applyDeletions(response.data!);
      if (response.data!.nextSince != null) {
        await OfflineDatabase.saveWatermark(response.data!.nextSince);
      }
    }
  }

  // ============================================================
  // ÉCRITURE — file locale idempotente
  // ============================================================

  /// Met en file une collecte (mode VIRTUAL_ACCOUNT uniquement).
  ///
  /// [typeCollecte] suit la charte `AdhesionApiValues`
  /// (`FRAIS` / `COTISATION` / `SOUSCRIPTION`), identique à `CollecteCreateDto`.
  ///
  /// [clientRequestId] peut être fourni pour rejouer exactement la même
  /// écriture ; il est sinon figé une fois pour toutes à la création locale.
  Future<SyncQueueEntry> enqueueCollecte({
    required String typeCollecte,
    required int fraisId,
    required int affilieId,
    required int agentId,
    required double montant,
    required int deviseId,
    required int mois,
    required int annee,
    int? cotisationAffilieId,
    int? souscriptionPrestationId,
    String statutPaiement = 'VALIDE',
    String? label,
    String? clientRequestId,
  }) async {
    final entry = _buildEntry(
      kind: SyncWriteKind.collecte,
      clientRequestId: clientRequestId,
      label: label,
      payload: {
        'typeCollecte': typeCollecte,
        if (fraisId > 0) 'fraisId': fraisId,
        if (cotisationAffilieId != null && cotisationAffilieId > 0)
          'cotisationAffilieId': cotisationAffilieId,
        if (souscriptionPrestationId != null && souscriptionPrestationId > 0)
          'souscriptionPrestationId': souscriptionPrestationId,
        'affilieId': affilieId,
        'agentId': agentId,
        'montant': montant,
        'deviseId': deviseId,
        'modePaiement': 'VIRTUAL_ACCOUNT',
        'statutPaiement': statutPaiement,
        'mois': mois,
        'annee': annee,
        'statut': true,
      },
    );
    await OfflineDatabase.enqueueWrite(entry);
    _refreshPendingCount();
    return entry;
  }

  /// Met en file une adhésion complète (affilié + collectes VIRTUAL_ACCOUNT).
  Future<SyncQueueEntry> enqueueAdhesion({
    required Map<String, dynamic> adhesion,
    String? label,
    String? clientRequestId,
  }) async {
    final entry = _buildEntry(
      kind: SyncWriteKind.adhesion,
      clientRequestId: clientRequestId,
      label: label,
      payload: {'adhesion': adhesion},
    );
    await OfflineDatabase.enqueueWrite(entry);
    _refreshPendingCount();
    return entry;
  }

  SyncQueueEntry _buildEntry({
    required SyncWriteKind kind,
    required Map<String, dynamic> payload,
    String? clientRequestId,
    String? label,
  }) {
    final id = (clientRequestId != null && clientRequestId.trim().isNotEmpty)
        ? clientRequestId.trim()
        : _uuid.v4();
    final nowUtc = DateTime.now().toUtc();
    return SyncQueueEntry(
      clientRequestId: id,
      kind: kind,
      payload: payload,
      deviceId: OfflineDatabase.deviceId,
      dateOperationUtc: nowUtc.toIso8601String(),
      createdAt: nowUtc.toIso8601String(),
      label: label,
    );
  }

  // ============================================================
  // UPLOAD — rejeu de la file
  // ============================================================

  /// Envoie la file par lots et traite les 4 statuts du serveur.
  ///
  /// Retourne le nombre d'écritures effectivement confirmées.
  Future<SyncFlushReport> flushQueue() async {
    if (state.value.isFlushing) {
      return SyncFlushReport.empty();
    }
    if (!await refreshOnlineStatus()) return SyncFlushReport.empty();

    state.value = state.value.copyWith(isFlushing: true);
    var created = 0;
    var duplicates = 0;
    var rejected = 0;
    var kept = 0;

    try {
      while (true) {
        final pending = OfflineDatabase.pendingWrites;
        if (pending.isEmpty) break;

        final batch = pending.take(_maxBatchItems).toList();
        for (final entry in batch) {
          await OfflineDatabase.updateWriteStatus(
            entry.clientRequestId,
            localStatus: SyncLocalStatus.syncing,
            attempts: entry.attempts + 1,
          );
        }

        final response = await ApiService.syncWritesBatch(
          batch.map((e) => e.toMap()).toList(),
        );

        if (!response.success || response.data == null) {
          // Erreur réseau/serveur globale : tout reste en file (backoff).
          for (final entry in batch) {
            final attempts = entry.attempts + 1;
            await OfflineDatabase.updateWriteStatus(
              entry.clientRequestId,
              localStatus: attempts >= _maxAttempts
                  ? SyncLocalStatus.failed
                  : SyncLocalStatus.pending,
              attempts: attempts,
              lastError: response.message ?? 'Échec du batch',
            );
          }
          kept += batch.length;
          state.value = state.value.copyWith(
            lastError: response.message ?? 'Échec du batch',
          );
          break;
        }

        final results = {
          for (final r in response.data!.results) r.clientRequestId: r,
        };

        for (final entry in batch) {
          final result = results[entry.clientRequestId];
          if (result == null) {
            // Pas de réponse pour cet item : on garde pour un retry.
            await OfflineDatabase.updateWriteStatus(
              entry.clientRequestId,
              localStatus: SyncLocalStatus.pending,
            );
            kept++;
            continue;
          }

          if (result.isCreated || result.isDuplicate) {
            await OfflineDatabase.removeWrite(entry.clientRequestId);
            if (result.isCreated) {
              created++;
              await OfflineDatabase.applyServerSolde(
                result.walletAgentId,
                result.nouveauSoldeWallet,
              );
            } else {
              duplicates++;
            }
            continue;
          }

          if (result.isRejected) {
            // Rejet métier définitif : on retire et on journalise.
            await OfflineDatabase.removeWrite(entry.clientRequestId);
            await OfflineDatabase.addJournalEntry({
              'at': DateTime.now().toUtc().toIso8601String(),
              'kind': 'rejected',
              'clientRequestId': entry.clientRequestId,
              'type': entry.kind.wire,
              'errorCode': result.errorCode,
              'message': result.message,
            });
            rejected++;
            continue;
          }

          // status = error : on conserve en file pour un retry ultérieur.
          await OfflineDatabase.updateWriteStatus(
            entry.clientRequestId,
            localStatus: SyncLocalStatus.pending,
            lastError: result.message ?? result.errorCode,
          );
          kept++;
        }
      }

      await OfflineDatabase.clearSyncError();
      state.value = state.value.copyWith(lastError: null);
      // Une fois les écritures intégrées, on réaligne les soldes.
      if (created > 0) {
        await syncAll();
      }
    } finally {
      state.value = state.value.copyWith(isFlushing: false);
      _refreshPendingCount();
    }

    return SyncFlushReport(
      created: created,
      duplicates: duplicates,
      rejected: rejected,
      kept: kept,
    );
  }

  /// VIDE la file (usage DEBUG / correction manuelle).
  Future<void> clearQueue() async {
    await OfflineDatabase.clearSyncData();
    _refreshPendingCount();
  }

  /// Identifiant de l'agent connecté (base du contrôle `AGENT_ID_INTERDIT`).
  int? get currentAgentId {
    final id = AuthService.superviseurId;
    return (id != null && id > 0) ? id : null;
  }

  /// Génère un UUID stable (exposé pour les rejeux explicites).
  static String newRequestId() => _uuid.v4();
}

/// Résumé d'un rejeu de file, pour l'UI.
class SyncFlushReport {
  final int created;
  final int duplicates;
  final int rejected;
  final int kept;

  const SyncFlushReport({
    required this.created,
    required this.duplicates,
    required this.rejected,
    required this.kept,
  });

  const SyncFlushReport.empty()
    : created = 0,
      duplicates = 0,
      rejected = 0,
      kept = 0;

  bool get isEmpty =>
      created == 0 && duplicates == 0 && rejected == 0 && kept == 0;

  int get confirmed => created + duplicates;

  String get message {
    if (isEmpty) return 'Aucune écriture à synchroniser.';
    final parts = <String>[];
    if (created > 0) parts.add('$created créée(s)');
    if (duplicates > 0) parts.add('$duplicates déjà traitées');
    if (rejected > 0) parts.add('$rejected rejetée(s)');
    if (kept > 0) parts.add('$kept en attente');
    return parts.join(' · ');
  }
}

/// Utilitaire : backoff exponentiel plafonné (utile aux retries manuels).
int syncBackoffDelayMs(int attempt) {
  final capped = min(attempt, _maxAttemptsStatic);
  return 1000 * (1 << capped);
}

const int _maxAttemptsStatic = 6;

/// debugPrint sûr (le package foundation est déjà importé).
void syncLog(String message) => debugPrint('[SYNC] $message');

/// UUID v4 minimal (RFC 4122) sans dépendance externe.
class Uuid {
  Uuid._();

  final Random _random = Random.secure();

  String v4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant RFC 4122

    String hex(int start, int end) => bytes
        .sublist(start, end)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }
}
