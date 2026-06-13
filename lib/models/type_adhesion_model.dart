class TypeAdhesion {
  final int id;
  final String libelle;
  final int maxDependants;
  final String description;
  final double montant;
  final bool statut;
  final DateTime dateCreation;
  final int categorieAdhesionId;

  TypeAdhesion({
    required this.id,
    required this.libelle,
    required this.maxDependants,
    required this.description,
    required this.montant,
    required this.statut,
    required this.dateCreation,
    required this.categorieAdhesionId,
  });

  factory TypeAdhesion.fromJson(Map<String, dynamic> json) {
    return TypeAdhesion(
      id: json['id'] as int,
      libelle: json['libelle'] as String,
      maxDependants: json['maxDependants'] as int,
      description: json['description'] as String,
      montant: (json['montant'] as num).toDouble(),
      statut: json['statut'] as bool,
      dateCreation: DateTime.parse(json['dateCreation'] as String),
      categorieAdhesionId: json['categorieAdhesionId'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'libelle': libelle,
      'maxDependants': maxDependants,
      'description': description,
      'montant': montant,
      'statut': statut,
      'dateCreation': dateCreation.toIso8601String(),
      'categorieAdhesionId': categorieAdhesionId,
    };
  }

  @override
  String toString() {
    return 'TypeAdhesion(id: $id, libelle: $libelle, maxDependants: $maxDependants)';
  }
}
