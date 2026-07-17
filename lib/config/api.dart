import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/api_error_helper.dart';
import '../utils/paginated_response_helper.dart';
import '../models/auth_user_model.dart';
import '../models/wallet_agent_model.dart';
import '../models/wallet_mouvement_model.dart';
import '../models/wallet_virtuel_agent_model.dart';
import '../models/wallet_virtuel_mouvement_model.dart';
import '../models/affilie_model.dart';
import '../models/adhesion_with_affilie_model.dart';
import '../models/dashboard_agent_model.dart';
import '../models/dashboard_agent_graphs_model.dart';
import '../models/dashboard_superviseur_model.dart';
import '../models/dashboard_percepteur_model.dart';
import '../models/chef_equipe_model.dart';
import '../models/dashboard_affilie_model.dart';
import '../models/frais_model.dart';
import '../models/recent_affilie_model.dart';
import '../models/souscription_prestation_model.dart';
import '../models/affilie_paiement_historique_model.dart';
import '../models/demande_bon_envoi_model.dart';
import '../models/bon_envoi_model.dart';
import '../models/jeton_medical_model.dart';
import '../models/kpi_agent_model.dart';
import '../models/agent_model.dart';
import '../models/devise_model.dart';
import '../models/perception_virtuelle_model.dart';
import '../models/retrait_agent_model.dart';
import '../models/retrait_agent_periode_model.dart';
import '../models/retrait_agent_verifier_solde_model.dart';
import '../models/arriere_affilie_model.dart';
import '../models/penalite_affilie_model.dart';
import '../models/adhesion_en_ligne_model.dart';
import '../models/agent_affecter_affilies_model.dart';
import 'app_environment.dart';

// ============================================
// CONFIGURATION API PROSOC
// ============================================

class ApiConfig {
  /// URL de base selon l'environnement (`APP_ENV=dev` ou `uat`).
  static String get baseUrl => AppEnvironmentConfig.baseUrl;

  static AppEnvironment get environment => AppEnvironmentConfig.current;

  // Headers par défaut
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Headers avec authentification
  static Map<String, String> authHeaders(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };
}

// ============================================
// MODÈLES DE RÉPONSE
// ============================================

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });

  factory ApiResponse.success(T data, {int? statusCode}) {
    return ApiResponse(
      success: true,
      data: data,
      statusCode: statusCode ?? 200,
    );
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }
}

class RefreshTokenResult {
  final bool success;
  final String message;
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final DateTime expiresAt;

  RefreshTokenResult({
    required this.success,
    required this.message,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.expiresAt,
  });

  factory RefreshTokenResult.fromJson(Map<String, dynamic> json) {
    final expiresRaw = json['expiresAt'] ?? json['expiresAtUtc'];
    return RefreshTokenResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      tokenType: json['tokenType'] ?? 'Bearer',
      expiresIn: json['expiresIn'] ?? 0,
      expiresAt: DateTime.parse(
        expiresRaw?.toString() ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

typedef SessionRefreshCallback = Future<bool> Function();

// ============================================
// SERVICE API PRINCIPAL
// ============================================

class ApiService {
  static String? _token;
  static SessionRefreshCallback? onSessionRefresh;
  static Future<bool>? _sessionRefreshFuture;
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal();

  // Getter et setter pour le token
  static String? get token => _token;
  static set token(String? value) => _token = value;

  // Vérifier si l'utilisateur est connecté
  static bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  // ============================================
  // AUTHENTIFICATION
  // ============================================

  /// POST /api/auth/login
  /// Connexion utilisateur et obtention du token JWT
  /// Retourne AuthUserModel avec toutes les informations de l'utilisateur et ses rôles
  static Future<ApiResponse<AuthUserModel>> login({
    required String nomUtilisateur,
    required String motDePasse,
    String? fcmToken,
    String deviceType = 'Mobile',
    String deviceModel = '',
    String osVersion = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Utilisateur/login'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'emailOuTelephone': nomUtilisateur,
          'motDePasse': motDePasse,
          'fcmToken': fcmToken ?? 'string',
          'deviceType': deviceType,
          'deviceModel': deviceModel,
          'osVersion': osVersion,
          'deviceInfo': 'Mobile',
        }),
      );
      if (kDebugMode) {
        debugPrint('Login response status: ${response.statusCode}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final authUser = AuthUserModel.fromJson(data);

        // Vérifier si le rôle est autorisé
        if (!authUser.isRoleAutorise) {
          return ApiResponse.error(
            'Accès refusé: Votre rôle "${authUser.nomRole}" n\'est pas autorisé à accéder à cette application.\nRôles autorisés: Agent (AT), Adhérent, Affilié, Percepteur, Superviseur, Chef d\'équipe.',
            statusCode: 403,
          );
        }

        _token = authUser.accessToken;
        return ApiResponse.success(authUser, statusCode: response.statusCode);
      } else if (response.statusCode == 401) {
        return ApiResponse.error(
          'Nom d\'utilisateur ou mot de passe incorrect',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 403) {
        ApiErrorHelper.logHttpFailure(
          'login',
          statusCode: 403,
          body: kDebugMode ? response.body : null,
        );
        return ApiResponse.error(
          'Accès refusé. Votre compte n\'a pas accès à cette application.',
          statusCode: response.statusCode,
        );
      } else {
        return _errorResponse<AuthUserModel>(response, context: 'login');
      }
    } catch (e) {
      return _errorFromException(e, StackTrace.current, 'login');
    }
  }

  /// POST /api/Utilisateur/logout
  /// Déconnexion utilisateur
  static Future<void> logout({
    int? idUtilisateur,
    String? refreshToken,
  }) async {
    if (_token == null || _token!.isEmpty) {
      return;
    }

    final body = <String, dynamic>{};
    if (idUtilisateur != null) {
      body['idUtilisateur'] = idUtilisateur;
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      body['refreshToken'] = refreshToken;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Utilisateur/logout'),
        headers: ApiConfig.authHeaders(_token!),
        body: jsonEncode(body.isNotEmpty ? body : {}),
      );

      if (kDebugMode) {
        debugPrint('Logout response: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Logout error: $e');
      }
    } finally {
      _token = null;
    }
  }

  /// POST /api/Utilisateur/refresh-token — renouvelle l'access token.
  static Future<ApiResponse<RefreshTokenResult>> refreshAccessToken(
    String refreshToken, {
    String grantType = 'refresh_token',
    String deviceInfo = 'Mobile',
  }) async {
    try {
      final body = {
        'refreshToken': refreshToken,
        'grantType': grantType,
        'deviceInfo': deviceInfo,
      };

      if (kDebugMode) {
        debugPrint('[API] POST /api/Utilisateur/refresh-token');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Utilisateur/refresh-token'),
        headers: ApiConfig.headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = RefreshTokenResult.fromJson(data);
        if (!result.success || result.accessToken.isEmpty) {
          return ApiResponse.error(
            result.message.isNotEmpty
                ? result.message
                : 'Réponse refresh invalide',
            statusCode: response.statusCode,
          );
        }
        _token = result.accessToken;
        return ApiResponse.success(result, statusCode: response.statusCode);
      }

      return _errorResponse<RefreshTokenResult>(
        response,
        context: 'POST /api/Utilisateur/refresh-token',
        requestBody: body,
      );
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, 'refresh-token');
    }
  }

  static Future<bool> _tryRefreshSession() async {
    final refresh = onSessionRefresh;
    if (refresh == null) return false;

    _sessionRefreshFuture ??= refresh().whenComplete(() {
      _sessionRefreshFuture = null;
    });
    return _sessionRefreshFuture!;
  }

  static Future<http.Response> _withAuthRetry(
    Future<http.Response> Function() send,
  ) async {
    var response = await send();
    if (response.statusCode == 401 && onSessionRefresh != null) {
      final refreshed = await _tryRefreshSession();
      if (refreshed) {
        response = await send();
      }
    }
    return response;
  }

  // ============================================
  // AGENTS
  // ============================================

  /// GET /api/agent - Liste de tous les agents
  static Future<ApiResponse<List<dynamic>>> getAgents() async {
    return _get<List<dynamic>>('/api/agent');
  }

  /// GET /api/Agent — Liste paginée des agents (recherche percepteur)
  static Future<ApiResponse<Map<String, dynamic>>> searchAgents({
    int page = 1,
    int pageSize = 15,
    String? search,
    String? sortBy,
    String? sortDirection,
    String? filters,
  }) async {
    final queryParams = <String, String>{
      'Page': page.toString(),
      'PageSize': pageSize.toString(),
      if (sortBy != null && sortBy.isNotEmpty) 'SortBy': sortBy,
      if (sortDirection != null && sortDirection.isNotEmpty)
        'SortDirection': sortDirection,
      if (search != null && search.isNotEmpty) 'Search': search,
      if (filters != null && filters.isNotEmpty) 'Filters': filters,
    };

    return _get<Map<String, dynamic>>('/api/Agent', queryParams: queryParams);
  }

  /// GET /api/Agent/{id} — Détails agent
  static Future<ApiResponse<Map<String, dynamic>>> getAgent(int id) async {
    return _get<Map<String, dynamic>>('/api/Agent/$id');
  }

  /// GET /api/Agent/{id} — Détails agent typés (profil + wallets)
  static Future<ApiResponse<AgentModel>> getAgentDetail(int id) async {
    final response = await getAgent(id);
    if (!response.success || response.data == null) {
      return ApiResponse.error(
        response.message ?? 'Impossible de charger les détails de l\'agent',
        statusCode: response.statusCode,
      );
    }
    return ApiResponse.success(
      AgentModel.fromJson(response.data!),
      statusCode: response.statusCode,
    );
  }

  /// GET /api/Agent/{agentId}/affilies - Affiliés d'un agent (paginé)
  static Future<ApiResponse<Map<String, dynamic>>> getAffiliesByAgent(
    int agentId, {
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    String? sortDirection,
    String? search,
    String? filters,
  }) async {
    final queryParams = <String, String>{
      // Swagger (PascalCase) + compat (camelCase)
      'Page': page.toString(),
      'pageNumber': page.toString(),
      'PageSize': pageSize.toString(),
      'pageSize': pageSize.toString(),
      if (sortBy != null && sortBy.isNotEmpty) 'SortBy': sortBy,
      if (sortDirection != null && sortDirection.isNotEmpty)
        'SortDirection': sortDirection,
      if (search != null && search.isNotEmpty) 'Search': search,
      if (filters != null && filters.isNotEmpty) 'Filters': filters,
    };

    final queryString = Uri(queryParameters: queryParams).query;
    return _get<Map<String, dynamic>>(
      '/api/Agent/$agentId/affilies?$queryString',
    );
  }

  /// GET /api/WalletAgent/by-agent/{agentId}?deviseId= — Wallet agent pour une devise
  static Future<ApiResponse<WalletAgentModel>> getWalletAgentByAgentAndDevise(
    int agentId, {
    required int deviseId,
  }) async {
    final context = 'WalletAgent/by-agent/$agentId?deviseId=$deviseId';
    try {
      final response = await _httpGet(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/WalletAgent/by-agent/$agentId?deviseId=$deviseId',
        ),
        context: context,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final map = _unwrapWalletAgentMap(decoded);
        if (map == null) {
          return ApiResponse.error(
            'Réponse wallet invalide',
            statusCode: response.statusCode,
          );
        }
        return ApiResponse.success(WalletAgentModel.fromJson(map));
      }
      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  static Map<String, dynamic>? _unwrapWalletAgentMap(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) return null;
    if (decoded.containsKey('idWalletAgent')) return decoded;
    final nested = decoded['data'] ?? decoded['Data'];
    if (nested is Map<String, dynamic>) return nested;
    return decoded;
  }

