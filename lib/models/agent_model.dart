class AgentModel {
  final int id;
  final String nomComplet;
  final String matricule;
  final String phone;
  final String? emailAgent;
  final String? fonction;
  final String? roleAgent;
  final String? photoUrl;
  final DateTime dateCreation;
  final DateTime? dateModification;
  final bool statut;
  final int? zoneSocialeId;
  final String? zoneSocialeNom;
  final int? categorieAgentId;

  AgentModel({
    required this.id,
    required this.nomComplet,
    required this.matricule,
    required this.phone,
    this.emailAgent,
    this.fonction,
    this.roleAgent,
    this.photoUrl,
    required this.dateCreation,
    this.dateModification,
    required this.statut,
    this.zoneSocialeId,
    this.zoneSocialeNom,
    this.categorieAgentId,
  });

  factory AgentModel.fromJson(Map<String, dynamic> json) {
    final nomComplet = json['nomComplet']?.toString().trim();
    final builtNom = [
      json['prenomAgent'],
      json['postnomAgent'],
      json['nomAgent'],
    ].where((part) => part != null && part.toString().trim().isNotEmpty).join(' ');

    return AgentModel(
      id: json['id'] ?? json['idAgent'] ?? json['agentId'] ?? 0,
      nomComplet: (nomComplet != null && nomComplet.isNotEmpty)
          ? nomComplet
          : builtNom,
      matricule: json['matricule'] ?? json['referenceAgent'] ?? '',
      phone: json['phone'] ?? json['telephoneAgent'] ?? '',
      emailAgent: json['emailAgent'],
      fonction: json['fonction'],
      roleAgent: json['roleAgent'],
      photoUrl: json['photoUrl'],
      dateCreation: DateTime.parse(json['dateCreation'] ?? DateTime.now().toIso8601String()),
      dateModification: json['dateModification'] != null 
          ? DateTime.parse(json['dateModification']) 
          : null,
      statut: json['statut'] ?? true,
      zoneSocialeId: json['zoneSocialeId'],
      zoneSocialeNom: json['zoneSocialeNom'],
      categorieAgentId: json['categorieAgentId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nomComplet': nomComplet,
      'matricule': matricule,
      'phone': phone,
      'emailAgent': emailAgent,
      'fonction': fonction,
      'roleAgent': roleAgent,
      'photoUrl': photoUrl,
      'zoneSocialeId': zoneSocialeId,
      'categorieAgentId': categorieAgentId,
      'statut': statut,
    };
  }

  /// Méthode pour créer une copie avec des champs mis à jour
  AgentModel copyWith({
    int? id,
    String? nomComplet,
    String? matricule,
    String? phone,
    String? emailAgent,
    String? fonction,
    String? roleAgent,
    String? photoUrl,
    DateTime? dateCreation,
    DateTime? dateModification,
    bool? statut,
    int? zoneSocialeId,
    String? zoneSocialeNom,
    int? categorieAgentId,
  }) {
    return AgentModel(
      id: id ?? this.id,
      nomComplet: nomComplet ?? this.nomComplet,
      matricule: matricule ?? this.matricule,
      phone: phone ?? this.phone,
      emailAgent: emailAgent ?? this.emailAgent,
      fonction: fonction ?? this.fonction,
      roleAgent: roleAgent ?? this.roleAgent,
      photoUrl: photoUrl ?? this.photoUrl,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
      statut: statut ?? this.statut,
      zoneSocialeId: zoneSocialeId ?? this.zoneSocialeId,
      zoneSocialeNom: zoneSocialeNom ?? this.zoneSocialeNom,
      categorieAgentId: categorieAgentId ?? this.categorieAgentId,
    );
  }
}
