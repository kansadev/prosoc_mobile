class TypeAdhesion {
  final int id;
  final String libelle;
  final int maxDependants;
  final String description;
  final double montant;
  final bool statut;
  final DateTime dateCreation;
  final int categorieAdhesionId;
  final String code;

  TypeAdhesion({
    required this.id,
    required this.libelle,
    required this.maxDependants,
    required this.description,
    required this.montant,
    required this.statut,
    required this.dateCreation,
    required this.categorieAdhesionId,
    this.code = '',
  });

  /// Tolérant : camelCase / PascalCase et champs facultatifs absents (les
  /// référentiels de synchronisation peuvent être plus légers que l'API).
  factory TypeAdhesion.fromJson(Map<String, dynamic> json) {
    dynamic champ(List<String> cles) {
      for (final cle in cles) {
        final valeur =
            json[cle] ?? json[cle[0].toUpperCase() + cle.substring(1)];
        if (valeur != null) return valeur;
      }
      return null;
    }

    int entier(dynamic v) =>
        v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

    final statut = champ(['statut']);
    return TypeAdhesion(
      id: entier(champ(['id', 'idTypeAdhesion', 'typeAdhesionId'])),
      libelle: (champ(['libelle', 'nom']) ?? '').toString(),
      maxDependants: entier(champ(['maxDependants'])),
      description: (champ(['description']) ?? '').toString(),
      montant: () {
        final v = champ(['montant']);
        return v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;
      }(),
      statut: statut is bool ? statut : statut?.toString() != 'false',
      dateCreation:
          DateTime.tryParse('${champ(['dateCreation']) ?? ''}') ??
          DateTime.now(),
      categorieAdhesionId: entier(champ(['categorieAdhesionId'])),
      code: (champ(['code']) ?? '').toString(),
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
      'code': code,
    };
  }

  @override
  String toString() {
    return 'TypeAdhesion(id: $id, libelle: $libelle, maxDependants: $maxDependants)';
  }
}
