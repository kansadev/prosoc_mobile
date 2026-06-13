// ============================================
// SERVICE D'AUTHENTIFICATION
// ============================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart';
import '../models/auth_user_model.dart';

class AuthService {
  /// Branche le renouvellement automatique de session sur les appels API (401).
  static void configureApiSessionRefresh() {
    ApiService.onSessionRefresh = refreshSession;
  }

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiresAtKey = 'expires_at';
  static const String _userDataKey = 'user_data';
  static const String _nomRoleKey = 'nom_role';
  static const String _nomCompletKey = 'nom_complet';
  static const String _idUtilisateurKey = 'id_utilisateur';
  static const String _onboardingSeenKey = 'onboarding_seen';

  static AuthUserModel? _currentUser;
  static AuthUserModel? get currentUser => _currentUser;

  /// Obtenir le nom complet de l'utilisateur
  static String? get userName => _currentUser?.utilisateur.nomComplet;

  /// Obtenir le rôle de l'utilisateur
  static String? get userRole => _currentUser?.nomRole;

  /// Obtenir l'ID de l'utilisateur
  static int? get userId => _currentUser?.utilisateur.idUtilisateur;

  /// ID affilié lié au compte (rôle adhérent / affilié)
  static int? get affilieId => _currentUser?.utilisateur.affilieId;

  /// ID agent lié au compte (agent AT, percepteur, superviseur terrain)
  static int? get agentId => _currentUser?.utilisateur.agentId;

  /// Peut utiliser les parcours agent (wallet, adhésion, réseau)
  static bool get isAgentTerrain {
    return _currentUser?.isAgentTerrain ?? false;
  }

  /// Identifiant superviseur pour les appels API d'équipe (agentId du JWT).
  static int? get superviseurId => agentId ?? userId;

