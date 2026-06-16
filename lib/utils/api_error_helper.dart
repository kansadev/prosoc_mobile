import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/wallet_agent_model.dart';

/// Messages utilisateur sûrs et journalisation technique (debug uniquement).
class ApiErrorHelper {
  ApiErrorHelper._();

  static String userFacingMessage({int? statusCode, String? fallback}) {
    if (statusCode != null) {
      switch (statusCode) {
        case 400:
          return 'Données invalides. Vérifiez le formulaire.';
        case 401:
          return 'Session expirée. Veuillez vous reconnecter.';
        case 403:
          return 'Action non autorisée.';
        case 404:
          return 'Ressource introuvable.';
        case 409:
          return 'Cette opération existe déjà.';
        case 429:
          return 'Trop de requêtes. Veuillez patienter.';
        case >= 500:
          return 'Service temporairement indisponible. Réessayez plus tard.';
      }
    }
    return fallback ?? 'Une erreur est survenue. Veuillez réessayer.';
  }

  /// Messages techniques serveur à ne jamais afficher tels quels à l'utilisateur.
  static bool isOpaqueServerDetail(String? detail) {
    if (detail == null || detail.trim().isEmpty) return true;
    final d = detail.trim().toLowerCase();
    return d.contains('erreur interne') ||
        d.contains('internal server error') ||
        d.contains('erreur serveur') ||
        d == 'an error occurred' ||
        d.startsWith('exception');
  }

  /// Titres RFC 7807 / ASP.NET génériques à ne pas afficher tels quels.
  static bool isGenericHttpProblemTitle(String? detail) {
    if (detail == null || detail.trim().isEmpty) return false;
    const generic = {
      'not found',
      'bad request',
      'unauthorized',
      'forbidden',
      'internal server error',
      'conflict',
      'unprocessable entity',
      'method not allowed',
    };
    return generic.contains(detail.trim().toLowerCase());
  }

  /// Message affiché à partir du détail API (masque les 500 génériques en prod).
  static String messageForApiFailure({
    int? statusCode,
    String? serverDetail,
    String? fallback,
  }) {
    if (serverDetail != null &&
        serverDetail.trim().isNotEmpty &&
        !isOpaqueServerDetail(serverDetail) &&
        !isGenericHttpProblemTitle(serverDetail) &&
        !serverDetail.startsWith('Erreur serveur (')) {
      return serverDetail.trim();
    }
    if (statusCode != null && statusCode >= 500) {
      return userFacingMessage(statusCode: statusCode);
    }
    return userFacingMessage(statusCode: statusCode, fallback: fallback);
  }

  /// Message utilisateur pour une réponse API (404 wallet agent, etc.).
  static String messageFromApiResponse({
    int? statusCode,
    String? serverMessage,
    String? notFoundMessage,
    String? fallback,
  }) {
    if (statusCode == 404) {
      if (serverMessage != null &&
          serverMessage.trim().isNotEmpty &&
          !isGenericHttpProblemTitle(serverMessage) &&
          !isOpaqueServerDetail(serverMessage)) {
        return serverMessage.trim();
      }
      return notFoundMessage ??
          'Ressource introuvable pour votre compte.';
    }
    return messageForApiFailure(
      statusCode: statusCode,
      serverDetail: serverMessage,
      fallback: fallback,
    );
  }

  /// Message affiché lorsqu'aucun wallet agent n'existe pour une devise.
  static String walletAgentUnavailableMessage({int? deviseId}) {
    if (deviseId != null) {
      final label = WalletAgentDeviseIds.labelForId(deviseId);
      return 'Wallet $label indisponible. Contactez votre superviseur.';
    }
    return 'Wallet indisponible. Contactez votre superviseur.';
  }

  static String messageForWalletAgentError({
    int? statusCode,
    String? serverMessage,
    int? deviseId,
  }) {
    return messageFromApiResponse(
      statusCode: statusCode,
      serverMessage: serverMessage,
      notFoundMessage: walletAgentUnavailableMessage(deviseId: deviseId),
      fallback: 'Impossible de charger votre wallet.',
    );
  }

  static String messageForWalletVirtuelError({
    int? statusCode,
    String? serverMessage,
  }) {
    return messageFromApiResponse(
      statusCode: statusCode,
      serverMessage: serverMessage,
      notFoundMessage:
          'Aucun compte virtuel n\'est encore configuré pour votre profil agent.',
      fallback: 'Impossible de charger votre compte virtuel.',
    );
  }

  static String messageForWalletMouvementsError({
    int? statusCode,
    String? serverMessage,
  }) {
    return messageFromApiResponse(
      statusCode: statusCode,
      serverMessage: serverMessage,
      notFoundMessage: 'Aucun mouvement disponible pour le moment.',
      fallback: 'Impossible de charger les mouvements.',
    );
  }

