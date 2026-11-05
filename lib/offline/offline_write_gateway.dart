import '../config/api.dart';
import '../models/adhesion_with_affilie_model.dart';
import '../models/souscription_prestation_model.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../utils/api_error_helper.dart';
import 'offline_database.dart';
import 'offline_wallet_check.dart';

/// Résultat d'une écriture passée par la passerelle offline.
sealed class OfflineWriteOutcome {}

/// Écriture envoyée et confirmée par le serveur.
class OfflineSynced extends OfflineWriteOutcome {
  final Map<String, dynamic>? data;
  OfflineSynced(this.data);
}

/// Écriture mise en file locale (hors ligne) — sera rejouée plus tard.
class OfflineQueued extends OfflineWriteOutcome {
  final String clientRequestId;
  final String label;
  OfflineQueued({required this.clientRequestId, required this.label});
}

/// Écriture refusée (erreur métier ou réseau non récupérable).
class OfflineFailed extends OfflineWriteOutcome {
  final String message;
  final int? statusCode;
  final ApiResponse<Object?> response;

  OfflineFailed({
    required this.message,
    required this.statusCode,
    required this.response,
  });
}

/// Passerelle d'écriture « online d'abord, file offline en secours ».
///
/// Règles (voir `Prosoc_FRONTEND_INTEGRATION_OFFLINE_SYNC.md`) :
/// - seul le mode `VIRTUAL_ACCOUNT` peut être mis en file (jamais FlexPay,
///   Mobile Money ni carte bancaire) ;
/// - hors ligne détecté avant l'appel → file directe ;
/// - échec réseau après l'appel → file de secours (l'écriture n'a pas abouti) ;
/// - erreur métier renvoyée par le serveur → jamais de file.
abstract final class OfflineWriteGateway {
  /// Une collecte affilié (frais / cotisation / souscription).
  static Future<OfflineWriteOutcome> collecte({
    required String typeCollecte,
    required int affilieId,
    required int agentId,
    required double montant,
    required int deviseId,
    required int mois,
    required int annee,
    required String modePaiement,
    required String statutPaiement,
    required String referencePaiement,
    required double montantRecu,
    required double montantAttendu,
    int fraisId = 0,
    int? cotisationAffilieId,
    int? souscriptionPrestationId,
    String observation = '',
    String? phone,
    String? label,
  }) {
    return _run(
      canQueue: modePaiement.toUpperCase() == 'VIRTUAL_ACCOUNT',
      controleAvantFile: () => OfflineWalletCheck.verifier(
        agentId: agentId,
        debits: {deviseId: montant},
      ),
      queue: (sync) async {
        final entry = await sync.enqueueCollecte(
          typeCollecte: typeCollecte,
          fraisId: fraisId,
          affilieId: affilieId,
          agentId: agentId,
          montant: montant,
          deviseId: deviseId,
          mois: mois,
          annee: annee,
          cotisationAffilieId: cotisationAffilieId,
          souscriptionPrestationId: souscriptionPrestationId,
          label: label,
        );
        return entry.clientRequestId;
      },
      online: () => ApiService.createCollecte(
        typeCollecte: typeCollecte,
        affilieId: affilieId,
        agentId: agentId,
        fraisId: fraisId,
        cotisationAffilieId: cotisationAffilieId,
        souscriptionPrestationId: souscriptionPrestationId,
        montant: montant,
        mois: mois,
        annee: annee,
        referencePaiement: referencePaiement,
        modePaiement: modePaiement,
        statutPaiement: statutPaiement,
        montantRecu: montantRecu,
        montantAttendu: montantAttendu,
        deviseId: deviseId,
        observation: observation,
        phone: phone,
      ),
      label: label,
    );
  }

  /// Une adhésion complète (affilié + collectes, toutes en VIRTUAL_ACCOUNT).
  ///
  /// [adhesion] est le corps `AdhesionWithAffilieCreateDto` ; il est stocké
  /// tel quel dans la file et renvoyé au batch.
  static Future<OfflineWriteOutcome> adhesion({
    required Map<String, dynamic> adhesion,
    required AdhesionWithAffilieRequest request,
    String? label,
  }) {
    return _run(
      canQueue: true,
      controleAvantFile: () {
        final agentId = request.agentId ?? 0;
        return OfflineWalletCheck.verifier(
          agentId: agentId,
          debits: OfflineDatabase.debitsDePayload({
            'adhesion': adhesion,
          }, agentId: agentId),
        );
      },
      queue: (sync) async {
        final entry = await sync.enqueueAdhesion(
          adhesion: adhesion,
          label: label,
        );
        return entry.clientRequestId;
      },
      online: () => ApiService.createAdhesionWithAffilieV2(request),
      label: label,
    );
  }

