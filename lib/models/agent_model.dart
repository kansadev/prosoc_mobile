import '../utils/currency_formatter.dart';

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
  final int? walletId;
  final double? walletSolde;
  final bool walletCree;
  final int? walletVirtuelId;
  final double? walletVirtuelSolde;
  final bool walletVirtuelCree;
  final int? utilisateurId;
  final String? nomUtilisateur;
  final bool utilisateurCree;

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
    this.walletId,
    this.walletSolde,
    this.walletCree = false,
    this.walletVirtuelId,
    this.walletVirtuelSolde,
    this.walletVirtuelCree = false,
    this.utilisateurId,
    this.nomUtilisateur,
    this.utilisateurCree = false,
  });

  factory AgentModel.fromJson(Map<String, dynamic> json) {
    final nomComplet = json['nomComplet']?.toString().trim();
    final builtNom = [
      json['prenomAgent'],
      json['postnomAgent'],
      json['nomAgent'],
    ]
        .where((part) => part != null && part.toString().trim().isNotEmpty)
        .join(' ');

    return AgentModel(
      id: json['id'] ?? json['idAgent'] ?? json['agentId'] ?? 0,
      nomComplet: (nomComplet != null && nomComplet.isNotEmpty)
          ? nomComplet
          : builtNom,
      matricule: json['matricule'] ?? json['referenceAgent'] ?? '',
      phone: json['phone'] ?? json['telephoneAgent'] ?? '',
      emailAgent: json['emailAgent']?.toString(),
      fonction: json['fonction']?.toString(),
      roleAgent: json['roleAgent']?.toString(),
      photoUrl: json['photoUrl']?.toString(),
      dateCreation: _parseDate(json['dateCreation']) ?? DateTime.now(),
      dateModification: _parseDate(json['dateModification']),
      statut: _asBool(json['statut'], defaultValue: true),
      zoneSocialeId: _asNullableInt(json['zoneSocialeId']),
      zoneSocialeNom: json['zoneSocialeNom']?.toString(),
      categorieAgentId: _asNullableInt(json['categorieAgentId']),
      walletId: _asNullableInt(json['walletId']),
      walletSolde: _asNullableDouble(json['walletSolde']),
      walletCree: _asBool(json['walletCree']),
      walletVirtuelId: _asNullableInt(json['walletVirtuelId']),
      walletVirtuelSolde: _asNullableDouble(json['walletVirtuelSolde']),
      walletVirtuelCree: _asBool(json['walletVirtuelCree']),
      utilisateurId: _asNullableInt(json['utilisateurId']),
      nomUtilisateur: json['nomUtilisateur']?.toString(),
      utilisateurCree: _asBool(json['utilisateurCree']),
    );
  }

  String get formattedWalletSolde =>
      CurrencyFormatter.formatUsd(walletSolde);

  String get formattedWalletVirtuelSolde =>
      CurrencyFormatter.formatUsd(walletVirtuelSolde);

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
    int? walletId,
    double? walletSolde,
    bool? walletCree,
    int? walletVirtuelId,
    double? walletVirtuelSolde,
    bool? walletVirtuelCree,
    int? utilisateurId,
    String? nomUtilisateur,
    bool? utilisateurCree,
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
      walletId: walletId ?? this.walletId,
      walletSolde: walletSolde ?? this.walletSolde,
      walletCree: walletCree ?? this.walletCree,
      walletVirtuelId: walletVirtuelId ?? this.walletVirtuelId,
      walletVirtuelSolde: walletVirtuelSolde ?? this.walletVirtuelSolde,
      walletVirtuelCree: walletVirtuelCree ?? this.walletVirtuelCree,
      utilisateurId: utilisateurId ?? this.utilisateurId,
      nomUtilisateur: nomUtilisateur ?? this.nomUtilisateur,
      utilisateurCree: utilisateurCree ?? this.utilisateurCree,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static double? _asNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.'));
  }

  static int? _asNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool _asBool(dynamic value, {bool defaultValue = false}) {
    if (value is bool) return value;
    if (value == null) return defaultValue;
    final normalized = value.toString().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return defaultValue;
  }
}