  /// GET /api/WalletAgent - Wallet Agent par agent ID (paginé)
  static Future<ApiResponse<WalletAgentPaginatedResponse>>
  getWalletAgentByAgent(int agentId, {int page = 1, int pageSize = 20}) async {
    final context = 'WalletAgent/by-agent/$agentId/paginated';
    try {
      final response = await _httpGet(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/WalletAgent/by-agent/$agentId/paginated?pageNumber=$page&pageSize=$pageSize',
        ),
        context: context,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(WalletAgentPaginatedResponse.fromJson(data));
      } else {
        return _errorResponse(response, context: context);
      }
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/WalletAgent - Liste de tous les wallets agents (paginé)
  static Future<ApiResponse<WalletAgentPaginatedResponse>> getWalletAgents({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/WalletAgent?pageNumber=$page&pageSize=$pageSize',
        ),
        headers: ApiConfig.authHeaders(_token!),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(WalletAgentPaginatedResponse.fromJson(data));
      } else {
        return _errorResponse(response);
      }
    } catch (e) {
      return _errorFromException(e, StackTrace.current);
    }
  }

  /// GET /api/WalletVirtuelAgent/by-agent/{agentId} - Wallet virtuel d'un agent
  static Future<ApiResponse<WalletVirtuelAgentModel>> getWalletVirtuelAgent(
    int agentId,
  ) async {
    final context = 'WalletVirtuelAgent/by-agent/$agentId';
    try {
      final response = await _httpGet(
        Uri.parse('${ApiConfig.baseUrl}/api/WalletVirtuelAgent/by-agent/$agentId'),
        context: context,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final map = _unwrapWalletVirtuelAgentMap(decoded);
        if (map == null) {
          return ApiResponse.error(
            'Réponse compte virtuel invalide',
            statusCode: response.statusCode,
          );
        }
        return ApiResponse.success(WalletVirtuelAgentModel.fromJson(map));
      } else {
        return _errorResponse(response, context: context);
      }
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// PUT /api/WalletVirtuelAgent/{id}/ajouter-solde — Recharge compte virtuel agent
  static Future<ApiResponse<WalletVirtuelAjouterSoldeResult>>
      ajouterSoldeWalletVirtuelAgent(
    int idWalletVirtuelAgent, {
    required double montant,
    String? observation,
  }) async {
    final context = 'WalletVirtuelAgent/$idWalletVirtuelAgent/ajouter-solde';
    final body = <String, dynamic>{
      'montant': montant,
      'observation': observation?.trim() ?? '',
    };

    try {
      if (kDebugMode) {
        ApiErrorHelper.logRequest(context, body);
      }

      final response = await _withAuthRetry(
        () => http.put(
          Uri.parse(
            '${ApiConfig.baseUrl}/api/WalletVirtuelAgent/$idWalletVirtuelAgent/ajouter-solde',
          ),
          headers: isAuthenticated
              ? ApiConfig.authHeaders(_token!)
              : ApiConfig.headers,
          body: jsonEncode(body),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          final map = decoded is Map<String, dynamic>
              ? decoded
              : Map<String, dynamic>.from(decoded);
          return ApiResponse.success(
            WalletVirtuelAjouterSoldeResult.fromJson(map),
            statusCode: response.statusCode,
          );
        }
        return ApiResponse.error(
          'Réponse recharge compte virtuel invalide',
          statusCode: response.statusCode,
        );
      }

      return _errorResponse<WalletVirtuelAjouterSoldeResult>(
        response,
        context: context,
        requestBody: body,
      );
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  static Map<String, dynamic>? _unwrapWalletVirtuelAgentMap(dynamic decoded) {
    if (decoded is List && decoded.isNotEmpty) {
      final first = decoded.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
      return null;
    }

    if (decoded is! Map<String, dynamic>) {
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    }

    if (decoded.containsKey('idWalletVirtuelAgent') ||
        decoded.containsKey('IdWalletVirtuelAgent')) {
      return decoded;
    }

    final nested = decoded['data'] ?? decoded['Data'];
    if (nested is Map<String, dynamic>) return nested;
    if (nested is Map) return Map<String, dynamic>.from(nested);
    if (nested is List && nested.isNotEmpty) {
      final first = nested.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }

    return decoded;
  }

  /// GET /api/WalletVirtuelAgent/by-agent/{agentId}/mouvements/paginated
  static Future<ApiResponse<Map<String, dynamic>>>
      getWalletVirtuelMouvementsPaginated(
    int agentId, {
    int page = 1,
    int pageSize = 10,
    String? sortBy,
    String sortDirection = 'desc',
    String? search,
    String? filters,
  }) async {
    final queryParams = <String, String>{
      'Page': page.toString(),
      'PageSize': pageSize.toString(),
      'SortDirection': sortDirection,
    };
    if (sortBy != null && sortBy.isNotEmpty) {
      queryParams['SortBy'] = sortBy;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['Search'] = search;
    }
    if (filters != null && filters.isNotEmpty) {
      queryParams['Filters'] = filters;
    }

    return _get<Map<String, dynamic>>(
      '/api/WalletVirtuelAgent/by-agent/$agentId/mouvements/paginated',
      queryParams: queryParams,
    );
  }

  /// Parse la réponse paginée des mouvements wallet virtuel.
  static List<WalletVirtuelMouvementModel> parseWalletVirtuelMouvements(
    Map<String, dynamic>? payload,
  ) {
    if (payload == null) return [];
    return PaginatedResponseHelper.extractRows(payload)
        .whereType<Map>()
        .map(
          (item) => WalletVirtuelMouvementModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  // ============================================
  // PERCEPTION VIRTUELLE (encaissement cash agent)
  // ============================================

  /// GET /api/PerceptionVirtuelle/collectes-en-attente
  static Future<ApiResponse<Map<String, dynamic>>>
      getPerceptionVirtuelleCollectesEnAttente({
    required int agentId,
    int page = 1,
    int pageSize = 20,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? search,
    String? sortBy,
    String? sortDirection,
    String? filters,
  }) async {
    final queryParams = <String, String>{
      'agentId': agentId.toString(),
      'Page': page.toString(),
      'pageNumber': page.toString(),
      'PageSize': pageSize.toString(),
      'pageSize': pageSize.toString(),
      if (dateDebut != null) 'dateDebut': dateDebut.toIso8601String(),
      if (dateFin != null) 'dateFin': dateFin.toIso8601String(),
      if (sortBy != null && sortBy.isNotEmpty) 'SortBy': sortBy,
      if (sortDirection != null && sortDirection.isNotEmpty)
        'SortDirection': sortDirection,
      if (search != null && search.isNotEmpty) 'Search': search,
      if (filters != null && filters.isNotEmpty) 'Filters': filters,
    };

    return _get<Map<String, dynamic>>(
      '/api/PerceptionVirtuelle/collectes-en-attente',
      queryParams: queryParams,
    );
  }

  static List<CollecteEnAttenteModel> parseCollectesEnAttente(
    Map<String, dynamic>? payload,
  ) {
    if (payload == null) return [];
    return PaginatedResponseHelper.extractRows(payload)
        .whereType<Map>()
        .map(
          (item) => CollecteEnAttenteModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  /// POST /api/PerceptionVirtuelle/confirmer
  static Future<ApiResponse<PerceptionVirtuelleConfirmResultModel>>
      confirmerPerceptionVirtuelle({
    required int agentId,
    required List<int> collecteIds,
    String? observation,
  }) async {
    const context = 'PerceptionVirtuelle/confirmer';
    final body = <String, dynamic>{
      'agentId': agentId,
      'collecteIds': collecteIds,
      'observation': observation ?? '',
    };

    try {
      if (kDebugMode) {
        ApiErrorHelper.logRequest(context, body, endpoint: '/api/PerceptionVirtuelle/confirmer');
      }

      final response = await _withAuthRetry(
        () => http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/PerceptionVirtuelle/confirmer'),
          headers: isAuthenticated
              ? ApiConfig.authHeaders(_token!)
              : ApiConfig.headers,
          body: jsonEncode(body),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          ApiErrorHelper.logHttpSuccess(
            context,
            statusCode: response.statusCode,
            body: response.body,
            endpoint: '/api/PerceptionVirtuelle/confirmer',
          );
        }

        final decoded = jsonDecode(response.body);
        final map = _unwrapPerceptionConfirmMap(decoded);
        if (map == null) {
          return ApiResponse.error(
            'Réponse de confirmation invalide',
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.success(
          PerceptionVirtuelleConfirmResultModel.fromJson(map),
          statusCode: response.statusCode,
        );
      }

      return _errorResponse<PerceptionVirtuelleConfirmResultModel>(
        response,
        context: context,
        requestBody: body,
      );
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  static Map<String, dynamic>? _unwrapPerceptionConfirmMap(dynamic decoded) {
    if (decoded is! Map) return null;

    final map = decoded is Map<String, dynamic>
        ? decoded
        : Map<String, dynamic>.from(decoded);

    final nested = map['data'] ?? map['Data'] ?? map['result'] ?? map['Result'];
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }

    if (map.containsKey('succes') ||
        map.containsKey('Succes') ||
        map.containsKey('success') ||
        map.containsKey('Success') ||
        map.containsKey('perceptionVirtuelleId') ||
        map.containsKey('PerceptionVirtuelleId')) {
      return map;
    }

    return null;
  }

  /// GET /api/WalletMouvement/by-agent/{agentId}/paginated
  static Future<ApiResponse<Map<String, dynamic>>> getWalletMouvementsPaginated(
    int agentId, {
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    String sortDirection = 'desc',
    String? search,
    String? filters,
  }) async {
    final queryParams = <String, String>{
      'Page': page.toString(),
      'PageSize': pageSize.toString(),
      'SortDirection': sortDirection,
    };
    if (sortBy != null && sortBy.isNotEmpty) {
      queryParams['SortBy'] = sortBy;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['Search'] = search;
    }
    if (filters != null && filters.isNotEmpty) {
      queryParams['Filters'] = filters;
    }

    return _get<Map<String, dynamic>>(
      '/api/WalletMouvement/by-agent/$agentId/paginated',
      queryParams: queryParams,
    );
  }

  /// Parse la réponse paginée des mouvements wallet agent.
  static List<WalletMouvementModel> parseWalletMouvements(
    Map<String, dynamic>? payload,
  ) {
    if (payload == null) return [];
    return PaginatedResponseHelper.extractRows(payload)
        .whereType<Map>()
        .map(
          (item) => WalletMouvementModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  static bool parseHasNextPage(Map<String, dynamic>? payload) {
    if (payload == null) return false;
    final value = payload['hasNextPage'] ?? payload['HasNextPage'];
    return value == true;
  }

  /// GET /api/WalletMouvement/{id} - Détail d'un mouvement wallet
  static Future<ApiResponse<WalletMouvementModel>> getWalletMouvementById(
    int id,
  ) async {
    final response = await _get<Map<String, dynamic>>('/api/WalletMouvement/$id');
    if (response.success && response.data != null) {
      return ApiResponse.success(
        WalletMouvementModel.fromJson(response.data!),
        statusCode: response.statusCode,
      );
    }
    return ApiResponse.error(
      response.message ??
          ApiErrorHelper.userFacingMessage(statusCode: response.statusCode),
      statusCode: response.statusCode,
    );
  }

  /// GET /api/WalletMouvement/by-agent/{agentId} - (legacy, liste non paginée)
  static Future<ApiResponse<List<WalletMouvementModel>>>
  getWalletMouvementsByAgent(int agentId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/WalletMouvement/by-agent/$agentId'),
        headers: ApiConfig.authHeaders(_token!),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          final mouvements = data
              .map((item) => WalletMouvementModel.fromJson(item))
              .toList();
          return ApiResponse.success(mouvements);
        } else {
          return ApiResponse.error(
            'Format de réponse invalide',
            statusCode: response.statusCode,
          );
        }
      } else {
        return _errorResponse(response);
      }
    } catch (e) {
      return _errorFromException(e, StackTrace.current);
    }
  }

  /// GET /api/DashboardAffilie/resume/{affilieId}?annee=
  static Future<ApiResponse<DashboardAffilieResumeModel>>
      getDashboardAffilieResume(
    int affilieId, {
    int? annee,
  }) async {
    final context = 'DashboardAffilie/resume/$affilieId';
    try {
      final query = annee != null ? '?annee=$annee' : '';
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/DashboardAffilie/resume/$affilieId$query',
        ),
        headers: ApiConfig.authHeaders(_token!),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return ApiResponse.success(
            DashboardAffilieResumeModel.fromJson(data),
          );
        }
        return ApiResponse.error(
          'Réponse dashboard affilié invalide',
          statusCode: response.statusCode,
        );
      }
      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/DashboardAffilie/cotisations/{affilieId}?mois=&annee=
  static Future<ApiResponse<List<DashboardAffilieCotisation>>>
      getDashboardAffilieCotisations(
    int affilieId, {
    int? mois,
    int? annee,
  }) async {
    final context = 'DashboardAffilie/cotisations/$affilieId';
    try {
      final params = <String, String>{};
      if (mois != null) params['mois'] = mois.toString();
      if (annee != null) params['annee'] = annee.toString();
      final query = params.isEmpty
          ? ''
          : '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/DashboardAffilie/cotisations/$affilieId$query',
        ),
        headers: ApiConfig.authHeaders(_token!),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(
          DashboardAffilieCotisation.listFromJson(data),
        );
      }
      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/DashboardAffilie/cotisations/recentes/{affilieId}?limit=
  static Future<ApiResponse<List<DashboardAffilieCotisation>>>
      getDashboardAffilieCotisationsRecentes(
    int affilieId, {
    int limit = 10,
  }) async {
    final context = 'DashboardAffilie/cotisations/recentes/$affilieId';
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/DashboardAffilie/cotisations/recentes/$affilieId?limit=$limit',
        ),
        headers: ApiConfig.authHeaders(_token!),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(
          DashboardAffilieCotisation.listFromJson(data),
        );
      }
      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/DashboardAffilie/prestations/{affilieId}?mois=&annee=
  static Future<ApiResponse<List<DashboardAffiliePrestation>>>
      getDashboardAffiliePrestations(
    int affilieId, {
    int? mois,
    int? annee,
  }) async {
    final context = 'DashboardAffilie/prestations/$affilieId';
    try {
      final params = <String, String>{};
      if (mois != null) params['mois'] = mois.toString();
      if (annee != null) params['annee'] = annee.toString();
      final query = params.isEmpty
          ? ''
          : '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/DashboardAffilie/prestations/$affilieId$query',
        ),
        headers: ApiConfig.authHeaders(_token!),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(
          DashboardAffiliePrestation.listFromJson(data),
        );
      }
      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/DashboardAffilie/prestations/recentes/{affilieId}?limit=
  static Future<ApiResponse<List<DashboardAffiliePrestation>>>
      getDashboardAffiliePrestationsRecentes(
    int affilieId, {
    int limit = 10,
  }) async {
    final context = 'DashboardAffilie/prestations/recentes/$affilieId';
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/DashboardAffilie/prestations/recentes/$affilieId?limit=$limit',
        ),
        headers: ApiConfig.authHeaders(_token!),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(
          DashboardAffiliePrestation.listFromJson(data),
        );
      }
      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/Affilie/paiements/historique — historique paginé des paiements.
  /// Essaie d'abord une requête minimale (évite certains 500 liés aux filtres).
  static Future<ApiResponse<Map<String, dynamic>>> getAffiliePaiementsHistorique({
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    String? sortDirection,
    String? search,
    String? filters,
    int? affilieId,
  }) async {
    const endpoint = '/api/Affilie/paiements/historique';
    final pagination = <String, String>{
      'Page': page.toString(),
      'pageNumber': page.toString(),
      'PageSize': pageSize.toString(),
      'pageSize': pageSize.toString(),
    };

    final minimal = Map<String, String>.from(pagination);
    var response = await _getHistoriquePaiements(
      endpoint,
      minimal,
      attempt: 'pagination seule',
    );
    if (response.success || response.statusCode != 500) {
      return response;
    }

    final withSort = <String, String>{
      ...pagination,
      if (sortBy != null && sortBy.isNotEmpty) 'SortBy': sortBy,
      if (sortDirection != null && sortDirection.isNotEmpty)
        'SortDirection': sortDirection,
    };
    if (withSort.length > pagination.length) {
      response = await _getHistoriquePaiements(
        endpoint,
        withSort,
        attempt: 'tri',
      );
      if (response.success || response.statusCode != 500) {
        return response;
      }
    }

    final full = <String, String>{
      ...withSort,
      if (search != null && search.isNotEmpty) 'Search': search,
      if (filters != null && filters.isNotEmpty) 'Filters': filters,
      if (affilieId != null) 'affilieId': affilieId.toString(),
    };
    if (full.length > withSort.length) {
      response = await _getHistoriquePaiements(
        endpoint,
        full,
        attempt: 'filtres complets',
      );
    }

    return response;
  }

  static Future<ApiResponse<Map<String, dynamic>>> _getHistoriquePaiements(
    String endpoint,
    Map<String, String> queryParams, {
    required String attempt,
  }) async {
    final response = await _get<Map<String, dynamic>>(
      endpoint,
      queryParams: queryParams,
    );
    if (!response.success &&
        ApiErrorHelper.isRetryableStatusCode(response.statusCode) &&
        kDebugMode) {
      debugPrint(
        '[API] $endpoint ($attempt) → ${response.statusCode} '
        '${response.message ?? ''}',
      );
    }
    return response;
  }

  /// Liste typée de l'historique des paiements affilié.
  static Future<ApiResponse<List<AffiliePaiementHistoriqueModel>>>
  getAffiliePaiementsHistoriqueList({
    int page = 1,
    int pageSize = 20,
    String? search,
    int? affilieId,
    String? sortBy,
    String? sortDirection,
  }) async {
    final filters = affilieId != null ? 'affilieId=$affilieId' : null;
    final response = await getAffiliePaiementsHistorique(
      page: page,
      pageSize: pageSize,
      search: search,
      filters: filters,
      affilieId: affilieId,
      sortBy: sortBy ?? 'dateCollecte',
      sortDirection: sortDirection ?? 'desc',
    );

    if (!response.success || response.data == null) {
      return ApiResponse(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final rows = PaginatedResponseHelper.extractRows(response.data);
    final parsed = <AffiliePaiementHistoriqueModel>[];
    for (final item in rows) {
      if (item is! Map) continue;
      try {
        final map = item is Map<String, dynamic>
            ? item
            : Map<String, dynamic>.from(item);
        parsed.add(AffiliePaiementHistoriqueModel.fromJson(map));
      } catch (e, stackTrace) {
        if (kDebugMode) {
          ApiErrorHelper.logException(
            'PaiementHistorique/fromJson',
            e,
            stackTrace,
          );
        }
      }
    }

    return ApiResponse.success(parsed, statusCode: response.statusCode);
  }

  /// GET /api/Superviseur/hierarchie/{superviseurId} — Hiérarchie équipe
  static Future<ApiResponse<SuperviseurHierarchieModel>> getSuperviseurHierarchie(
    int superviseurId,
  ) async {
    final context = 'Superviseur/hierarchie/$superviseurId';
    try {
      final response = await _httpGet(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/Superviseur/hierarchie/$superviseurId',
        ),
        context: context,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) {
          return ApiResponse.error(
            'Réponse hiérarchie superviseur invalide',
            statusCode: response.statusCode,
          );
        }
        final map = decoded is Map<String, dynamic>
            ? decoded
            : Map<String, dynamic>.from(decoded);
        return ApiResponse.success(
          SuperviseurHierarchieModel.fromJson(map),
          statusCode: response.statusCode,
        );
      }
      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/Agents/by-superviseur/{superviseurId} — Agents supervisés
  static Future<ApiResponse<List<AgentModel>>> getAgentsBySuperviseur(
    int superviseurId,
  ) async {
    final context = 'Agents/by-superviseur/$superviseurId';
    try {
      final response = await _httpGet(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/Agents/by-superviseur/$superviseurId',
        ),
        context: context,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final rows = PaginatedResponseHelper.extractRows(decoded);
        final agents = rows
            .whereType<Map>()
            .map((row) => AgentModel.fromJson(Map<String, dynamic>.from(row)))
            .toList();
        return ApiResponse.success(agents, statusCode: response.statusCode);
      }
      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/DashboardSuperviseur/dashboard/{superviseurId}
  static Future<ApiResponse<DashboardSuperviseurModel>> getDashboardSuperviseur(
    int superviseurId,
  ) async {
    final context = 'DashboardSuperviseur/dashboard/$superviseurId';
    try {
      final response = await _httpGet(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/DashboardSuperviseur/dashboard/$superviseurId',
        ),
        context: context,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) {
          return ApiResponse.error(
            'Réponse dashboard superviseur invalide',
            statusCode: response.statusCode,
          );
        }
        final map = decoded is Map<String, dynamic>
            ? decoded
            : Map<String, dynamic>.from(decoded);
        return ApiResponse.success(
          DashboardSuperviseurModel.fromJson(map),
          statusCode: response.statusCode,
        );
      }
      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/DashboardSuperviseur/kpis/{superviseurId}?limit=
  static Future<ApiResponse<StatsSuperviseur>> getDashboardSuperviseurKpis(
    int superviseurId, {
    int? limit,
  }) async {
    final context = 'DashboardSuperviseur/kpis/$superviseurId';
    try {
      final query = limit != null ? '?limit=$limit' : '';
      final response = await _httpGet(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/DashboardSuperviseur/kpis/$superviseurId$query',
        ),
        context: context,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) {
          return ApiResponse.error(
            'Réponse KPIs superviseur invalide',
            statusCode: response.statusCode,
          );
        }
        final map = decoded is Map<String, dynamic>
            ? decoded
            : Map<String, dynamic>.from(decoded);
        return ApiResponse.success(
          StatsSuperviseur.fromJson(map),
          statusCode: response.statusCode,
        );
      }
      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/DashboardSuperviseur/indicateurs-performance/{superviseurId}
  static Future<ApiResponse<SuperviseurIndicateursPerformance>>
      getDashboardSuperviseurIndicateursPerformance(
    int superviseurId,
  ) async {
    final context =
        'DashboardSuperviseur/indicateurs-performance/$superviseurId';
    try {
      final response = await _httpGet(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/DashboardSuperviseur/indicateurs-performance/$superviseurId',
        ),
        context: context,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) {
          return ApiResponse.error(
            'Réponse indicateurs superviseur invalide',
            statusCode: response.statusCode,
          );
        }
        final map = decoded is Map<String, dynamic>
            ? decoded
            : Map<String, dynamic>.from(decoded);
        return ApiResponse.success(
          SuperviseurIndicateursPerformance.fromJson(map),
          statusCode: response.statusCode,
        );
      }
      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/DashboardSuperviseur/top-agents/{superviseurId}?limit=
  static Future<ApiResponse<List<SuperviseurAgentPerformance>>>
      getDashboardSuperviseurTopAgents(
    int superviseurId, {
    int? limit,
  }) async {
    final context = 'DashboardSuperviseur/top-agents/$superviseurId';
    try {
      final query = limit != null ? '?limit=$limit' : '';
      final response = await _httpGet(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/DashboardSuperviseur/top-agents/$superviseurId$query',
        ),
        context: context,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final rows = decoded is List
            ? decoded
            : PaginatedResponseHelper.extractRows(decoded);
        final agents = rows
            .whereType<Map>()
            .map(
              (row) => SuperviseurAgentPerformance.fromJson(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList();
        return ApiResponse.success(agents, statusCode: response.statusCode);
      }
      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/DashboardChefEquipe/kpis — KPIs Chef d'équipe
  static Future<ApiResponse<ChefEquipeKpisDto>> getChefEquipeKpis() async {
    const context = 'DashboardChefEquipe/kpis';
    try {
      final response = await _httpGet(
        Uri.parse('${ApiConfig.baseUrl}/api/DashboardChefEquipe/kpis'),
        context: context,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) {
          return ApiResponse.error(
            'Réponse KPIs Chef d\'équipe invalide',
            statusCode: response.statusCode,
          );
        }
        final map = decoded is Map<String, dynamic>
            ? decoded
            : Map<String, dynamic>.from(decoded);
        return ApiResponse.success(
          ChefEquipeKpisDto.fromJson(map),
          statusCode: response.statusCode,
        );
      }

      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/DashboardChefEquipe/agents — Agents AT (résumé) de la zone
  static Future<ApiResponse<List<ChefEquipeAgentResumeDto>>>
      getChefEquipeAgents() async {
    const context = 'DashboardChefEquipe/agents';
    try {
      final response = await _httpGet(
        Uri.parse('${ApiConfig.baseUrl}/api/DashboardChefEquipe/agents'),
        context: context,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final rows = decoded is List
            ? decoded
            : decoded is Map
                ? PaginatedResponseHelper.extractRows(decoded)
                : const [];

        final agents = rows
            .whereType<Map>()
            .map((row) =>
                ChefEquipeAgentResumeDto.fromJson(Map<String, dynamic>.from(row)))
            .toList();

        return ApiResponse.success(agents, statusCode: response.statusCode);
      }

      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/DashboardChefEquipe/agents/{agentId}/mouvements-wallet?limit=20
  static Future<ApiResponse<AgentCommissionsResumeDto>>
      getChefEquipeMouvementsWallet(
    int agentId, {
    int limit = 20,
  }) async {
    final context = 'DashboardChefEquipe/agents/$agentId/mouvements-wallet';
    try {
      final query = limit > 0 ? '?limit=$limit' : '';
      final response = await _httpGet(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/DashboardChefEquipe/agents/$agentId/mouvements-wallet$query',
        ),
        context: context,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) {
          return ApiResponse.error(
            'Réponse mouvements wallet Chef d\'équipe invalide',
            statusCode: response.statusCode,
          );
        }
        final map = decoded is Map<String, dynamic>
            ? decoded
            : Map<String, dynamic>.from(decoded);
        return ApiResponse.success(
          AgentCommissionsResumeDto.fromJson(map),
          statusCode: response.statusCode,
        );
      }

      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/DashboardChefEquipe/agents/{agentId}/collectes?limit=50
  static Future<ApiResponse<List<ChefEquipeCollecteResumeDto>>>
      getChefEquipeCollectes(
    int agentId, {
    int limit = 50,
  }) async {
    final context = 'DashboardChefEquipe/agents/$agentId/collectes';
    try {
      final query = limit > 0 ? '?limit=$limit' : '';
      final response = await _httpGet(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/DashboardChefEquipe/agents/$agentId/collectes$query',
        ),
        context: context,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final rows = decoded is List
            ? decoded
            : decoded is Map
                ? PaginatedResponseHelper.extractRows(decoded)
                : const [];

        final collectes = rows
            .whereType<Map>()
            .map((row) => ChefEquipeCollecteResumeDto.fromJson(
                  Map<String, dynamic>.from(row),
                ))
            .toList();

        return ApiResponse.success(
          collectes,
          statusCode: response.statusCode,
        );
      }

      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/DashboardPercepteur/summary — Dashboard percepteur (token JWT)
  static Future<ApiResponse<DashboardPercepteurModel>>
      getDashboardPercepteurSummary() async {
    const context = 'DashboardPercepteur/summary';
    try {
      final response = await _httpGet(
        Uri.parse('${ApiConfig.baseUrl}/api/DashboardPercepteur/summary'),
        context: context,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) {
          return ApiResponse.error(
            'Réponse dashboard percepteur invalide',
            statusCode: response.statusCode,
          );
        }
        final map = decoded is Map<String, dynamic>
            ? decoded
            : Map<String, dynamic>.from(decoded);
        return ApiResponse.success(
          DashboardPercepteurModel.fromJson(map),
          statusCode: response.statusCode,
        );
      }
      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/DashboardPercepteur/transactions — Transactions récentes percepteur
  static Future<ApiResponse<List<PercepteurTransaction>>>
      getDashboardPercepteurTransactions({
    int limit = 5,
  }) async {
    const context = 'DashboardPercepteur/transactions';
    try {
      final response = await _httpGet(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/DashboardPercepteur/transactions?limit=$limit',
        ),
        context: context,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final rows = decoded is List
            ? decoded
            : PaginatedResponseHelper.extractRows(decoded);
        final transactions = rows
            .whereType<Map>()
            .map(
              (row) => PercepteurTransaction.fromJson(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList();
        return ApiResponse.success(
          transactions,
          statusCode: response.statusCode,
        );
      }
      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/DashboardPercepteur/evolution-transactions — Évolution par période
  static Future<ApiResponse<List<PercepteurEvolutionTransaction>>>
      getDashboardPercepteurEvolutionTransactions({
    int mois = 6,
  }) async {
    const context = 'DashboardPercepteur/evolution-transactions';
    try {
      final response = await _httpGet(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/DashboardPercepteur/evolution-transactions?mois=$mois',
        ),
        context: context,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final rows = decoded is List
            ? decoded
            : PaginatedResponseHelper.extractRows(decoded);
        final evolution = rows
            .whereType<Map>()
            .map(
              (row) => PercepteurEvolutionTransaction.fromJson(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList();
        return ApiResponse.success(
          evolution,
          statusCode: response.statusCode,
        );
      }
      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/DashboardAgent/performance - Performance du dashboard agent (agentID from token)
  static Future<ApiResponse<DashboardAgentModel>> getDashboardAgentPerformance(
  ) {
    return _getDashboardAgent('performance', context: 'DashboardAgent/performance');
  }

  /// GET /api/DashboardAgent/terrain - Dashboard terrain agent (agentID from token)
  static Future<ApiResponse<DashboardAgentModel>> getDashboardAgentTerrain() {
    return _getDashboardAgent('terrain', context: 'DashboardAgent/terrain');
  }

  /// GET /api/DashboardAgent/graphs - Graphiques du dashboard agent (agentID from token)
  static Future<ApiResponse<DashboardAgentGraphsModel>>
      getDashboardAgentGraphs() async {
    const context = 'DashboardAgent/graphs';
    try {
      final response = await _httpGet(
        Uri.parse('${ApiConfig.baseUrl}/api/DashboardAgent/graphs'),
        context: context,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final map = unwrapDashboardAgentGraphsJson(decoded);
        if (map == null || !dashboardAgentGraphsPayloadLooksValid(map)) {
          if (kDebugMode) {
            debugPrint(
              '[API] $context — structure inattendue: '
              '${decoded.runtimeType}',
            );
          }
          return ApiResponse.error(
            'Réponse graphiques invalide',
            statusCode: response.statusCode,
          );
        }
        return ApiResponse.success(DashboardAgentGraphsModel.fromJson(map));
      }
      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  static Future<ApiResponse<DashboardAgentModel>> _getDashboardAgent(
    String segment, {
    required String context,
  }) async {
    try {
      final response = await _httpGet(
        Uri.parse('${ApiConfig.baseUrl}/api/DashboardAgent/$segment'),
        context: context,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final map = unwrapDashboardAgentJson(decoded);
        if (map == null || !dashboardAgentPayloadLooksValid(map)) {
          if (kDebugMode) {
            debugPrint(
              '[API] $context — structure inattendue: '
              '${decoded.runtimeType}',
            );
          }
          return ApiResponse.error(
            'Réponse dashboard invalide',
            statusCode: response.statusCode,
          );
        }
        return ApiResponse.success(DashboardAgentModel.fromJson(map));
      }
      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/DashboardAgent/kpis - KPIs du agent (agentID from token)
  static Future<ApiResponse<KpiAgentModel>> getAgentKpis() async {
    const context = 'DashboardAgent/kpis';
    try {
      final response = await _httpGet(
        Uri.parse('${ApiConfig.baseUrl}/api/DashboardAgent/kpis'),
        context: context,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final map = unwrapKpiAgentJson(decoded);
        if (map == null || !kpiAgentPayloadLooksValid(map)) {
          if (kDebugMode) {
            debugPrint(
              '[API] $context — structure inattendue: '
              '${decoded.runtimeType}',
            );
          }
          return ApiResponse.error(
            'Réponse KPI invalide',
            statusCode: response.statusCode,
          );
        }
        return ApiResponse.success(KpiAgentModel.fromJson(map));
      }
      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/DashboardAgent/affilies-recents - Affiliés récents
  static Future<ApiResponse<List<RecentAffilieModel>>> getRecentAffiliates({
    int limit = 5,
  }) async {
    final context = 'DashboardAgent/affilies-recents';
    try {
      final response = await _httpGet(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/DashboardAgent/affilies-recents?limit=$limit',
        ),
        context: context,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rows = data is List
            ? data
            : PaginatedResponseHelper.extractRows(data);
        return ApiResponse.success(
          rows
              .whereType<Map>()
              .map((json) => RecentAffilieModel.fromJson(
                    Map<String, dynamic>.from(json),
                  ))
              .toList(),
        );
      } else {
        return _errorResponse(response, context: context);
      }
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// POST /api/agent - Créer un agent
  static Future<ApiResponse<Map<String, dynamic>>> createAgent({
    required String codeAT,
    required String nomComplet,
    required String matricule,
    required String phone,
    required int zoneSocialeId,
    int? categorieAgentId,
    bool statut = true,
  }) async {
    return _post<Map<String, dynamic>>('/api/agent', {
      'codeAT': codeAT,
      'nomComplet': nomComplet,
      'matricule': matricule,
      'phone': phone,
      'zoneSocialeId': zoneSocialeId,
      'categorieAgentId': categorieAgentId,
      'statut': statut,
    });
  }

  /// POST /api/Utilisateur/changer_mot_de_passe - Changer le mot de passe
  static Future<ApiResponse<Map<String, dynamic>>> changePassword({
    required int idUtilisateur,
    required String ancienMotDePasse,
    required String nouveauMotDePasse,
    required String confirmerNouveauMotDePasse,
  }) async {
    return _post<Map<String, dynamic>>(
      '/api/Utilisateur/changer_mot_de_passe',
      {
        'idUtilisateur': idUtilisateur,
        'ancienMotDePasse': ancienMotDePasse,
        'nouveauMotDePasse': nouveauMotDePasse,
        'confirmerNouveauMotDePasse': confirmerNouveauMotDePasse,
      },
    );
  }

  /// POST /api/Affilie - Créer un nouvel affilié
  static Future<ApiResponse<AffilieModel>> createAffilie({
    required String codeAdhesion,
    required String nom,
    required String prenom,
    required DateTime dateNaissance,
    required String telephone,
    required String postnom,
    required String provinceResidence,
    required String communeResidence,
    required String quartierResidence,
    required String avenueResidence,
    required String numeroResidence,
    required String communeActivite,
    required String quartierActivite,
    required String avenueActivite,
    required String numeroActivite,
    bool statut = true,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/Affilie'),
      headers: isAuthenticated
          ? ApiConfig.authHeaders(_token!)
          : ApiConfig.headers,
      body: jsonEncode({
        'codeAdhesion': codeAdhesion,
        'nom': nom,
        'prenom': prenom,
        'dateNaissance': dateNaissance.toIso8601String(),
        'telephone': telephone,
        'postnom': postnom,
        'provinceResidence': provinceResidence,
        'communeResidence': communeResidence,
        'quartierResidence': quartierResidence,
        'avenueResidence': avenueResidence,
        'numeroResidence': numeroResidence,
        'communeActivite': communeActivite,
        'quartierActivite': quartierActivite,
        'avenueActivite': avenueActivite,
        'numeroActivite': numeroActivite,
        'statut': statut,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return ApiResponse.success(
        AffilieModel.fromJson(data),
        statusCode: response.statusCode,
      );
    } else {
      return _errorResponse(response, context: 'createAffilie');
    }
  }

  /// POST /api/Adhesion/with-affilie - Créer une adhésion avec affilié (nouveau format)
  static Future<ApiResponse<AdhesionResponse>> createAdhesionWithAffilieV2(
    AdhesionWithAffilieRequest request,
  ) async {
    const context = 'Adhesion/with-affilie';
    try {
      final requestMap = request.toJson();
      final requestJson = jsonEncode(requestMap);
      if (kDebugMode) {
        final photoLen = (requestMap['photoBase64'] as String?)?.length ?? 0;
        final carteLen =
            (requestMap['carteIdentiteBase64'] as String?)?.length ?? 0;
        debugPrint(
          '[API] $context body: ${requestJson.length} octets '
          '(photo: $photoLen, carte: $carteLen base64)',
        );
      }
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Adhesion/with-affilie'),
        headers: isAuthenticated
            ? ApiConfig.authHeaders(_token!)
            : ApiConfig.headers,
        body: requestJson,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (kDebugMode) debugPrint('Adhesion response OK');
        return ApiResponse.success(
          AdhesionResponse.fromJson(data),
          statusCode: response.statusCode,
        );
      } else {
        return _errorResponse<AdhesionResponse>(
          response,
          context: context,
          requestBody: _sanitizeAdhesionLogPayload(requestMap),
        );
      }
    } catch (e) {
      return _errorFromException(e, StackTrace.current);
    }
  }

  static Map<String, dynamic> _sanitizeAdhesionLogPayload(
    Map<String, dynamic> payload,
  ) {
    const base64Keys = {'photoBase64', 'carteIdentiteBase64'};
    final out = <String, dynamic>{};
    payload.forEach((key, value) {
      if (base64Keys.contains(key) && value is String && value.isNotEmpty) {
        out[key] = '<base64 ${value.length} caractères>';
      } else {
        out[key] = value;
      }
    });
    return out;
  }

  /// POST /api/Adhesion/with-affilie-paiement-electronique — Mobile Money / FlexPay
  static Future<ApiResponse<AdhesionElectronicPaymentResponse>>
      createAdhesionWithAffiliePaiementElectronique({
    required AdhesionWithAffilieRequest adhesion,
    required String modePaiement,
    required String telephonePaiement,
    required int devisePaiementId,
  }) async {
    const context = 'Adhesion/with-affilie-paiement-electronique';
    try {
      final body = jsonEncode({
        'adhesion': adhesion.toJson(),
        'modePaiement': modePaiement,
        'telephonePaiement': telephonePaiement,
        'devisePaiementId': devisePaiementId,
      });
      ApiErrorHelper.logRequest(
        context,
        {
          'modePaiement': modePaiement,
          'telephonePaiement': telephonePaiement,
          'devisePaiementId': devisePaiementId,
        },
        endpoint: '/api/Adhesion/with-affilie-paiement-electronique',
      );

      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/Adhesion/with-affilie-paiement-electronique',
        ),
        headers: isAuthenticated
            ? ApiConfig.authHeaders(_token!)
            : ApiConfig.headers,
        body: body,
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        ApiErrorHelper.logHttpSuccess(
          context,
          statusCode: response.statusCode,
          body: response.body,
          endpoint: '/api/Adhesion/with-affilie-paiement-electronique',
        );
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final payload = data.containsKey('idCollecteEnAttente') ||
                  data.containsKey('flexPayAccepted')
              ? data
              : (data['data'] is Map<String, dynamic>
                  ? data['data'] as Map<String, dynamic>
                  : data);
          return ApiResponse.success(
            AdhesionElectronicPaymentResponse.fromJson(payload),
            statusCode: response.statusCode,
          );
        }
        return ApiResponse.error(
          'Format de réponse invalide',
          statusCode: response.statusCode,
        );
      }
      return _errorResponse<AdhesionElectronicPaymentResponse>(
        response,
        context: context,
      );
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/Adhesion/en-ligne-sans-gestionnaire — File d'attente (Superviseur)
  static Future<ApiResponse<PaginatedAdhesionsEnLigne>>
      getAdhesionsEnLigneSansGestionnaire({
    int page = 1,
    int pageSize = 20,
  }) async {
    const context = 'Adhesion/en-ligne-sans-gestionnaire';
    final query =
        '?page=$page&pageSize=$pageSize&pageNumber=$page&Page=$page&PageSize=$pageSize';
    try {
      final response = await _httpGet(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/Adhesion/en-ligne-sans-gestionnaire$query',
        ),
        context: context,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final rows = PaginatedResponseHelper.extractRows(decoded);
        final items = rows
            .whereType<Map>()
            .map(
              (row) => AdhesionEnLigneSansGestionnaireModel.fromJson(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList();
        return ApiResponse.success(
          PaginatedAdhesionsEnLigne(
            items: items,
            totalItems: PaginatedResponseHelper.extractTotalItems(
              decoded,
              fallback: items.length,
            ),
            currentPage: PaginatedResponseHelper.extractCurrentPage(
              decoded,
              fallback: page,
            ),
            hasNext: PaginatedResponseHelper.extractHasNext(decoded),
          ),
          statusCode: response.statusCode,
        );
      }
      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// PUT /api/Agent/{agentId}/affecter-affilies — Affectation affiliés vers AT
  static Future<ApiResponse<AgentAffecterAffiliesResultModel>>
      affecterAffiliesToAgent(
    int agentId, {
    required List<int> affilieIds,
    int? sourceAgentId,
  }) async {
    const context = 'Agent/affecter-affilies';
    final body = <String, dynamic>{
      'affilieIds': affilieIds,
      if (sourceAgentId != null) 'sourceAgentId': sourceAgentId,
    };
    try {
      final response = await _withAuthRetry(
        () => http.put(
          Uri.parse(
            '${ApiConfig.baseUrl}/api/Agent/$agentId/affecter-affilies',
          ),
          headers: isAuthenticated
              ? ApiConfig.authHeaders(_token!)
              : ApiConfig.headers,
          body: jsonEncode(body),
        ),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          final map = decoded is Map<String, dynamic>
              ? decoded
              : Map<String, dynamic>.from(decoded);
          final payload = map['data'] is Map
              ? Map<String, dynamic>.from(map['data'] as Map)
              : map;
          return ApiResponse.success(
            AgentAffecterAffiliesResultModel.fromJson(payload),
            statusCode: response.statusCode,
          );
        }
        return ApiResponse.error(
          'Réponse affectation invalide',
          statusCode: response.statusCode,
        );
      }
      return _errorResponse(response, context: context, requestBody: body);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/Referentiel/liens-parente — Codes lien parenté (public)
  static Future<ApiResponse<List<LienParenteModel>>> getLiensParente() async {
    const context = 'Referentiel/liens-parente';
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/Referentiel/liens-parente'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final rows = PaginatedResponseHelper.extractRows(decoded);
        final list = rows.isNotEmpty
            ? rows
            : (decoded is List ? decoded : const <dynamic>[]);
        final items = list
            .whereType<Map>()
            .map(
              (row) => LienParenteModel.fromJson(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList();
        return ApiResponse.success(items, statusCode: response.statusCode);
      }
      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// PUT /api/Agent/{id} — Mettre à jour un agent
  static Future<ApiResponse<Map<String, dynamic>>> updateAgent(
    int id, {
    String? codeAT,
    String? nomComplet,
    String? matricule,
    String? phone,
    String? emailAgent,
    String? fonction,
    String? roleAgent,
    String? photoUrl,
    int? zoneSocialeId,
    int? categorieAgentId,
    bool? statut,
  }) async {
    return _put<Map<String, dynamic>>('/api/Agent/$id', {
      if (codeAT != null) 'codeAT': codeAT,
      if (nomComplet != null) 'nomComplet': nomComplet,
      if (matricule != null) 'matricule': matricule,
      if (phone != null) 'phone': phone,
      if (emailAgent != null) 'emailAgent': emailAgent,
      if (fonction != null) 'fonction': fonction,
      if (roleAgent != null) 'roleAgent': roleAgent,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (zoneSocialeId != null) 'zoneSocialeId': zoneSocialeId,
      if (categorieAgentId != null) 'categorieAgentId': categorieAgentId,
      if (statut != null) 'statut': statut,
    });
  }

  /// DELETE /api/agent/{id} - Supprimer un agent
  static Future<ApiResponse<void>> deleteAgent(int id) async {
    return _delete('/api/agent/$id');
  }

  // ============================================
  // ADHÉSIONS
  // ============================================

  /// GET /api/Frais - Liste de tous les frais
  static Future<ApiResponse<List<Frais>>> getFrais() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/Frais'),
        headers: isAuthenticated
            ? ApiConfig.authHeaders(_token!)
            : ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final rows = PaginatedResponseHelper.extractRows(decoded);
        final parsed = <Frais>[];
        for (final item in rows) {
          if (item is! Map) continue;
          try {
            parsed.add(
              Frais.fromJson(
                item is Map<String, dynamic>
                    ? item
                    : Map<String, dynamic>.from(item),
              ),
            );
          } catch (e, stackTrace) {
            ApiErrorHelper.logException('Frais/fromJson', e, stackTrace);
          }
        }
        return ApiResponse.success(parsed, statusCode: response.statusCode);
      } else {
        return _errorResponse(response);
      }
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, 'Frais/list');
    }
  }

  /// GET /api/adhesion - Liste de toutes les adhésions
  static Future<ApiResponse<List<dynamic>>> getAdhesions() async {
    return _get<List<dynamic>>('/api/adhesion');
  }

  /// POST /api/adhesion/with-affilie - Créer une adhésion avec un affilié
  static Future<ApiResponse<Map<String, dynamic>>> createAdhesionWithAffilie({
    required Map<String, dynamic> affilie,
    required Map<String, dynamic> adhesion,
    required List<Map<String, dynamic>> souscriptions,
    required Map<String, dynamic> collecte,
  }) async {
    return _post<Map<String, dynamic>>('/api/adhesion/with-affilie', {
      'affilie': affilie,
      'adhesion': adhesion,
      'souscriptions': souscriptions,
      'collecte': collecte,
    });
  }

  // ============================================
  // AFFILIÉS
  // ============================================

  /// GET /api/affilie - Liste de tous les affiliés
  static Future<ApiResponse<List<dynamic>>> getAffilies() async {
    return _get<List<dynamic>>('/api/affilie');
  }

  /// GET /api/Affilie — Liste paginée des affiliés (recherche, filtres)
  static Future<ApiResponse<Map<String, dynamic>>> searchAffilies({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? sortBy,
    String? sortDirection,
    String? filters,
  }) async {
    final queryParams = <String, String>{
      'Page': page.toString(),
      'pageNumber': page.toString(),
      'PageSize': pageSize.toString(),
      'pageSize': pageSize.toString(),
      if (sortBy != null && sortBy.isNotEmpty) 'SortBy': sortBy,
      if (sortDirection != null && sortDirection.isNotEmpty)
        'SortDirection': sortDirection,
      if (search != null && search.isNotEmpty) 'Search': search,
      if (filters != null && filters.isNotEmpty) 'Filters': filters,
    };

    final queryString = Uri(queryParameters: queryParams).query;
    return _get<Map<String, dynamic>>('/api/Affilie?$queryString');
  }

  /// GET /api/affilie/{id} - Affilié spécifique
  static Future<ApiResponse<Map<String, dynamic>>> getAffilie(int id) async {
    return _get<Map<String, dynamic>>('/api/affilie/$id');
  }

  /// POST /api/affilie - Créer un affilié (ancien)
  @Deprecated('Utiliser createAffilie à la place')
  static Future<ApiResponse<Map<String, dynamic>>> createOldAffilie({
    required String nom,
    required String prenom,
    required DateTime dateN,
    required String telephone,
  }) async {
    return _post<Map<String, dynamic>>('/api/affilie', {
      'nom': nom,
      'prenom': prenom,
      'dateN': dateN.toIso8601String(),
      'telephone': telephone,
    });
  }

  /// PUT /api/affilie/{id} - Mettre à jour un affilié
  static Future<ApiResponse<Map<String, dynamic>>> updateAffilie(
    int id, {
    String? nom,
    String? prenom,
    DateTime? dateN,
    String? telephone,
    bool? statut,
  }) async {
    return _put<Map<String, dynamic>>('/api/affilie/$id', {
      if (nom != null) 'nom': nom,
      if (prenom != null) 'prenom': prenom,
      if (dateN != null) 'dateN': dateN.toIso8601String(),
      if (telephone != null) 'telephone': telephone,
      if (statut != null) 'statut': statut,
    });
  }

  // ============================================
  // ZONES SOCIALES
  // ============================================

  /// GET /api/zonesociale - Liste de toutes les zones sociales
  static Future<ApiResponse<List<dynamic>>> getZoneSociales() async {
    return _get<List<dynamic>>('/api/zonesociale');
  }

  /// GET /api/zonesociale/{id} - Zone sociale spécifique
  static Future<ApiResponse<Map<String, dynamic>>> getZoneSociale(
    int id,
  ) async {
    return _get<Map<String, dynamic>>('/api/zonesociale/$id');
  }

  /// POST /api/zonesociale - Créer une zone sociale
  static Future<ApiResponse<Map<String, dynamic>>> createZoneSociale({
    required String nom,
    required int communeId,
    bool statut = true,
  }) async {
    return _post<Map<String, dynamic>>('/api/zonesociale', {
      'nom': nom,
      'communeId': communeId,
      'statut': statut,
    });
  }

  /// PUT /api/zonesociale/{id} - Mettre à jour une zone sociale
  static Future<ApiResponse<Map<String, dynamic>>> updateZoneSociale(
    int id, {
    String? nom,
    int? communeId,
    bool? statut,
  }) async {
    return _put<Map<String, dynamic>>('/api/zonesociale/$id', {
      if (nom != null) 'nom': nom,
      if (communeId != null) 'communeId': communeId,
      if (statut != null) 'statut': statut,
    });
  }

  /// DELETE /api/zonesociale/{id} - Supprimer une zone sociale
  static Future<ApiResponse<void>> deleteZoneSociale(int id) async {
    return _delete('/api/zonesociale/$id');
  }

  // ============================================
  // COMMUNES
  // ============================================

  /// GET /api/commune - Liste de toutes les communes
  static Future<ApiResponse<List<dynamic>>> getCommunes() async {
    return _get<List<dynamic>>('/api/commune');
  }

  /// GET /api/commune/{id} - Commune spécifique
  static Future<ApiResponse<Map<String, dynamic>>> getCommune(int id) async {
    return _get<Map<String, dynamic>>('/api/commune/$id');
  }

  /// POST /api/commune - Créer une commune
  static Future<ApiResponse<Map<String, dynamic>>> createCommune({
    required String nom,
    required int provinceId,
    bool statut = true,
  }) async {
    return _post<Map<String, dynamic>>('/api/commune', {
      'nom': nom,
      'provinceId': provinceId,
      'statut': statut,
    });
  }

  /// PUT /api/commune/{id} - Mettre à jour une commune
  static Future<ApiResponse<Map<String, dynamic>>> updateCommune(
    int id, {
    String? nom,
    int? provinceId,
    bool? statut,
  }) async {
    return _put<Map<String, dynamic>>('/api/commune/$id', {
      if (nom != null) 'nom': nom,
      if (provinceId != null) 'provinceId': provinceId,
      if (statut != null) 'statut': statut,
    });
  }

  /// DELETE /api/commune/{id} - Supprimer une commune
  static Future<ApiResponse<void>> deleteCommune(int id) async {
    return _delete('/api/commune/$id');
  }

  // ============================================
  // PROVINCES
  // ============================================

  /// GET /api/province - Liste de toutes les provinces
  static Future<ApiResponse<List<dynamic>>> getProvinces() async {
    return _get<List<dynamic>>('/api/province');
  }

  /// GET /api/province/{id} - Province spécifique
  static Future<ApiResponse<Map<String, dynamic>>> getProvince(int id) async {
    return _get<Map<String, dynamic>>('/api/province/$id');
  }

  /// POST /api/province - Créer une province
  static Future<ApiResponse<Map<String, dynamic>>> createProvince({
    required String nom,
    bool statut = true,
  }) async {
    return _post<Map<String, dynamic>>('/api/province', {
      'nom': nom,
      'statut': statut,
    });
  }

  // ============================================
  // COLLECTES
  // ============================================

  /// GET /api/TarifCotisation - Liste paginée des tarifs de cotisation
  static Future<ApiResponse<Map<String, dynamic>>> getTarifCotisations({
    int page = 1,
    int pageSize = 50,
    String? sortBy,
    String? sortDirection,
    String? search,
    String? filters,
  }) async {
    final queryParams = <String, String>{
      'Page': page.toString(),
      'pageNumber': page.toString(),
      'PageSize': pageSize.toString(),
      'pageSize': pageSize.toString(),
      if (sortBy != null && sortBy.isNotEmpty) 'SortBy': sortBy,
      if (sortDirection != null && sortDirection.isNotEmpty)
        'SortDirection': sortDirection,
      if (search != null && search.isNotEmpty) 'Search': search,
      if (filters != null && filters.isNotEmpty) 'Filters': filters,
    };
    return _get<Map<String, dynamic>>(
      '/api/TarifCotisation',
      queryParams: queryParams,
    );
  }

  /// GET /api/TarifCotisation/Affilie?idAffilie={id} - Tarifs applicables à l'affilié
  static Future<ApiResponse<List<dynamic>>> getTarifCotisationByAffilie(
    int affilieId,
  ) async {
    return _get<List<dynamic>>(
      '/api/TarifCotisation/Affilie',
      queryParams: {'idAffilie': affilieId.toString()},
    );
  }

  /// GET /api/TarifCotisation/{id}/montant-total?nombreDependants={n}
  static Future<ApiResponse<Map<String, dynamic>>> getTarifCotisationMontantTotal(
    int tarifId, {
    int nombreDependants = 0,
  }) async {
    return _get<Map<String, dynamic>>(
      '/api/TarifCotisation/$tarifId/montant-total?nombreDependants=$nombreDependants',
    );
  }

  /// GET /api/collecte - Liste de toutes les collectes
  static Future<ApiResponse<List<dynamic>>> getCollectes() async {
    return _get<List<dynamic>>('/api/collecte');
  }

  /// GET /api/collecte/{id} - Collecte spécifique
  static Future<ApiResponse<Map<String, dynamic>>> getCollecte(int id) async {
    return _get<Map<String, dynamic>>('/api/collecte/$id');
  }

  /// GET /api/Collecte/{id} — id numérique ou GUID (suivi paiement FlexPay)
  static Future<ApiResponse<Map<String, dynamic>>> getCollecteByKey(
    String id,
  ) async {
    final primary = await _get<Map<String, dynamic>>('/api/Collecte/$id');
    if (primary.success) return primary;
    return _get<Map<String, dynamic>>('/api/collecte/$id');
  }

  /// GET /api/FlexPay/verifier/{orderNumber} — statut paiement (polling).
  /// Endpoint anonymisable (inscription publique + agent connecté).
  static Future<ApiResponse<FlexPayVerifierResult>> verifyFlexPayPayment(
    String orderNumber,
  ) async {
    const context = 'FlexPay/verifier';
    final trimmed = orderNumber.trim();
    if (trimmed.isEmpty) {
      return ApiResponse.error('Numéro de commande FlexPay manquant');
    }

    final endpoint = '/api/FlexPay/verifier/$trimmed';
    try {
      ApiErrorHelper.logRequest(
        context,
        {'orderNumber': trimmed},
        endpoint: endpoint,
        method: 'GET',
      );

      // Toujours sans forcer le Bearer : inscription publique sans token.
      // Si un JWT est présent (agent), on l'envoie aussi.
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: isAuthenticated
            ? ApiConfig.authHeaders(_token!)
            : ApiConfig.headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ApiErrorHelper.logHttpSuccess(
          context,
          statusCode: response.statusCode,
          body: response.body,
          endpoint: endpoint,
        );
        final decoded = jsonDecode(response.body);
        Map<String, dynamic>? payload;
        if (decoded is Map<String, dynamic>) {
          payload = decoded.containsKey('success') ||
                  decoded.containsKey('alreadyProcessed')
              ? decoded
              : (decoded['data'] is Map
                  ? Map<String, dynamic>.from(decoded['data'] as Map)
                  : decoded);
        }
        if (payload == null) {
          return ApiResponse.error(
            'Format de réponse invalide',
            statusCode: response.statusCode,
          );
        }
        return ApiResponse.success(
          FlexPayVerifierResult.fromJson(payload),
          statusCode: response.statusCode,
        );
      }

      return _errorResponse<FlexPayVerifierResult>(
        response,
        context: context,
      );
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/Collecte/by-agent/{agentId} — Historique des collectes d'un agent
  static Future<ApiResponse<List<dynamic>>> getCollecteByAgent(
    int agentId,
  ) async {
    return _get<List<dynamic>>('/api/Collecte/by-agent/$agentId');
  }

  /// GET /api/Collecte/by-type/{typeCollecte} — FRAIS | SOUSCRIPTION | COTISATION
  static Future<ApiResponse<List<dynamic>>> getCollecteByType(
    String typeCollecte,
  ) async {
    final normalized = typeCollecte.trim().toUpperCase();
    return _get<List<dynamic>>('/api/Collecte/by-type/$normalized');
  }

  static List<AffiliePaiementHistoriqueModel> parseCollecteHistoriqueList(
    dynamic data,
  ) {
    final rows = data is List
        ? data
        : PaginatedResponseHelper.extractRows(data);
    return rows
        .whereType<Map>()
        .map(
          (item) => AffiliePaiementHistoriqueModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  /// POST /api/Collecte - Créer une collecte
  ///
  /// Pour `typeCollecte` = Souscription, [souscriptionPrestationId] correspond à
  /// l'`id` de l'enregistrement **SouscriptionPrestation** (pas `prestationId`).
  static Future<ApiResponse<Map<String, dynamic>>> createCollecte({
    required String typeCollecte,
    required int affilieId,
    required int agentId,
    required double montant,
    required int mois,
    required int annee,
    required String referencePaiement,
    required String modePaiement,
    String? operateur,
    required String statutPaiement,
    int? subscriptionPrestationId,
    int? souscriptionPrestationId,
    int? prestationId,
    int? fraisId,
    int? cotisationAffilieId,
    required double montantRecu,
    required double montantAttendu,
    required int deviseId,
    String? observation,
    String? phone,
    bool statut = true,
  }) async {
    final normalizedType = typeCollecte.trim().toLowerCase();
    final isFrais = normalizedType == 'frais';
    final isSouscription = normalizedType == 'souscription';
    final isCotisation = normalizedType == 'cotisation';

    final resolvedSouscriptionPrestationId = isSouscription
        ? () {
            final explicit =
                souscriptionPrestationId ?? subscriptionPrestationId;
            if (explicit != null && explicit > 0) return explicit;
            return null;
          }()
        : null;

    int? resolvedFraisId;
    if (isFrais && fraisId != null && fraisId > 0) {
      resolvedFraisId = fraisId;
    }

    int? resolvedCotisationId;
    if (isCotisation &&
        cotisationAffilieId != null &&
        cotisationAffilieId > 0) {
      resolvedCotisationId = cotisationAffilieId;
    }

    final body = <String, dynamic>{
      'typeCollecte': typeCollecte,
      'affilieId': affilieId,
      'agentId': agentId,
      'montant': montant,
      'mois': mois,
      'annee': annee,
      'referencePaiement': _nullableTrimmed(referencePaiement),
      'modePaiement': modePaiement,
      'statutPaiement': statutPaiement,
      'montantRecu': montantRecu,
      'montantAttendu': montantAttendu,
      'deviseId': deviseId,
      'statut': statut,
      if (resolvedFraisId != null) 'fraisId': resolvedFraisId,
      if (resolvedCotisationId != null) ...{
        'cotisationAffilieId': resolvedCotisationId,
        'tarifCotisationId': resolvedCotisationId,
      },
      if (isSouscription &&
          resolvedSouscriptionPrestationId != null &&
          resolvedSouscriptionPrestationId > 0)
        'souscriptionPrestationId': resolvedSouscriptionPrestationId,
      if (operateur != null && operateur.isNotEmpty) 'operateur': operateur,
      if (observation != null && observation.isNotEmpty)
        'observation': observation,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    };

    return _post<Map<String, dynamic>>(
      '/api/collecte',
      body,
      logContext: 'Collecte/create',
    );
  }

  /// POST /api/Collecte/with-paiement-electronique — Mobile Money / Carte (FlexPay)
  static Future<ApiResponse<AdhesionElectronicPaymentResponse>>
      createCollecteWithPaiementElectronique({
    required Map<String, dynamic> collecte,
    required String modePaiement,
    required String telephonePaiement,
    required int devisePaiementId,
  }) async {
    const context = 'Collecte/with-paiement-electronique';
    try {
      final body = jsonEncode({
        'collecte': collecte,
        'modePaiement': modePaiement,
        'telephonePaiement': telephonePaiement,
        'devisePaiementId': devisePaiementId,
      });
      ApiErrorHelper.logRequest(
        context,
        {
          'modePaiement': modePaiement,
          'telephonePaiement': telephonePaiement,
          'devisePaiementId': devisePaiementId,
          'typeCollecte': collecte['typeCollecte'],
        },
        endpoint: '/api/Collecte/with-paiement-electronique',
      );

      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/Collecte/with-paiement-electronique',
        ),
        headers: isAuthenticated
            ? ApiConfig.authHeaders(_token!)
            : ApiConfig.headers,
        body: body,
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        ApiErrorHelper.logHttpSuccess(
          context,
          statusCode: response.statusCode,
          body: response.body,
          endpoint: '/api/Collecte/with-paiement-electronique',
        );
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final payload = data.containsKey('idCollecteEnAttente') ||
                  data.containsKey('flexPayAccepted')
              ? data
              : (data['data'] is Map<String, dynamic>
                  ? data['data'] as Map<String, dynamic>
                  : data);
          return ApiResponse.success(
            AdhesionElectronicPaymentResponse.fromJson(payload),
            statusCode: response.statusCode,
          );
        }
        return ApiResponse.error(
          'Format de réponse invalide',
          statusCode: response.statusCode,
        );
      }
      return _errorResponse<AdhesionElectronicPaymentResponse>(
        response,
        context: context,
      );
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// PUT /api/collecte/{id} - Mettre à jour une collecte
  static Future<ApiResponse<Map<String, dynamic>>> updateCollecte(
    int id, {
    String? referencePaiement,
    String? modePaiement,
    String? operateur,
    String? statutPaiement,
    double? montantRecu,
    double? montantAttendu,
    DateTime? dateCollecte,
    String? observation,
  }) async {
    return _put<Map<String, dynamic>>('/api/collecte/$id', {
      if (referencePaiement != null) 'referencePaiement': referencePaiement,
      if (modePaiement != null) 'modePaiement': modePaiement,
      if (operateur != null) 'operateur': operateur,
      if (statutPaiement != null) 'statutPaiement': statutPaiement,
      if (montantRecu != null) 'montantRecu': montantRecu,
      if (montantAttendu != null) 'montantAttendu': montantAttendu,
      if (dateCollecte != null) 'dateCollecte': dateCollecte.toIso8601String(),
      if (observation != null) 'observation': observation,
    });
  }

  /// DELETE /api/collecte/{id} - Supprimer une collecte
  static Future<ApiResponse<void>> deleteCollecte(int id) async {
    return _delete('/api/collecte/$id');
  }

  // ============================================
  // DEVISES
  // ============================================

  /// GET /api/Devise — Liste paginée des devises (retourne la liste `data`).
  static Future<ApiResponse<List<dynamic>>> getDevises({
    int pageSize = 50,
    String? search,
    String? sortBy,
    String? sortDirection,
  }) async {
    const context = 'Devise';
    try {
      final allRows = <dynamic>[];
      var page = 1;
      var hasNext = true;

      while (hasNext) {
        final queryParams = <String, String>{
          'Page': page.toString(),
          'PageSize': pageSize.toString(),
          if (sortBy != null && sortBy.isNotEmpty) 'SortBy': sortBy,
          if (sortDirection != null && sortDirection.isNotEmpty)
            'SortDirection': sortDirection,
          if (search != null && search.isNotEmpty) 'Search': search,
        };
        final queryString = Uri(queryParameters: queryParams).query;
        final response = await _get<Map<String, dynamic>>(
          '/api/Devise?$queryString',
        );

        if (!response.success || response.data == null) {
          if (allRows.isEmpty && page == 1) {
            return _get<List<dynamic>>('/api/devise');
          }
          break;
        }

        final payload = response.data!;
        allRows.addAll(PaginatedResponseHelper.extractRows(payload));
        hasNext = PaginatedResponseHelper.extractHasNext(payload);
        page++;
        if (page > 50) break;
      }

      return ApiResponse.success(Devise.sortRowsByPriority(allRows));
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/devise/{id} - Devise spécifique
  static Future<ApiResponse<Map<String, dynamic>>> getDevise(int id) async {
    return _get<Map<String, dynamic>>('/api/Devise/$id');
  }

  /// GET /api/Prestation - Liste des prestations avec paramètres
  static Future<ApiResponse<Map<String, dynamic>>> getPrestations({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? sortBy,
    String? sortDirection,
  }) async {
    final queryParams = <String, String>{
      'Page': page.toString(),
      'pageNumber': page.toString(),
      'PageSize': pageSize.toString(),
      'pageSize': pageSize.toString(),
      if (sortBy != null && sortBy.isNotEmpty) 'SortBy': sortBy,
      if (sortDirection != null && sortDirection.isNotEmpty) 'SortDirection': sortDirection,
      if (search != null && search.isNotEmpty) 'Search': search,
    };

    final queryString = Uri(queryParameters: queryParams).query;
    return _get<Map<String, dynamic>>('/api/Prestation?$queryString');
  }

  /// POST /api/devise - Créer une devise
  static Future<ApiResponse<Map<String, dynamic>>> createDevise({
    required String nom,
    required String code,
    required String symbole,
    required double tauxChange,
    bool statut = true,
  }) async {
    return _post<Map<String, dynamic>>('/api/devise', {
      'nom': nom,
      'code': code,
      'symbole': symbole,
      'tauxChange': tauxChange,
      'statut': statut,
    });
  }

  /// PUT /api/devise/{id} - Mettre à jour une devise
  static Future<ApiResponse<Map<String, dynamic>>> updateDevise(
    int id, {
    String? nom,
    String? code,
    String? symbole,
    double? tauxChange,
    bool? statut,
  }) async {
    return _put<Map<String, dynamic>>('/api/devise/$id', {
      if (nom != null) 'nom': nom,
      if (code != null) 'code': code,
      if (symbole != null) 'symbole': symbole,
      if (tauxChange != null) 'tauxChange': tauxChange,
      if (statut != null) 'statut': statut,
    });
  }

  /// DELETE /api/devise/{id} - Supprimer une devise
  static Future<ApiResponse<void>> deleteDevise(int id) async {
    return _delete('/api/devise/$id');
  }

  // ============================================
  // PRESTATIONS
  // ============================================

  /// GET /api/prestation/{id} - Prestation spécifique
  static Future<ApiResponse<Map<String, dynamic>>> getPrestation(int id) async {
    return _get<Map<String, dynamic>>('/api/prestation/$id');
  }

  /// POST /api/prestation - Créer une prestation
  static Future<ApiResponse<Map<String, dynamic>>> createPrestation({
    required String nom,
    required String description,
    required double montant,
    required int categoriePrestationId,
    bool statut = true,
  }) async {
    return _post<Map<String, dynamic>>('/api/prestation', {
      'nom': nom,
      'description': description,
      'montant': montant,
      'categoriePrestationId': categoriePrestationId,
      'statut': statut,
    });
  }

  /// PUT /api/prestation/{id} - Mettre à jour une prestation
  static Future<ApiResponse<Map<String, dynamic>>> updatePrestation(
    int id, {
    String? nom,
    String? description,
    double? montant,
    int? categoriePrestationId,
    bool? statut,
  }) async {
    return _put<Map<String, dynamic>>('/api/prestation/$id', {
      if (nom != null) 'nom': nom,
      if (description != null) 'description': description,
      if (montant != null) 'montant': montant,
      if (categoriePrestationId != null)
        'categoriePrestationId': categoriePrestationId,
      if (statut != null) 'statut': statut,
    });
  }

  /// DELETE /api/prestation/{id} - Supprimer une prestation
  static Future<ApiResponse<void>> deletePrestation(int id) async {
    return _delete('/api/prestation/$id');
  }

  // ============================================
  // CATÉGORIES
  // ============================================

  /// GET /api/categorieadhesion - Catégories d'adhésions
  static Future<ApiResponse<List<dynamic>>> getCategorieAdhesions() async {
    return _get<List<dynamic>>('/api/categorieadhesion');
  }

  /// GET /api/categorieagent - Catégories d'agents
  static Future<ApiResponse<List<dynamic>>> getCategorieAgents() async {
    return _get<List<dynamic>>('/api/categorieagent');
  }

  /// GET /api/categorieprestation - Catégories de prestations
  static Future<ApiResponse<List<dynamic>>> getCategoriePrestations() async {
    return _get<List<dynamic>>('/api/categorieprestation');
  }

  /// GET /api/typeadhesion - Types d'adhésions
  static Future<ApiResponse<List<dynamic>>> getTypeAdhesions() async {
    return _get<List<dynamic>>('/api/typeadhesion');
  }

  // ============================================
  // UTILISATEURS
  // ============================================

  /// GET /api/utilisateur - Liste de tous les utilisateurs
  static Future<ApiResponse<List<dynamic>>> getUtilisateurs() async {
    return _get<List<dynamic>>('/api/utilisateur');
  }

  /// POST /api/utilisateur - Créer un utilisateur
  static Future<ApiResponse<Map<String, dynamic>>> createUtilisateur({
    required String nomUtilisateur,
    required String motDePasse,
    required int roleId,
  }) async {
    return _post<Map<String, dynamic>>('/api/utilisateur', {
      'nomUtilisateur': nomUtilisateur,
      'motDePasse': motDePasse,
      'roleId': roleId,
    });
  }

  /// GET /api/Utilisateur/{id} - Détail utilisateur
  static Future<ApiResponse<Map<String, dynamic>>> getUtilisateurById(
    int id,
  ) async {
    return _get<Map<String, dynamic>>('/api/Utilisateur/$id');
  }

  /// PUT /api/Utilisateur/{id} - Mise à jour utilisateur
  static Future<ApiResponse<Map<String, dynamic>>> updateUtilisateur({
    required int id,
    required String nomUtilisateur,
    required String emailUtilisateur,
    required String phoneUtilisateur,
    required bool statut,
    required int roleId,
    int? agentId,
    int? affilieId,
  }) async {
    return _put<Map<String, dynamic>>('/api/Utilisateur/$id', {
      'nomUtilisateur': nomUtilisateur,
      'emailUtilisateur': emailUtilisateur,
      'phoneUtilisateur': phoneUtilisateur,
      'statut': statut,
      'roleId': roleId,
      'agentId': agentId ?? 0,
      'affilieId': affilieId ?? 0,
    });
  }

  /// PUT /api/Utilisateur/{id}/roles/{roleId}/primary - Définir le rôle principal
  static Future<ApiResponse<Map<String, dynamic>>> setUtilisateurPrimaryRole({
    required int id,
    required int roleId,
  }) async {
    return _put<Map<String, dynamic>>(
      '/api/Utilisateur/$id/roles/$roleId/primary',
      {},
    );
  }

  // ============================================
  // RÔLES ET PERMISSIONS
  // ============================================

  /// GET /api/role - Liste de tous les rôles
  static Future<ApiResponse<List<dynamic>>> getRoles() async {
    return _get<List<dynamic>>('/api/role');
  }

  /// GET /api/permission - Liste de toutes les permissions
  static Future<ApiResponse<List<dynamic>>> getPermissions() async {
    return _get<List<dynamic>>('/api/permission');
  }

  // ============================================
  // MÉTHODES PRIVÉES (HTTP)
  // ============================================

  static Future<http.Response> _httpGet(
    Uri uri, {
    required String context,
    int maxAttempts = 3,
  }) async {
    Object? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        if (kDebugMode) {
          debugPrint('[API] GET $context (tentative $attempt/$maxAttempts)');
        }
        return await http
            .get(
              uri,
              headers: isAuthenticated
                  ? ApiConfig.authHeaders(_token!)
                  : ApiConfig.headers,
            )
            .timeout(const Duration(seconds: 45));
      } catch (e, stackTrace) {
        lastError = e;
        if (kDebugMode && !ApiErrorHelper.isRetryableNetworkError(e)) {
          ApiErrorHelper.logException(context, e, stackTrace);
        }
        if (ApiErrorHelper.isRetryableNetworkError(e) && attempt < maxAttempts) {
          await Future<void>.delayed(Duration(milliseconds: 600 * attempt));
          continue;
        }
        break;
      }
    }

    throw lastError ?? Exception('Requête GET échouée');
  }

  static Future<ApiResponse<T>> _get<T>(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      Uri uri;
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = Uri.parse('${ApiConfig.baseUrl}$endpoint').replace(queryParameters: queryParams);
      } else {
        uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      }
      
      if (kDebugMode) {
        debugPrint('[API] GET $endpoint');
      }

      final response = await _withAuthRetry(
        () => http.get(
          uri,
          headers: isAuthenticated
              ? ApiConfig.authHeaders(_token!)
              : ApiConfig.headers,
        ),
      );

      if (kDebugMode && response.statusCode >= 400) {
        ApiErrorHelper.logHttpFailure(
          'GET $endpoint',
          statusCode: response.statusCode,
          body: response.body,
        );
      }

      return _handleResponse<T>(response);
    } catch (e) {
      return _errorFromException(e, StackTrace.current);
    }
  }

  static Future<ApiResponse<T>> _post<T>(
    String endpoint,
    Map<String, dynamic> body, {
    String? logContext,
  }) async {
    final context = logContext ?? 'POST $endpoint';
    try {
      if (kDebugMode) {
        ApiErrorHelper.logRequest(context, body, endpoint: endpoint);
      }

      final response = await _withAuthRetry(
        () => http.post(
          Uri.parse('${ApiConfig.baseUrl}$endpoint'),
          headers: isAuthenticated
              ? ApiConfig.authHeaders(_token!)
              : ApiConfig.headers,
          body: jsonEncode(body),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _handleResponse<T>(response);
      }
      return _errorResponse<T>(
        response,
        context: context,
        requestBody: body,
      );
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  static Future<ApiResponse<T>> _put<T>(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _withAuthRetry(
        () => http.put(
          Uri.parse('${ApiConfig.baseUrl}$endpoint'),
          headers: isAuthenticated
              ? ApiConfig.authHeaders(_token!)
              : ApiConfig.headers,
          body: jsonEncode(body),
        ),
      );

      return _handleResponse<T>(response);
    } catch (e) {
      return _errorFromException(e, StackTrace.current);
    }
  }

  static Future<ApiResponse<void>> _delete(String endpoint) async {
    try {
      final response = await _withAuthRetry(
        () => http.delete(
          Uri.parse('${ApiConfig.baseUrl}$endpoint'),
          headers: isAuthenticated
              ? ApiConfig.authHeaders(_token!)
              : ApiConfig.headers,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse.success(null, statusCode: response.statusCode);
      } else {
        return _errorResponse(response);
      }
    } catch (e) {
      return _errorFromException(e, StackTrace.current);
    }
  }

  static ApiResponse<T> _handleResponse<T>(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);

      // Convertir les données JSON en objet du type approprié
      T? parsedData;
      if (T == WalletVirtuelAgentModel && data is Map<String, dynamic>) {
        parsedData = WalletVirtuelAgentModel.fromJson(data) as T;
      } else if (T == Map<String, dynamic>) {
        if (data is List) {
          parsedData = <String, dynamic>{'data': data} as T;
        } else {
          parsedData = data as T;
        }
      } else if (T.toString() == 'List<dynamic>' &&
          data is Map<String, dynamic> &&
          data.containsKey('data')) {
        // Gérer les réponses paginées: { data: [...], currentPage: 1, ... }
        parsedData = data['data'] as T;
      } else if (T.toString() == 'List<dynamic>' && data is List) {
        // Gérer les réponses listes directes
        parsedData = data as T;
      } else {
        parsedData = data as T;
      }

      if (parsedData == null) {
        return ApiResponse.error(
          'Erreur de parsing des données',
          statusCode: response.statusCode,
        );
      }

      return ApiResponse.success(parsedData, statusCode: response.statusCode);
    } else if (response.statusCode == 401) {
      _token = null;
      return ApiResponse.error('Non authentifié', statusCode: 401);
    } else if (response.statusCode == 403) {
      return ApiResponse.error('Non autorisé', statusCode: 403);
    } else if (response.statusCode == 404) {
      return ApiResponse.error('Ressource non trouvée', statusCode: 404);
    } else if (response.statusCode == 429) {
      return ApiResponse.error(
        'Trop de requêtes. Veuillez patienter.',
        statusCode: 429,
      );
    } else {
      return _errorResponse<T>(response);
    }
  }

  static ApiResponse<T> _errorResponse<T>(
    http.Response response, {
    String? context,
    Map<String, dynamic>? requestBody,
  }) {
    final detail = _parseErrorDetail(response);
    ApiErrorHelper.logHttpFailure(
      context ?? response.request?.url.path ?? 'API',
      statusCode: response.statusCode,
      detail: detail,
      body: response.body,
      request: requestBody,
    );
    final message = ApiErrorHelper.messageForApiFailure(
      statusCode: response.statusCode,
      serverDetail: detail,
    );
    return ApiResponse.error(
      message,
      statusCode: response.statusCode,
    );
  }

  static ApiResponse<T> _errorFromException<T>(
    Object error, [
    StackTrace? stackTrace,
    String? context,
  ]) {
    final verboseStack = !ApiErrorHelper.isRetryableNetworkError(error);
    ApiErrorHelper.logException(
      context ?? 'API',
      error,
      stackTrace,
      verboseStack,
    );
    return ApiResponse.error(ApiErrorHelper.userFacingNetwork());
  }

  static String? _nullableTrimmed(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _formatValidationErrors(dynamic errors) {
    if (errors is! Map || errors.isEmpty) return null;

    const fieldLabels = {
      'EmailAffilie': 'E-mail',
      'emailAffilie': 'E-mail',
      'Telephone': 'Téléphone',
      'telephone': 'Téléphone',
      'Nom': 'Nom',
      'Prenom': 'Prénom',
      'DateNaissance': 'Date de naissance',
    };

    final parts = <String>[];
    errors.forEach((key, value) {
      final label = fieldLabels[key.toString()] ?? key.toString();
      if (value is List && value.isNotEmpty) {
        parts.add('$label : ${value.first}');
      } else if (value != null) {
        parts.add('$label : $value');
      }
    });
    return parts.isEmpty ? null : parts.join('\n');
  }

  static String _parseErrorDetail(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) {
      return 'Erreur serveur (${response.statusCode})';
    }
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        final validationMessage = _formatValidationErrors(
          data['errors'] ?? data['Errors'],
        );
        if (validationMessage != null) return validationMessage;

        final detail = data['detail'] ?? data['Detail'];
        if (detail is String && detail.isNotEmpty) return detail;
        final title = data['title'] ?? data['Title'];
        if (title is String && title.isNotEmpty) {
          return title;
        }
        final nestedValidation =
            ApiErrorHelper.validationMessageFromBody(body);
        if (nestedValidation != null && nestedValidation.isNotEmpty) {
          return nestedValidation;
        }

        final message = data['message'] ?? data['Message'];
        if (message is String && message.isNotEmpty) return message;
        final errorField = data['error'] ?? data['Error'];
        if (errorField is String && errorField.isNotEmpty) return errorField;
      }
      return body.length > 300 ? '${body.substring(0, 300)}...' : body;
    } catch (_) {
      return body.length > 300 ? '${body.substring(0, 300)}...' : body;
    }
  }

  // ============================================
  // MODULE RETRAIT AGENT - Mars 2026
  // ============================================

  /// GET /api/retraitagent - Liste des demandes de retrait
  static Future<ApiResponse<List<dynamic>>> getDemandesRetraitAgent() async {
    return _get<List<dynamic>>('/api/retraitagent');
  }

  /// GET /api/RetraitAgent/by-agent/{agentId} - Historique des retraits d'un agent
  static Future<ApiResponse<List<dynamic>>> getRetraitAgentByAgent(
    int agentId,
  ) async {
    return _get<List<dynamic>>('/api/RetraitAgent/by-agent/$agentId');
  }

  static List<DemandeRetraitAgentModel> parseRetraitAgentList(dynamic data) {
    final rows = data is List
        ? data
        : PaginatedResponseHelper.extractRows(data);
    return rows
        .whereType<Map>()
        .map(
          (item) => DemandeRetraitAgentModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  static Future<ApiResponse<List<DemandeRetraitAgentModel>>>
      _fetchRetraitAgentListe(String endpoint) async {
    final context = 'GET $endpoint';
    try {
      final response = await _httpGet(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        context: context,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return ApiResponse.success(parseRetraitAgentList(decoded));
      }
      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/RetraitAgent/en-attente
  static Future<ApiResponse<List<DemandeRetraitAgentModel>>>
      getRetraitsEnAttente() =>
          _fetchRetraitAgentListe('/api/RetraitAgent/en-attente');

  /// GET /api/RetraitAgent/validees
  static Future<ApiResponse<List<DemandeRetraitAgentModel>>>
      getRetraitsValidees() =>
          _fetchRetraitAgentListe('/api/RetraitAgent/validees');

  /// GET /api/RetraitAgent/traitees
  static Future<ApiResponse<List<DemandeRetraitAgentModel>>>
      getRetraitsTraitees() =>
          _fetchRetraitAgentListe('/api/RetraitAgent/traitees');

  /// POST /api/RetraitAgent/verifier-solde
  static Future<ApiResponse<RetraitAgentVerifierSolde>>
      verifierSoldeRetraitAgent({
    required int agentId,
    required double montantDemande,
    int? deviseId,
  }) async {
    const context = 'RetraitAgent/verifier-solde';
    final body = <String, dynamic>{
      'agentId': agentId,
      'montantDemande': montantDemande,
      if (deviseId != null) 'deviseId': deviseId,
    };

    try {
      if (kDebugMode) {
        ApiErrorHelper.logRequest(context, body);
      }

      final response = await _withAuthRetry(
        () => http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/RetraitAgent/verifier-solde'),
          headers: isAuthenticated
              ? ApiConfig.authHeaders(_token!)
              : ApiConfig.headers,
          body: jsonEncode(body),
        ),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final map = unwrapRetraitVerifierSoldeJson(decoded);
        if (map == null) {
          return ApiResponse.error(
            'Réponse vérification solde invalide',
            statusCode: response.statusCode,
          );
        }
        return ApiResponse.success(RetraitAgentVerifierSolde.fromJson(map));
      }
      return _errorResponse(
        response,
        context: context,
        requestBody: body,
      );
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/retraitagent/{id} - Détail d'une demande de retrait
  static Future<ApiResponse<Map<String, dynamic>>> getDemandeRetraitAgent(
    int id,
  ) async {
    return _get<Map<String, dynamic>>('/api/retraitagent/$id');
  }

  /// POST /api/retraitagent - Créer une demande de retrait
  static Future<ApiResponse<Map<String, dynamic>>> createDemandeRetraitAgent({
    required int agentId,
    required double montant,
    required String typeRetrait,
    required String motifRetrait,
    int? deviseId,
  }) async {
    return _post<Map<String, dynamic>>('/api/retraitAgent', {
      'agentId': agentId,
      'montantDemande': montant,
      'typeRetrait': typeRetrait,
      'motifRetrait': motifRetrait,
      if (deviseId != null) 'deviseId': deviseId,
    });
  }

  static Map<String, dynamic> _dependantBody({
    required String nom,
    required String lienParente,
    required int affilieId,
    required String dateNaissance,
    String? adresse,
    String? certificatScolariteBase64,
    String? certificatScolariteContentType,
  }) {
    return {
      'nom': nom,
      'lienParente': lienParente,
      'affilieId': affilieId,
      'dateNaissance': dateNaissance,
      if (adresse != null && adresse.isNotEmpty) 'adresse': adresse,
      if (certificatScolariteBase64 != null &&
          certificatScolariteBase64.isNotEmpty)
        'certificatScolariteBase64': certificatScolariteBase64,
      if (certificatScolariteContentType != null &&
          certificatScolariteContentType.isNotEmpty)
        'certificatScolariteContentType': certificatScolariteContentType,
    };
  }

  /// POST /api/Dependant - Créer un dépendant
  static Future<ApiResponse<Map<String, dynamic>>> createDependant({
    required String nom,
    required String lienParente,
    required int affilieId,
    required String dateNaissance,
    String? adresse,
    String? certificatScolariteBase64,
    String? certificatScolariteContentType,
  }) async {
    return _post<Map<String, dynamic>>(
      '/api/Dependant',
      _dependantBody(
        nom: nom,
        lienParente: lienParente,
        affilieId: affilieId,
        dateNaissance: dateNaissance,
        adresse: adresse,
        certificatScolariteBase64: certificatScolariteBase64,
        certificatScolariteContentType: certificatScolariteContentType,
      ),
    );
  }

  /// PUT /api/Dependant/{id} - Modifier un dépendant
  static Future<ApiResponse<Map<String, dynamic>>> updateDependant({
    required int id,
    required String nom,
    required String lienParente,
    required int affilieId,
    required String dateNaissance,
    String? adresse,
    String? certificatScolariteBase64,
    String? certificatScolariteContentType,
  }) async {
    return _put<Map<String, dynamic>>(
      '/api/Dependant/$id',
      _dependantBody(
        nom: nom,
        lienParente: lienParente,
        affilieId: affilieId,
        dateNaissance: dateNaissance,
        adresse: adresse,
        certificatScolariteBase64: certificatScolariteBase64,
        certificatScolariteContentType: certificatScolariteContentType,
      ),
    );
  }

  /// DELETE /api/Dependant/{id}
  static Future<ApiResponse<void>> deleteDependant(int id) async {
    return _delete('/api/Dependant/$id');
  }

  /// DELETE /api/Dependant/{id}/certificat-scolarite
  static Future<ApiResponse<void>> deleteDependantCertificatScolarite(
    int id,
  ) async {
    return _delete('/api/Dependant/$id/certificat-scolarite');
  }

  /// GET /api/Dependant/by-affilie/{affilieId} - Liste paginée des dépendants
  static Future<ApiResponse<Map<String, dynamic>>> getDependantsByAffilie(
    int affilieId, {
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    String? sortDirection,
    String? search,
    String? filters,
  }) async {
    final queryParams = <String, String>{
      'affilieId': affilieId.toString(),
      'affilielId': affilieId.toString(),
      'Page': page.toString(),
      'pageNumber': page.toString(),
      'PageSize': pageSize.toString(),
      'pageSize': pageSize.toString(),
      if (sortBy != null && sortBy.isNotEmpty) 'SortBy': sortBy,
      if (sortDirection != null && sortDirection.isNotEmpty)
        'SortDirection': sortDirection,
      if (search != null && search.isNotEmpty) 'Search': search,
      if (filters != null && filters.isNotEmpty) 'Filters': filters,
    };
    return _get<Map<String, dynamic>>(
      '/api/Dependant/by-affilie/$affilieId',
      queryParams: queryParams,
    );
  }

  /// GET /api/SouscriptionPrestation/by-affilie/{affilieId} - Liste paginée
  static Future<ApiResponse<List<dynamic>>> getSouscriptionsByAffilie(
    int affilieId, {
    int page = 1,
    int pageSize = 100,
    String? sortBy,
    String? sortDirection,
  }) async {
    return _get<List<dynamic>>(
      '/api/SouscriptionPrestation/by-affilie/$affilieId',
      queryParams: {
        'Page': page.toString(),
        'pageNumber': page.toString(),
        'PageSize': pageSize.toString(),
        'pageSize': pageSize.toString(),
        if (sortBy != null && sortBy.isNotEmpty) 'SortBy': sortBy,
        if (sortDirection != null && sortDirection.isNotEmpty)
          'SortDirection': sortDirection,
      },
    );
  }

  /// Liste typée des souscriptions prestation d'un affilié.
  static Future<ApiResponse<List<SouscriptionPrestationModel>>>
  getSouscriptionsPrestationByAffilie(
    int affilieId, {
    int pageSize = 100,
  }) async {
    final response = await getSouscriptionsByAffilie(
      affilieId,
      pageSize: pageSize,
      sortBy: 'dateSouscription',
      sortDirection: 'desc',
    );
    if (!response.success || response.data == null) {
      return ApiResponse(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final rows = response.data is List
        ? response.data!
        : PaginatedResponseHelper.extractRows(response.data);

    final parsed = <SouscriptionPrestationModel>[];
    for (final item in rows) {
      if (item is! Map) continue;
      try {
        final map = item is Map<String, dynamic>
            ? item
            : Map<String, dynamic>.from(item);
        parsed.add(SouscriptionPrestationModel.fromJson(map));
      } catch (e, stackTrace) {
        if (kDebugMode) {
          ApiErrorHelper.logException(
            'SouscriptionPrestation/fromJson',
            e,
            stackTrace,
          );
        }
      }
    }

    return ApiResponse.success(parsed, statusCode: response.statusCode);
  }

  /// GET /api/SouscriptionsArrierees/by-affilie/{affilieId} - Liste des arriérés de paiement d'un adhérent
  static Future<ApiResponse<List<dynamic>>> getSouscriptionsArriereesByAffilie(int affilieId) async {
    return _get<List<dynamic>>('/api/SouscriptionsArrierees/by-affilie/$affilieId');
  }

  /// GET /api/Collecte/by-affilie/{affilieId}/paginated - Liste des collectes paginées d'un adhérent
  static Future<ApiResponse<Map<String, dynamic>>> getCollecteByAffiliePaginated({
    required int affilieId,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    String? sortDirection,
    String? search,
    String? filters,
  }) async {
    final queryParams = <String, String>{
      'pageNumber': page.toString(),
      'pageSize': pageSize.toString(),
      if (sortBy != null) 'sortBy': sortBy,
      if (sortDirection != null) 'sortDirection': sortDirection,
      if (search != null) 'search': search,
      if (filters != null) 'filters': filters,
    };
    
    return _get<Map<String, dynamic>>('/api/Collecte/by-affilie/$affilieId/paginated', queryParams: queryParams);
  }

  /// POST /api/SouscriptionPrestation?affilieId= — souscription + collecte associée.
  static Future<ApiResponse<SouscriptionPrestationCreateResult>>
      createSouscriptionPrestation({
    required int affilieId,
    required SouscriptionPrestationCreateRequest request,
  }) async {
    final response = await _post<Map<String, dynamic>>(
      '/api/SouscriptionPrestation?affilieId=$affilieId',
      request.toJson(),
      logContext: 'SouscriptionPrestation/create',
    );

    if (!response.success || response.data == null) {
      return ApiResponse(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    return ApiResponse.success(
      SouscriptionPrestationCreateResult.fromJson(response.data!),
      statusCode: response.statusCode,
    );
  }

  /// POST /api/SouscriptionPrestation/paiement-electronique
  /// Nouvelle souscription payée en Mobile Money / Carte (FlexPay).
  static Future<ApiResponse<AdhesionElectronicPaymentResponse>>
      createSouscriptionPrestationPaiementElectronique(
    SouscriptionPrestationPaiementElectroniqueRequest request,
  ) async {
    const context = 'SouscriptionPrestation/paiement-electronique';
    try {
      final body = jsonEncode(request.toJson());
      ApiErrorHelper.logRequest(
        context,
        {
          'affilieId': request.affilieId,
          'modePaiement': request.modePaiement,
          'telephonePaiement': request.telephonePaiement,
          'devisePaiementId': request.devisePaiementId,
          'prestationId': request.achat.prestationId,
        },
        endpoint: '/api/SouscriptionPrestation/paiement-electronique',
      );

      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/SouscriptionPrestation/paiement-electronique',
        ),
        headers: isAuthenticated
            ? ApiConfig.authHeaders(_token!)
            : ApiConfig.headers,
        body: body,
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        ApiErrorHelper.logHttpSuccess(
          context,
          statusCode: response.statusCode,
          body: response.body,
          endpoint: '/api/SouscriptionPrestation/paiement-electronique',
        );
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final payload = data.containsKey('flexPayAccepted') ||
                  data.containsKey('paymentUrl') ||
                  data.containsKey('orderNumber')
              ? data
              : (data['data'] is Map<String, dynamic>
                  ? data['data'] as Map<String, dynamic>
                  : data);
          return ApiResponse.success(
            AdhesionElectronicPaymentResponse.fromJson(payload),
            statusCode: response.statusCode,
          );
        }
        return ApiResponse.error(
          'Format de réponse invalide',
          statusCode: response.statusCode,
        );
      }
      return _errorResponse<AdhesionElectronicPaymentResponse>(
        response,
        context: context,
      );
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/DemandeBonEnvoi/by-affilie/{affilieId}
  static Future<ApiResponse<List<DemandeBonEnvoiModel>>>
  getDemandesBonEnvoiByAffilie(int affilieId) async {
    final response = await _get<dynamic>(
      '/api/DemandeBonEnvoi/by-affilie/$affilieId',
    );
    if (!response.success) {
      return ApiResponse(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final raw = response.data;
    final List<dynamic> rows;
    if (raw is List) {
      rows = raw;
    } else if (raw is Map<String, dynamic>) {
      rows = PaginatedResponseHelper.extractRows(raw);
    } else {
      rows = const [];
    }

    final parsed = <DemandeBonEnvoiModel>[];
    for (final item in rows) {
      if (item is! Map) continue;
      try {
        final map = item is Map<String, dynamic>
            ? item
            : Map<String, dynamic>.from(item);
        parsed.add(DemandeBonEnvoiModel.fromJson(map));
      } catch (e, stackTrace) {
        ApiErrorHelper.logException('DemandeBonEnvoi/fromJson', e, stackTrace);
      }
    }

    return ApiResponse.success(parsed, statusCode: response.statusCode);
  }

  /// Vérifie l'éligibilité — GET puis POST si 405 (Method Not Allowed).
  static Future<ApiResponse<DemandeBonEligibilite>> verifierEligibiliteDemandeBon(
    int affilieId,
  ) async {
    final path = '/api/DemandeBonEnvoi/verifier-eligibilite/$affilieId';
    var response = await _get<dynamic>(path);
    if (!response.success && response.statusCode == 405) {
      response = await _post<dynamic>(path, <String, dynamic>{});
    }
    if (!response.success) {
      return ApiResponse(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }
    return ApiResponse.success(
      DemandeBonEligibilite.fromJson(response.data),
      statusCode: response.statusCode,
    );
  }

  /// POST /api/DemandeBonEnvoi
  static Future<ApiResponse<Map<String, dynamic>>> createDemandeBonEnvoi({
    required int affilieId,
    required int prestationId,
    required String typeDemande,
    required String motifDemande,
    int? agentId,
    String? observationAgent,
  }) async {
    final body = <String, dynamic>{
      'affilieId': affilieId,
      'prestationId': prestationId,
      'typeDemande': typeDemande,
      'motifDemande': motifDemande,
      if (agentId != null && agentId > 0) 'agentId': agentId,
      if (observationAgent != null && observationAgent.trim().isNotEmpty)
        'observationAgent': observationAgent.trim(),
    };
    return _post<Map<String, dynamic>>('/api/DemandeBonEnvoi', body);
  }

  /// GET /api/BonEnvoi/by-affilie/{affilieId}/paginated
  static Future<ApiResponse<Map<String, dynamic>>> getBonEnvoiByAffiliePaginated({
    required int affilieId,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    String? sortDirection,
    String? search,
    String? filters,
  }) async {
    final queryParams = <String, String>{
      'Page': page.toString(),
      'pageNumber': page.toString(),
      'PageSize': pageSize.toString(),
      'pageSize': pageSize.toString(),
      if (sortBy != null && sortBy.isNotEmpty) 'SortBy': sortBy,
      if (sortDirection != null && sortDirection.isNotEmpty)
        'SortDirection': sortDirection,
      if (search != null && search.isNotEmpty) 'Search': search,
      if (filters != null && filters.isNotEmpty) 'Filters': filters,
    };
    return _get<Map<String, dynamic>>(
      '/api/BonEnvoi/by-affilie/$affilieId/paginated',
      queryParams: queryParams,
    );
  }

  /// Liste typée des bons d'envoi paginés d'un affilié.
  static Future<ApiResponse<List<BonEnvoiModel>>> getBonEnvoiListByAffilie({
    required int affilieId,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? sortBy,
    String? sortDirection,
    String? filters,
  }) async {
    final response = await getBonEnvoiByAffiliePaginated(
      affilieId: affilieId,
      page: page,
      pageSize: pageSize,
      search: search,
      sortBy: sortBy,
      sortDirection: sortDirection,
      filters: filters,
    );
    if (!response.success || response.data == null) {
      return ApiResponse(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final payload = response.data!;
    final rows = PaginatedResponseHelper.extractRows(payload);
    final parsed = <BonEnvoiModel>[];
    for (final item in rows) {
      if (item is! Map) continue;
      try {
        final map = item is Map<String, dynamic>
            ? item
            : Map<String, dynamic>.from(item);
        parsed.add(BonEnvoiModel.fromJson(map));
      } catch (e, stackTrace) {
        ApiErrorHelper.logException('BonEnvoi/fromJson', e, stackTrace);
      }
    }

    return ApiResponse.success(parsed, statusCode: response.statusCode);
  }

  static List<DemandeBonEnvoiModel> _parseDemandeBonEnvoiList(dynamic raw) {
    final List<dynamic> rows;
    if (raw is List) {
      rows = raw;
    } else if (raw is Map<String, dynamic>) {
      rows = PaginatedResponseHelper.extractRows(raw);
    } else if (raw is Map) {
      rows = PaginatedResponseHelper.extractRows(
        Map<String, dynamic>.from(raw),
      );
    } else {
      rows = const [];
    }

    final parsed = <DemandeBonEnvoiModel>[];
    for (final item in rows) {
      if (item is! Map) continue;
      try {
        final map = item is Map<String, dynamic>
            ? item
            : Map<String, dynamic>.from(item);
        parsed.add(DemandeBonEnvoiModel.fromJson(map));
      } catch (e, stackTrace) {
        ApiErrorHelper.logException('DemandeBonEnvoi/fromJson', e, stackTrace);
      }
    }
    return parsed;
  }

  static Map<String, dynamic> _unwrapDemandeBonEnvoiMap(
    Map<String, dynamic> json,
  ) {
    final nested = json['demande'] ?? json['demandeBonEnvoi'] ?? json['data'];
    if (nested is Map) {
      return nested is Map<String, dynamic>
          ? nested
          : Map<String, dynamic>.from(nested);
    }
    return json;
  }

  /// GET /api/DemandeBonEnvoi/by-statut/{statut}/simple
  /// Fallback plural (doc legacy) : /api/DemandeBonEnvois/by-statut/{statut}/simple
  static Future<ApiResponse<List<DemandeBonEnvoiModel>>>
      getDemandesBonEnvoiByStatut(String statut) async {
    final encodedStatut = Uri.encodeComponent(statut);
    final paths = <String>[
      '/api/DemandeBonEnvoi/by-statut/$encodedStatut/simple',
      '/api/DemandeBonEnvois/by-statut/$encodedStatut/simple',
      '/api/DemandeBonEnvoi/by-statut/$encodedStatut/paginated',
      '/api/DemandeBonEnvois/by-statut/$encodedStatut/paginated',
    ];

    ApiResponse<dynamic>? lastFailure;
    for (final path in paths) {
      final response = await _get<dynamic>(path);
      if (response.success) {
        return ApiResponse.success(
          _parseDemandeBonEnvoiList(response.data),
          statusCode: response.statusCode,
        );
      }
      lastFailure = response;
      // Ne tente les fallbacks que si la ressource n'existe pas (404).
      if (response.statusCode != 404) break;
    }

    return ApiResponse(
      success: false,
      message: lastFailure?.message ??
          'Impossible de charger les demandes de bon.',
      statusCode: lastFailure?.statusCode,
    );
  }

  /// POST /api/DemandeBonEnvoi/{id}/confirmer — Crée le couple BonEnvoi + JetonMedical.
  /// Fallback legacy : POST /api/DemandeBonEnvoi/valider-et-generer
  static Future<ApiResponse<DemandeBonEnvoiModel>> confirmerDemandeBonEnvoi(
    int idDemande, {
    int? agentId,
    String? observationAgent,
  }) async {
    final body = <String, dynamic>{
      if (agentId != null && agentId > 0) 'agentId': agentId,
      if (observationAgent != null && observationAgent.trim().isNotEmpty)
        'observationAgent': observationAgent.trim(),
    };
    final response = await _post<Map<String, dynamic>>(
      '/api/DemandeBonEnvoi/$idDemande/confirmer',
      body,
      logContext: 'DemandeBonEnvoi/confirmer',
    );
    if (response.success && response.data != null) {
      return ApiResponse.success(
        DemandeBonEnvoiModel.fromJson(
          _unwrapDemandeBonEnvoiMap(response.data!),
        ),
        statusCode: response.statusCode,
      );
    }

    // Endpoint singular absent → tentative pluriel + legacy.
    if (response.statusCode == 404) {
      final plural = await _post<Map<String, dynamic>>(
        '/api/DemandeBonEnvois/$idDemande/confirmer',
        body,
        logContext: 'DemandeBonEnvois/confirmer',
      );
      if (plural.success && plural.data != null) {
        return ApiResponse.success(
          DemandeBonEnvoiModel.fromJson(
            _unwrapDemandeBonEnvoiMap(plural.data!),
          ),
          statusCode: plural.statusCode,
        );
      }
      return validerEtGenererDemandeBonEnvoi(
        idDemande: idDemande,
        agentId: agentId,
        observationAgent: observationAgent,
      );
    }

    return ApiResponse(
      success: false,
      message: response.message ??
          'Impossible de confirmer la demande (bon + jeton).',
      statusCode: response.statusCode,
    );
  }

  /// POST /api/DemandeBonEnvoi/valider-et-generer (legacy — même workflow transactionnel)
  static Future<ApiResponse<DemandeBonEnvoiModel>> validerEtGenererDemandeBonEnvoi({
    required int idDemande,
    int? agentId,
    String? observationAgent,
  }) async {
    final body = <String, dynamic>{
      'idDemande': idDemande,
      if (agentId != null && agentId > 0) 'agentId': agentId,
      if (observationAgent != null && observationAgent.trim().isNotEmpty)
        'observationAgent': observationAgent.trim(),
    };
    final response = await _post<Map<String, dynamic>>(
      '/api/DemandeBonEnvoi/valider-et-generer',
      body,
      logContext: 'DemandeBonEnvoi/valider-et-generer',
    );
    if ((!response.success || response.data == null) &&
        response.statusCode == 404) {
      final legacy = await _post<Map<String, dynamic>>(
        '/api/DemandeBonEnvois/valider-et-generer',
        body,
        logContext: 'DemandeBonEnvois/valider-et-generer',
      );
      if (legacy.success && legacy.data != null) {
        return ApiResponse.success(
          DemandeBonEnvoiModel.fromJson(
            _unwrapDemandeBonEnvoiMap(legacy.data!),
          ),
          statusCode: legacy.statusCode,
        );
      }
      return ApiResponse(
        success: false,
        message: legacy.message ??
            response.message ??
            'Impossible de valider et générer le bon + jeton.',
        statusCode: legacy.statusCode ?? response.statusCode,
      );
    }
    if (!response.success || response.data == null) {
      return ApiResponse(
        success: false,
        message: response.message ??
            'Impossible de valider et générer le bon + jeton.',
        statusCode: response.statusCode,
      );
    }
    return ApiResponse.success(
      DemandeBonEnvoiModel.fromJson(
        _unwrapDemandeBonEnvoiMap(response.data!),
      ),
      statusCode: response.statusCode,
    );
  }

  /// POST /api/BonEnvoi/scanner — Contrôle bon + jeton lié à l'hôpital
  static Future<ApiResponse<Map<String, dynamic>>> scannerBonEnvoi({
    required String qrCodePayload,
    String? numeroBon,
    int? hopitalPartenaireId,
  }) async {
    return _post<Map<String, dynamic>>(
      '/api/BonEnvoi/scanner',
      {
        'qrCodePayload': qrCodePayload,
        if (numeroBon != null && numeroBon.trim().isNotEmpty)
          'numeroBon': numeroBon.trim(),
        if (hopitalPartenaireId != null && hopitalPartenaireId > 0)
          'hopitalPartenaireId': hopitalPartenaireId,
      },
      logContext: 'BonEnvoi/scanner',
    );
  }

  /// POST /api/JetonMedical/utiliser — Utilisation jeton (bon actif lié requis)
  static Future<ApiResponse<Map<String, dynamic>>> utiliserJetonMedical({
    required int idJetonMedical,
    required String codeJeton,
    String? observation,
    int? hopitalPartenaireId,
  }) async {
    return _post<Map<String, dynamic>>(
      '/api/JetonMedical/utiliser',
      {
        'idJetonMedical': idJetonMedical,
        'codeJeton': codeJeton,
        if (observation != null && observation.trim().isNotEmpty)
          'observation': observation.trim(),
        if (hopitalPartenaireId != null && hopitalPartenaireId > 0)
          'hopitalPartenaireId': hopitalPartenaireId,
      },
      logContext: 'JetonMedical/utiliser',
    );
  }

  /// GET /api/JetonMedical/by-affilie/{affilieId}
  static Future<ApiResponse<List<JetonMedicalModel>>> getJetonsMedicauxByAffilie(
    int affilieId,
  ) async {
    final response = await _get<dynamic>(
      '/api/JetonMedical/by-affilie/$affilieId',
    );
    if (!response.success) {
      return ApiResponse(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final raw = response.data;
    final List<dynamic> rows;
    if (raw is List) {
      rows = raw;
    } else if (raw is Map<String, dynamic>) {
      rows = PaginatedResponseHelper.extractRows(raw);
    } else {
      rows = const [];
    }

    final parsed = <JetonMedicalModel>[];
    for (final item in rows) {
      if (item is! Map) continue;
      try {
        final map = item is Map<String, dynamic>
            ? item
            : Map<String, dynamic>.from(item);
        parsed.add(JetonMedicalModel.fromJson(map));
      } catch (e, stackTrace) {
        ApiErrorHelper.logException('JetonMedical/fromJson', e, stackTrace);
      }
    }

    return ApiResponse.success(parsed, statusCode: response.statusCode);
  }

  /// GET /api/arrieres-affilie/affilie/{affilieId} - Arriérés d'un affilié
  static Future<ApiResponse<List<ArriereAffilieModel>>> getArrieresAffilie(
    int affilieId,
  ) async {
    return _fetchArrieresAffilie(
      path: '/api/arrieres-affilie/affilie/$affilieId',
      context: 'arrieres-affilie/affilie/$affilieId',
    );
  }

  /// GET /api/arrieres-affilie/mes-arrieres - Arriérés de l'affilié connecté
  static Future<ApiResponse<List<ArriereAffilieModel>>> getMesArrieresAffilie() async {
    return _fetchArrieresAffilie(
      path: '/api/arrieres-affilie/mes-arrieres',
      context: 'arrieres-affilie/mes-arrieres',
    );
  }

  static Future<ApiResponse<List<ArriereAffilieModel>>> _fetchArrieresAffilie({
    required String path,
    required String context,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: isAuthenticated
            ? ApiConfig.authHeaders(_token!)
            : ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final rows = decoded is List
            ? decoded
            : PaginatedResponseHelper.extractRows(decoded);
        final parsed = <ArriereAffilieModel>[];
        for (final item in rows) {
          if (item is! Map) continue;
          try {
            final map = item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item);
            parsed.add(ArriereAffilieModel.fromJson(map));
          } catch (e, stackTrace) {
            ApiErrorHelper.logException(
              'ArriereAffilie/fromJson',
              e,
              stackTrace,
            );
          }
        }
        return ApiResponse.success(parsed, statusCode: response.statusCode);
      }

      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  // ============================================
  // PÉNALITÉS AFFILIÉ
  // ============================================

  /// GET /api/penalite-affilie/arriere/{arrieresAffilieId}
  static Future<ApiResponse<List<PenaliteAffilieModel>>> getPenalitesByArriere(
    int arrieresAffilieId,
  ) async {
    return _fetchPenalitesAffilie(
      path: '/api/penalite-affilie/arriere/$arrieresAffilieId',
      context: 'penalite-affilie/arriere/$arrieresAffilieId',
    );
  }

  /// GET /api/penalite-affilie/mes-penalites
  static Future<ApiResponse<List<PenaliteAffilieModel>>>
      getMesPenalitesAffilie() async {
    return _fetchPenalitesAffilie(
      path: '/api/penalite-affilie/mes-penalites',
      context: 'penalite-affilie/mes-penalites',
    );
  }

  static Future<ApiResponse<List<PenaliteAffilieModel>>> _fetchPenalitesAffilie({
    required String path,
    required String context,
  }) async {
    try {
      final response = await _httpGet(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        context: context,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final rows = decoded is List
            ? decoded
            : PaginatedResponseHelper.extractRows(decoded);
        final parsed = <PenaliteAffilieModel>[];
        for (final item in rows) {
          if (item is! Map) continue;
          try {
            final map = item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item);
            parsed.add(PenaliteAffilieModel.fromJson(map));
          } catch (e, stackTrace) {
            ApiErrorHelper.logException(
              'PenaliteAffilie/fromJson',
              e,
              stackTrace,
            );
          }
        }
        return ApiResponse.success(parsed, statusCode: response.statusCode);
      }

      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// POST /api/Antecedent - Créer un antécédent
  static Future<ApiResponse<Map<String, dynamic>>> createAntecedent({
    required String description,
    required int affilieId,
    required bool statut,
  }) async {
    return _post<Map<String, dynamic>>('/api/Antecedent', {
      'description': description,
      'affilieId': affilieId,
      'statut': statut,
    });
  }

  /// POST /api/RetraitAgent/valider-et-generer-jeton - Valider une demande et générer un jeton
  static Future<ApiResponse<RetraitWorkflowResultModel>>
      validerEtGenererJetonRetrait({
    required int idDemande,
    required String statutDemande,
    String? motifValidation,
    int? agentValidationId,
  }) async {
    final response = await _post<Map<String, dynamic>>(
      '/api/RetraitAgent/valider-et-generer-jeton',
      {
        'idDemande': idDemande,
        'statutDemande': statutDemande,
        'motifValidation': motifValidation ?? '',
        'agentValidationId': agentValidationId ?? 0,
      },
    );
    if (!response.success || response.data == null) {
      return ApiResponse.error(
        response.message ?? 'Échec de la validation',
        statusCode: response.statusCode,
      );
    }
    return ApiResponse.success(
      RetraitWorkflowResultModel.fromJson(response.data!),
      statusCode: response.statusCode,
    );
  }

  /// PUT /api/RetraitAgent/{id} — Rejet superviseur
  static Future<ApiResponse<Map<String, dynamic>>> putRejeterDemandeRetraitAgent({
    required int id,
    required int idDemande,
    required int agentValidationId,
    required String motifValidation,
  }) async {
    return _put<Map<String, dynamic>>('/api/RetraitAgent/$id', {
      'idDemande': idDemande,
      'statutDemande': 'REJETEE',
      'agentValidationId': agentValidationId,
      'motifValidation': motifValidation,
    });
  }

  /// POST /api/retraitagent/valider/{id} - Valider une demande de retrait
  static Future<ApiResponse<Map<String, dynamic>>> validerDemandeRetraitAgent(
    int id,
  ) async {
    return _post<Map<String, dynamic>>('/api/retraitagent/valider/$id', {});
  }

  /// POST /api/retraitagent/rejeter/{id} - Rejeter une demande de retrait
  static Future<ApiResponse<Map<String, dynamic>>> rejeterDemandeRetraitAgent(
    int id, {
    required String motif,
  }) async {
    return _post<Map<String, dynamic>>('/api/retraitagent/rejeter/$id', {
      'motif': motif,
    });
  }

  /// POST /api/RetraitAgent/utiliser-jeton - Utiliser un jeton de retrait
  static Future<ApiResponse<Map<String, dynamic>>> utiliserJetonRetraitAgent({
    required int idJeton,
    required String codeJeton,
    required int agentId,
    String? observationUtilisation,
  }) async {
    return _post<Map<String, dynamic>>(
      '/api/RetraitAgent/utiliser-jeton',
      {
        'idJeton': idJeton,
        'codeJeton': codeJeton,
        'agentId': agentId,
        'observationUtilisation': observationUtilisation ?? '',
      },
      logContext: 'RetraitAgent/utiliser-jeton',
    );
  }

  /// @deprecated Utiliser [utiliserJetonRetraitAgent]
  static Future<ApiResponse<Map<String, dynamic>>> utiliserTokenRetrait({
    required String token,
  }) async {
    return _post<Map<String, dynamic>>('/api/retraitagent/utiliser', {
      'token': token,
    });
  }

  /// GET /api/RetraitAgent/periode-courante - Période de retrait en cours
  static Future<ApiResponse<RetraitAgentPeriodeCourante>>
      getRetraitAgentPeriodeCourante() async {
    const context = 'RetraitAgent/periode-courante';
    try {
      final response = await _httpGet(
        Uri.parse('${ApiConfig.baseUrl}/api/RetraitAgent/periode-courante'),
        context: context,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final map = unwrapRetraitPeriodeJson(decoded);
        if (map == null) {
          return ApiResponse.error(
            'Réponse période de retrait invalide',
            statusCode: response.statusCode,
          );
        }
        return ApiResponse.success(RetraitAgentPeriodeCourante.fromJson(map));
      }
      return _errorResponse(response, context: context);
    } catch (e, stackTrace) {
      return _errorFromException(e, stackTrace, context);
    }
  }

  /// GET /api/retraitagent/periodes - Vérifier les périodes autorisées (legacy)
  static Future<ApiResponse<Map<String, dynamic>>>
  getPeriodesAutorisees() async {
    return _get<Map<String, dynamic>>('/api/retraitagent/periodes');
  }

  // ============================================
  // DASHBOARD AFFILIE - Mars 2026
  // ============================================

  /// GET /api/dashboardaffilie - Dashboard complet de l'affilié
  static Future<ApiResponse<Map<String, dynamic>>> getDashboardAffilie() async {
    return _get<Map<String, dynamic>>('/api/dashboardaffilie');
  }

  /// GET /api/dashboardaffilie/kpis - KPIs en temps réel
  static Future<ApiResponse<Map<String, dynamic>>>
  getKPIsDashboardAffilie() async {
    return _get<Map<String, dynamic>>('/api/dashboardaffilie/kpis');
  }

  /// GET /api/dashboardaffilie/historique-cotisations - Historique des cotisations
  static Future<ApiResponse<List<dynamic>>> getHistoriqueCotisations({
    String? periode,
  }) async {
    final queryParams = periode != null ? '?periode=$periode' : '';
    return _get<List<dynamic>>(
      '/api/dashboardaffilie/historique-cotisations$queryParams',
    );
  }

  /// GET /api/dashboardaffilie/historique-prestations - Historique des prestations
  static Future<ApiResponse<List<dynamic>>> getHistoriquePrestations({
    String? periode,
  }) async {
    final queryParams = periode != null ? '?periode=$periode' : '';
    return _get<List<dynamic>>(
      '/api/dashboardaffilie/historique-prestations$queryParams',
    );
  }

  /// GET /api/dashboardaffilie/beneficiaires - Liste des bénéficiaires
  static Future<ApiResponse<List<dynamic>>> getBeneficiaires() async {
    return _get<List<dynamic>>('/api/dashboardaffilie/beneficiaires');
  }

  /// GET /api/dashboardaffilie/plafonds - Plafonds des bénéfices
  static Future<ApiResponse<Map<String, dynamic>>> getPlafonds() async {
    return _get<Map<String, dynamic>>('/api/dashboardaffilie/plafonds');
  }

  // ============================================
  // GESTION PHOTOS DE PROFIL
  // ============================================

  /// PUT /api/agent/{id}/photo - Mettre à jour la photo d'un agent
  static Future<ApiResponse<Map<String, dynamic>>> updateAgentPhoto(
    int agentId, {
    required String photoUrl,
  }) async {
    return _put<Map<String, dynamic>>('/api/agent/$agentId', {
      'photoUrl': photoUrl,
    });
  }

  /// PUT /api/affilie/{id}/photo - Mettre à jour la photo d'un affilié
  static Future<ApiResponse<Map<String, dynamic>>> updateAffiliePhoto(
    int affilieId, {
    required String photoUrl,
  }) async {
    return _put<Map<String, dynamic>>('/api/affilie/$affilieId', {
      'photoUrl': photoUrl,
    });
  }
}
