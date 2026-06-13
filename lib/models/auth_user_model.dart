// ============================================
// MODÈLE D'UTILISATEUR AUTHENTIFIÉ
// ============================================

class UtilisateurModel {
  final int idUtilisateur;
  final String referenceUtilisateur;
  final String nomComplet;
  final String nomUtilisateur;
  final String? email;
  final String? telephone;
  final String? photoUrl;
  final String? genre;
  final bool statut;
  final DateTime dateCreation;
  final bool isConnecte;
  final bool doitChangerMotDePasse;
  final int? agentId;
  final int? affilieId;

  UtilisateurModel({
    required this.idUtilisateur,
    required this.referenceUtilisateur,
    required this.nomComplet,
    required this.nomUtilisateur,
    this.email,
    this.telephone,
    this.photoUrl,
    this.genre,
    required this.statut,
    required this.dateCreation,
    required this.isConnecte,
    required this.doitChangerMotDePasse,
    this.agentId,
    this.affilieId,
  });

  factory UtilisateurModel.fromJson(Map<String, dynamic> json) {
    return UtilisateurModel(
      idUtilisateur: json['idUtilisateur'] ?? 0,
      referenceUtilisateur: json['referenceUtilisateur'] ?? '',
      nomComplet: json['nomComplet'] ?? '',
      nomUtilisateur: json['nomUtilisateur'] ?? '',
      email: json['email'] ?? json['emailUtilisateur'],
      telephone: json['telephone'] ?? json['phoneUtilisateur'],
      photoUrl: json['photoUrl'],
      genre: json['genre'],
      statut: json['statut'] ?? false,
      dateCreation: DateTime.parse(json['dateCreation'] ?? DateTime.now().toIso8601String()),
      isConnecte: json['isConnecte'] ?? false,
      doitChangerMotDePasse: json['doitChangerMotDePasse'] ?? false,
      agentId: json['agentId'],
      affilieId: json['affilieId'],
    );
  }

  UtilisateurModel copyWith({
    String? nomUtilisateur,
    String? nomComplet,
    String? email,
    String? telephone,
    bool? statut,
    int? agentId,
    int? affilieId,
  }) {
    return UtilisateurModel(
      idUtilisateur: idUtilisateur,
      referenceUtilisateur: referenceUtilisateur,
      nomComplet: nomComplet ?? this.nomComplet,
      nomUtilisateur: nomUtilisateur ?? this.nomUtilisateur,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      photoUrl: photoUrl,
      genre: genre,
      statut: statut ?? this.statut,
      dateCreation: dateCreation,
      isConnecte: isConnecte,
      doitChangerMotDePasse: doitChangerMotDePasse,
      agentId: agentId ?? this.agentId,
      affilieId: affilieId ?? this.affilieId,
    );
  }
}

class RoleModel {
  final int idRole;
  final String nom;
  final String description;
  final int niveau;
  final bool statut;

  RoleModel({
    required this.idRole,
    required this.nom,
    required this.description,
    required this.niveau,
    required this.statut,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      idRole: json['idRole'] ?? 0,
      nom: json['nom'] ?? json['role'] ?? '',
      description: json['description'] ?? '',
      niveau: json['niveau'] ?? 0,
      statut: json['statut'] ?? false,
    );
  }
}

class AuthUserModel {
  final bool success;
  final String message;
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final DateTime expiresAt;
  final bool doitChangerMotDePasse;
  final bool acceptNotification;
  final UtilisateurModel utilisateur;
  final String nomRole;
  final List<String> permissions;
  final RoleModel primaryRole;
  final List<RoleModel> roles;

  AuthUserModel({
    required this.success,
    required this.message,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.expiresAt,
    required this.doitChangerMotDePasse,
    required this.acceptNotification,
    required this.utilisateur,
    required this.nomRole,
    required this.permissions,
    required this.primaryRole,
    required this.roles,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      tokenType: json['tokenType'] ?? 'Bearer',
      expiresIn: json['expiresIn'] ?? 0,
      expiresAt: DateTime.parse(json['expiresAt'] ?? DateTime.now().toIso8601String()),
      doitChangerMotDePasse: json['doitChangerMotDePasse'] ?? false,
      acceptNotification: json['acceptNotification'] ?? false,
      utilisateur: UtilisateurModel.fromJson(json['utilisateur'] ?? {}),
      nomRole: json['nomRole'] ?? '',
      permissions: List<String>.from(json['permissions'] ?? []),
      primaryRole: RoleModel.fromJson(json['primaryRole'] ?? {}),
      roles: (json['roles'] as List<dynamic>?)
              ?.map((role) => RoleModel.fromJson(role))
              .toList() ??
          [],
    );
  }

  AuthUserModel copyWith({
    UtilisateurModel? utilisateur,
    String? nomRole,
    RoleModel? primaryRole,
    bool? doitChangerMotDePasse,
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) {
    return AuthUserModel(
      success: success,
      message: message,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenType: tokenType,
      expiresIn: expiresIn,
      expiresAt: expiresAt ?? this.expiresAt,
      doitChangerMotDePasse: doitChangerMotDePasse ?? this.doitChangerMotDePasse,
      acceptNotification: acceptNotification,
      utilisateur: utilisateur ?? this.utilisateur,
      nomRole: nomRole ?? this.nomRole,
      permissions: permissions,
      primaryRole: primaryRole ?? this.primaryRole,
      roles: roles,
    );
  }

  /// Vérifie si l'utilisateur a le rôle Agent (AT)
  bool get isAgentAT {
    return nomRole.toLowerCase().contains('agent') && 
           nomRole.toLowerCase().contains('at');
  }

  /// Vérifie si l'utilisateur a le rôle Adhérent ou Affilié
  bool get isAdherentOrAffilie {
    final roleLower = nomRole.toLowerCase();
    return roleLower.contains('adhérent') || 
           roleLower.contains('affilié') || 
           roleLower.contains('affilie') ||
           roleLower.contains('adherent');
  }

  /// Vérifie si l'utilisateur a le rôle Percepteur
  bool get isPercepteur {
    return nomRole.toLowerCase().contains('percepteur');
  }

  /// Vérifie si l'utilisateur a le rôle Superviseur
  bool get isSuperviseur {
    return nomRole.toLowerCase().contains('superviseur');
  }

  /// Superviseur lié à un agent (peut faire adhésions, wallets, etc.)
  bool get isAgentTerrain {
    if (isAgentAT) return true;
    return isSuperviseur && utilisateur.agentId != null;
  }

  /// Vérifie si le rôle est autorisé sur l'application mobile
  bool get isRoleAutorise {
    return isAgentAT || isAdherentOrAffilie || isPercepteur || isSuperviseur;
  }

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  /// Liste des rôles autorisés
  static const List<String> rolesAutorises = [
    'Agent (AT)',
    'Adhérent',
    'Affilié',
    'Percepteur',
    'Superviseur',
  ];

  /// Vérifie si un rôle est dans la liste des rôles autorisés
  static bool isRoleAutoriseString(String role) {
    final roleLower = role.toLowerCase();
    return roleLower.contains('agent') ||
        roleLower.contains('adhérent') ||
        roleLower.contains('affilié') ||
        roleLower.contains('affilie') ||
        roleLower.contains('adherent') ||
        roleLower.contains('percepteur') ||
        roleLower.contains('superviseur');
  }
}