  /// Extrait les messages métier d'une réponse JSON d'erreur API.
  static String? validationMessageFromBody(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map) return null;
      return _validationMessageFromMap(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  static String? _validationMessageFromMap(Map<String, dynamic> data) {
    final nested = data['error'] ?? data['Error'];
    if (nested is Map) {
      final fromNested = _issuesFromErrorMap(Map<String, dynamic>.from(nested));
      if (fromNested != null) return fromNested;
    }
    final details = data['details'] ?? data['Details'];
    if (details is List) {
      return _issuesFromDetailsList(details);
    }
    return null;
  }

  static String? _issuesFromErrorMap(Map<String, dynamic> error) {
    final fromDetails = _issuesFromDetailsList(error['details'] ?? error['Details']);
    if (fromDetails != null) return fromDetails;

    final message = error['message'] ?? error['Message'];
    if (message is String &&
        message.trim().isNotEmpty &&
        !isOpaqueServerDetail(message)) {
      return message.trim();
    }
    return null;
  }

  static String? _issuesFromDetailsList(dynamic details) {
    if (details is! List || details.isEmpty) return null;
    final parts = <String>[];
    for (final item in details) {
      if (item is Map) {
        final issue = item['issue'] ?? item['Issue'];
        if (issue is String && issue.trim().isNotEmpty) {
          parts.add(issue.trim());
        }
      }
    }
    if (parts.isEmpty) return null;
    return parts.join('\n\n');
  }

  /// Historique paiements indisponible (500 côté API).
  static String historiquePaiementsUnavailable({int? statusCode}) {
    if (statusCode != null && statusCode >= 500) {
      return 'L\'historique des paiements est momentanément indisponible. '
          'Consultez les onglets Récentes, Période et Retards. '
          'Réessayez dans quelques instants.';
    }
    return messageForApiFailure(
      statusCode: statusCode,
      fallback: 'Impossible de charger l\'historique des paiements.',
    );
  }

  static bool isRetryableStatusCode(int? statusCode) {
    return statusCode == 500 || statusCode == 502 || statusCode == 503;
  }

  static String userFacingNetwork() =>
      'Impossible de contacter le serveur. Vérifiez votre connexion.';

  /// Erreurs réseau souvent transitoires (serveur saturé, reset TCP, etc.).
  static bool isRetryableNetworkError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('connection reset') ||
        message.contains('connection refused') ||
        message.contains('connection timed out') ||
        message.contains('network is unreachable') ||
        message.contains('failed host lookup') ||
        message.contains('socketexception') ||
        message.contains('clientexception') ||
        message.contains('handshake exception');
  }

  static String networkErrorSummary(Object error) {
    final text = error.toString();
    if (text.contains('Connection reset by peer')) {
      return 'Connexion interrompue par le serveur';
    }
    if (text.contains('Failed host lookup')) {
      return 'Serveur introuvable (DNS)';
    }
    if (text.contains('Connection timed out')) {
      return 'Délai de connexion dépassé';
    }
    return 'Erreur réseau';
  }

  /// Journalise une requête API avant envoi (debug uniquement).
  static void logRequest(
    String context,
    Map<String, dynamic> payload, {
    String method = 'POST',
    String? endpoint,
  }) {
    if (!kDebugMode) return;
    final buffer = StringBuffer('[API] $method $context');
    if (endpoint != null && endpoint.isNotEmpty) {
      buffer.write(' → $endpoint');
    }
    buffer.write('\n  request: ${_formatJson(payload)}');
    debugPrint(buffer.toString());
  }

  /// Journalise une réponse HTTP réussie (debug uniquement).
  static void logHttpSuccess(
    String context, {
    required int statusCode,
    required String body,
    String? endpoint,
  }) {
    if (!kDebugMode) return;
    final buffer = StringBuffer('[API] $context ($statusCode)');
    if (endpoint != null && endpoint.isNotEmpty) {
      buffer.write(' ← $endpoint');
    }
    buffer.write('\n  response: ${_formatResponseBody(body)}');
    debugPrint(buffer.toString());
  }

  static void logHttpFailure(
    String context, {
    int? statusCode,
    String? detail,
    String? body,
    Map<String, dynamic>? request,
  }) {
    if (!kDebugMode) return;
    final buffer = StringBuffer('[API] $context');
    if (statusCode != null) buffer.write(' ($statusCode)');
    if (request != null && request.isNotEmpty) {
      buffer.write('\n  request: ${_formatJson(request)}');
    }
    if (detail != null && detail.isNotEmpty) {
      buffer.write('\n  detail: $detail');
    }
    if (body != null && body.isNotEmpty) {
      final isServerError = statusCode != null && statusCode >= 500;
      final differsFromDetail = detail == null || body.trim() != detail.trim();
      if (isServerError || differsFromDetail) {
        buffer.write('\n  response: ${_truncate(body, 2000)}');
      }
    }
    debugPrint(buffer.toString());
  }

  static String _formatJson(Map<String, dynamic> payload) {
    try {
      return const JsonEncoder.withIndent('  ').convert(payload);
    } catch (_) {
      return payload.toString();
    }
  }

  static String _formatResponseBody(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return '(vide)';
    try {
      final decoded = jsonDecode(trimmed);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return _truncate(trimmed, 4000);
    }
  }

  static String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength)}...';
  }

  static void logException(
    String context,
    Object error, [
    StackTrace? stackTrace,
    bool logFullStack = true,
  ]) {
    if (!kDebugMode) return;
    if (isRetryableNetworkError(error) && !logFullStack) {
      debugPrint('[API] $context — ${networkErrorSummary(error)}');
      return;
    }
    debugPrint('[API] $context — $error');
    if (logFullStack && stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}