  /// Marquer que l'onboarding a été vu
  static Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
  }

  /// Vérifier si l'onboarding a déjà été vu
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingSeenKey) ?? false;
  }

  /// Sauvegarder les données d'authentification
  static Future<bool> saveAuthData(AuthUserModel authUser) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_accessTokenKey, authUser.accessToken);
      await prefs.setString(_refreshTokenKey, authUser.refreshToken);
      await prefs.setString(_expiresAtKey, authUser.expiresAt.toIso8601String());
      await prefs.setString(_nomRoleKey, authUser.nomRole);
      await prefs.setString(_nomCompletKey, authUser.utilisateur.nomComplet);
      await prefs.setInt(_idUtilisateurKey, authUser.utilisateur.idUtilisateur);

      // Stocker les données utilisateur en JSON
      final userJson = jsonEncode({
        'idUtilisateur': authUser.utilisateur.idUtilisateur,
        'referenceUtilisateur': authUser.utilisateur.referenceUtilisateur,
        'nomComplet': authUser.utilisateur.nomComplet,
        'nomUtilisateur': authUser.utilisateur.nomUtilisateur,
        'email': authUser.utilisateur.email,
        'telephone': authUser.utilisateur.telephone,
        'photoUrl': authUser.utilisateur.photoUrl,
        'genre': authUser.utilisateur.genre,
        'statut': authUser.utilisateur.statut,
        'dateCreation': authUser.utilisateur.dateCreation.toIso8601String(),
        'isConnecte': authUser.utilisateur.isConnecte,
        'doitChangerMotDePasse': authUser.utilisateur.doitChangerMotDePasse,
        'agentId': authUser.utilisateur.agentId,
        'affilieId': authUser.utilisateur.affilieId,
      });
      await prefs.setString(_userDataKey, userJson);

      _currentUser = authUser;
      ApiService.token = authUser.accessToken;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Vérifier si l'utilisateur est déjà connecté
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var accessToken = prefs.getString(_accessTokenKey);
      var expiresAtStr = prefs.getString(_expiresAtKey);
      final userDataStr = prefs.getString(_userDataKey);
      final nomComplet = prefs.getString(_nomCompletKey);
      final nomRole = prefs.getString(_nomRoleKey);
      final idUtilisateur = prefs.getInt(_idUtilisateurKey);

      if (accessToken == null || accessToken.isEmpty) {
        return false;
      }

      // Token expiré : tenter un refresh avant de déconnecter
      if (expiresAtStr != null) {
        final expiresAt = DateTime.parse(expiresAtStr);
        if (DateTime.now().isAfter(expiresAt)) {
          final refreshed = await refreshSession();
          if (!refreshed) return false;
          accessToken = prefs.getString(_accessTokenKey);
          expiresAtStr = prefs.getString(_expiresAtKey);
          if (accessToken == null || accessToken.isEmpty) return false;
        }
      }

      // Restaurer le token dans ApiService
      ApiService.token = accessToken;

        // Restaurer les données utilisateur
      UtilisateurModel? utilisateur;
      int? savedAgentId;
      int? savedAffilieId;
      
      // Extraire agentId et affilieId du userDataStr
      if (userDataStr != null) {
        try {
          final userData = jsonDecode(userDataStr);
          savedAgentId = userData['agentId'];
          savedAffilieId = userData['affilieId'];
          utilisateur = UtilisateurModel.fromJson(userData);
        } catch (e) {
          utilisateur = UtilisateurModel(
            idUtilisateur: idUtilisateur ?? 0,
            referenceUtilisateur: '',
            nomComplet: nomComplet ?? '',
            nomUtilisateur: '',
            statut: true,
            dateCreation: DateTime.now(),
            isConnecte: true,
            doitChangerMotDePasse: false,
            agentId: idUtilisateur,
            affilieId: null,
          );
        }
      }

      _currentUser = AuthUserModel(
        success: true,
        message: '',
        accessToken: accessToken,
        refreshToken: prefs.getString(_refreshTokenKey) ?? '',
        tokenType: 'Bearer',
        expiresIn: 7200,
        expiresAt: expiresAtStr != null ? DateTime.parse(expiresAtStr) : DateTime.now(),
        doitChangerMotDePasse: false,
        acceptNotification: false,
        utilisateur: utilisateur ?? UtilisateurModel(
          idUtilisateur: idUtilisateur ?? 0,
          referenceUtilisateur: '',
          nomComplet: nomComplet ?? '',
          nomUtilisateur: '',
          statut: true,
          dateCreation: DateTime.now(),
          isConnecte: true,
          doitChangerMotDePasse: false,
        ),
        nomRole: nomRole ?? '',
        permissions: [],
        primaryRole: RoleModel(idRole: 0, nom: nomRole ?? '', description: '', niveau: 0, statut: true),
        roles: [],
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Obtenir le token d'accès
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// Obtenir le nom du rôle
  static Future<String?> getNomRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nomRoleKey);
  }

  /// Obtenir le nom complet
  static Future<String?> getNomComplet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nomCompletKey);
  }

  /// Nettoyer les données d'authentification (déconnexion)
  static Future<bool> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_expiresAtKey);
      await prefs.remove(_userDataKey);
      await prefs.remove(_nomRoleKey);
      await prefs.remove(_nomCompletKey);
      await prefs.remove(_idUtilisateurKey);

      _currentUser = null;
      ApiService.token = null;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Renouvelle l'access token via le refresh token stocké localement.
  static Future<bool> refreshSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedRefresh = prefs.getString(_refreshTokenKey);
      final refreshToken = (_currentUser?.refreshToken.isNotEmpty == true)
          ? _currentUser!.refreshToken
          : storedRefresh;

      if (refreshToken == null || refreshToken.isEmpty) {
        await clearAuthData();
        return false;
      }

      final response = await ApiService.refreshAccessToken(refreshToken);
      if (!response.success || response.data == null) {
        await clearAuthData();
        return false;
      }

      final result = response.data!;
      await prefs.setString(_accessTokenKey, result.accessToken);
      await prefs.setString(_expiresAtKey, result.expiresAt.toIso8601String());
      if (result.refreshToken.isNotEmpty) {
        await prefs.setString(_refreshTokenKey, result.refreshToken);
      }

      ApiService.token = result.accessToken;

      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          accessToken: result.accessToken,
          expiresAt: result.expiresAt,
          refreshToken: result.refreshToken.isNotEmpty
              ? result.refreshToken
              : _currentUser!.refreshToken,
        );
      }

      return true;
    } catch (_) {
      await clearAuthData();
      return false;
    }
  }

  /// Connexion utilisateur
  static Future<ApiResponse<AuthUserModel>> login({
    required String nomUtilisateur,
    required String motDePasse,
    String? fcmToken,
  }) async {
    final response = await ApiService.login(
      nomUtilisateur: nomUtilisateur,
      motDePasse: motDePasse,
      fcmToken: fcmToken,
    );

    if (response.success && response.data != null) {
      // Sauvegarder les données d'authentification
      await saveAuthData(response.data!);
    }

    return response;
  }

  /// Déconnexion utilisateur
  static Future<void> logout() async {
    final idUtilisateur = userId;
    var refreshToken = _currentUser?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      refreshToken = prefs.getString(_refreshTokenKey);
    }

    try {
      await ApiService.logout(
        idUtilisateur: idUtilisateur,
        refreshToken: refreshToken,
      );
    } catch (e) {
      // Ignorer les erreurs API, continuer la déconnexion locale
    }
    await clearAuthData();
  }

  /// Vérifier si le mot de passe doit être changé
  static bool get doitChangerMotDePasse {
    return _currentUser?.doitChangerMotDePasse ?? false;
  }

  /// Vérifier si l'utilisateur a le rôle Agent (AT)
  static bool get isAgentAT {
    return _currentUser?.isAgentAT ?? false;
  }

  /// Vérifier si l'utilisateur a le rôle Adhérent ou Affilié
  static bool get isAdherentOrAffilie {
    return _currentUser?.isAdherentOrAffilie ?? false;
  }

  /// Vérifier si l'utilisateur a le rôle Superviseur
  static bool get isSuperviseur {
    return _currentUser?.isSuperviseur ?? false;
  }

  /// Vérifier si l'utilisateur a le rôle Percepteur
  static bool get isPercepteur {
    return _currentUser?.isPercepteur ?? false;
  }

  /// Met à jour le profil en cache après édition ou refresh API.
  static Future<void> applyProfileUpdate(UtilisateurModel utilisateur) async {
    if (_currentUser == null) return;

    _currentUser = _currentUser!.copyWith(utilisateur: utilisateur);

    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode({
      'idUtilisateur': utilisateur.idUtilisateur,
      'referenceUtilisateur': utilisateur.referenceUtilisateur,
      'nomComplet': utilisateur.nomComplet,
      'nomUtilisateur': utilisateur.nomUtilisateur,
      'email': utilisateur.email,
      'telephone': utilisateur.telephone,
      'photoUrl': utilisateur.photoUrl,
      'genre': utilisateur.genre,
      'statut': utilisateur.statut,
      'dateCreation': utilisateur.dateCreation.toIso8601String(),
      'isConnecte': utilisateur.isConnecte,
      'doitChangerMotDePasse': utilisateur.doitChangerMotDePasse,
      'agentId': utilisateur.agentId,
      'affilieId': utilisateur.affilieId,
    });
    await prefs.setString(_userDataKey, userJson);
    if (utilisateur.nomComplet.isNotEmpty) {
      await prefs.setString(_nomCompletKey, utilisateur.nomComplet);
    }
  }

  /// Met à jour le rôle principal en cache.
  static Future<void> applyPrimaryRole(RoleModel role) async {
    if (_currentUser == null) return;

    _currentUser = _currentUser!.copyWith(
      primaryRole: role,
      nomRole: role.description.isNotEmpty ? role.description : role.nom,
    );
    await SharedPreferences.getInstance().then(
      (prefs) => prefs.setString(
        _nomRoleKey,
        role.description.isNotEmpty ? role.description : role.nom,
      ),
    );
  }
}