  /// Achat d'une nouvelle souscription de prestation au compte virtuel.
  /// En file, le serveur contrôlera éligibilité, doublon et montant au batch.
  static Future<OfflineWriteOutcome> souscriptionPrestation({
    required int affilieId,
    required int agentId,
    required int prestationId,
    required double montant,
    required int deviseId,
    required int mois,
    required int annee,
    required String referencePaiement,
    required SouscriptionPrestationCreateRequest request,
    String? label,
  }) {
    return _run(
      canQueue: true,
      controleAvantFile: () {
        if (OfflineDatabase.achatPrestationExistant(
          affilieId: affilieId,
          prestationId: prestationId,
        )) {
          return 'Cet affilié a déjà souscrit à cette prestation, ou un achat '
              'identique attend la synchronisation.';
        }
        return OfflineWalletCheck.verifier(
          agentId: agentId,
          debits: {deviseId: montant},
        );
      },
      queue: (sync) async {
        final entry = await sync.enqueueSouscriptionPrestation(
          affilieId: affilieId,
          agentId: agentId,
          prestationId: prestationId,
          montant: montant,
          deviseId: deviseId,
          mois: mois,
          annee: annee,
          referencePaiement: referencePaiement,
          label: label,
        );
        return entry.clientRequestId;
      },
      online: () => ApiService.createSouscriptionPrestation(
        affilieId: affilieId,
        request: request,
      ),
      label: label,
    );
  }

  static Future<OfflineWriteOutcome> _run({
    required bool canQueue,
    required Future<String> Function(SyncService sync) queue,
    required Future<ApiResponse<dynamic>> Function() online,
    String? Function()? controleAvantFile,
    String? label,
  }) async {
    final sync = SyncService.instance;
    final resolvedLabel = (label != null && label.trim().isNotEmpty)
        ? label.trim()
        : 'Écriture offline';

    // Sans WRITE_SYNC, une écriture en file ne partirait jamais : mieux vaut un
    // échec réseau visible (ex. Percepteur).
    final peutEnvoyerFile =
        AuthService.currentUser?.hasPermission('WRITE_SYNC') ?? false;

    // 1) Hors ligne connu avant l'appel → file directe.
    if (!canQueue || !peutEnvoyerFile) {
      return _attempt(online, sync, resolvedLabel);
    }
    // Toute mise en file (hors ligne connu OU repli après échec réseau)
    // passe d'abord par le contrôle local du compte virtuel.
    Future<OfflineWriteOutcome> mettreEnFile() async {
      final blocage = controleAvantFile?.call();
      if (blocage != null) {
        return OfflineFailed(
          message: blocage,
          statusCode: 400,
          response: ApiResponse.error(blocage, statusCode: 400),
        );
      }
      final id = await queue(sync);
      return OfflineQueued(clientRequestId: id, label: resolvedLabel);
    }

    if (!sync.isOnline) return mettreEnFile();

    // 2) En ligne : on tente l'appel ; en cas d'échec réseau on met en file.
    return _attempt(online, sync, resolvedLabel, queue: mettreEnFile);
  }

  static Future<OfflineWriteOutcome> _attempt(
    Future<ApiResponse<dynamic>> Function() online,
    SyncService sync,
    String label, {
    Future<OfflineWriteOutcome> Function()? queue,
  }) async {
    ApiResponse<dynamic> response;
    try {
      response = await online();
    } catch (e) {
      if (queue != null && ApiErrorHelper.isRetryableNetworkError(e)) {
        return queue();
      }
      return OfflineFailed(
        message: ApiErrorHelper.userFacingNetwork(),
        statusCode: null,
        response: ApiResponse.error(ApiErrorHelper.userFacingNetwork()),
      );
    }

    if (response.success) {
      return OfflineSynced(
        response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : null,
      );
    }

    final retryable =
        response.statusCode == null ||
        ApiErrorHelper.isRetryableStatusCode(response.statusCode) ||
        ApiErrorHelper.isRetryableNetworkError(response.message ?? '');
    if (queue != null && retryable) {
      return queue();
    }

    return OfflineFailed(
      message: response.message ?? 'Opération impossible pour le moment.',
      statusCode: response.statusCode,
      response: response,
    );
  }
}
