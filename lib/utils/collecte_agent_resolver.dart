import '../config/api.dart';
import '../services/auth_service.dart';
import 'paginated_response_helper.dart';

/// Résout l'`agentId` requis pour une collecte (AT connecté ou affilié).
class CollecteAgentResolver {
  CollecteAgentResolver._();

  static int? _positiveInt(dynamic value) {
    if (value is int) return value > 0 ? value : null;
    if (value is num) {
      final parsed = value.toInt();
      return parsed > 0 ? parsed : null;
    }
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      return parsed != null && parsed > 0 ? parsed : null;
    }
    return null;
  }

  /// Extrait un `agentId` depuis une réponse API (affilié, adhésion, etc.).
  static int? extractAgentId(Map<String, dynamic> data) {
    for (final key in const [
      'agentId',
      'idAgent',
      'AgentId',
      'IdAgent',
      'agentTerritorialId',
      'idAgentGestionnaireCompte',
    ]) {
      final parsed = _positiveInt(data[key]);
      if (parsed != null) return parsed;
    }

    final adhesion = data['adhesion'];
    if (adhesion is Map) {
      final parsed = extractAgentId(Map<String, dynamic>.from(adhesion));
      if (parsed != null) return parsed;
    }

    final adhesions = data['adhesions'];
    if (adhesions is List) {
      for (final item in adhesions) {
        if (item is! Map) continue;
        final parsed = extractAgentId(Map<String, dynamic>.from(item));
        if (parsed != null) return parsed;
      }
    }

    return null;
  }

  /// Priorité : paramètre explicite → session (AT ou agent gestionnaire affilié)
  /// → fiche affilié → dernière collecte.
  static Future<int?> resolveForAffilie(
    int affilieId, {
    int? explicitAgentId,
  }) async {
    final fromExplicit = _positiveInt(explicitAgentId);
    if (fromExplicit != null) return fromExplicit;

    final fromAuth = _positiveInt(AuthService.collecteAgentId);
    if (fromAuth != null) return fromAuth;

    try {
      final affilieResponse = await ApiService.getAffilie(affilieId);
      if (affilieResponse.success && affilieResponse.data != null) {
        final fromAffilie = extractAgentId(affilieResponse.data!);
        if (fromAffilie != null) return fromAffilie;
      }
    } catch (_) {}

    try {
      final collectesResponse = await ApiService.getCollecteByAffiliePaginated(
        affilieId: affilieId,
        page: 1,
        pageSize: 5,
        sortBy: 'dateCollecte',
        sortDirection: 'desc',
      );
      if (collectesResponse.success && collectesResponse.data != null) {
        final rows = PaginatedResponseHelper.extractRows(collectesResponse.data!);
        for (final row in rows) {
          if (row is! Map) continue;
          final parsed = _positiveInt(row['agentId']);
          if (parsed != null) return parsed;
        }
      }
    } catch (_) {}

    return null;
  }
}
