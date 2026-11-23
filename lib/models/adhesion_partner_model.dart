class AdhesionCategory {
  final int id;
  final String code;
  final String libelle;
  final bool statut;

  const AdhesionCategory({
    required this.id,
    required this.code,
    required this.libelle,
    required this.statut,
  });

  factory AdhesionCategory.fromJson(Map<String, dynamic> json) {
    final id = _asInt(
      json['idCategorieAdhesion'] ??
          json['IdCategorieAdhesion'] ??
          json['id'] ??
          json['Id'],
    );
    final statut = json['statut'] ?? json['Statut'];
    return AdhesionCategory(
      id: id,
      code: (json['code'] ?? json['Code'] ?? '').toString().trim(),
      libelle:
          (json['libelle'] ??
                  json['Libelle'] ??
                  json['nom'] ??
                  json['Nom'] ??
                  '')
              .toString()
              .trim(),
      statut: statut == null ? true : _asBool(statut),
    );
  }

  Map<String, dynamic> toJson() => {
    'idCategorieAdhesion': id,
    'code': code,
    'libelle': libelle,
    'statut': statut,
  };
}

class AdhesionPartner {
  final int id;
  final String nom;
  final bool statut;

  const AdhesionPartner({
    required this.id,
    required this.nom,
    required this.statut,
  });

  factory AdhesionPartner.fromJson(Map<String, dynamic> json) {
    final id =
        json['idStructurePartenaire'] ??
        json['IdStructurePartenaire'] ??
        json['idEntreprisePartenaire'] ??
        json['IdEntreprisePartenaire'] ??
        json['id'] ??
        json['Id'];
    final nom =
        json['nom'] ??
        json['Nom'] ??
        json['nomStructurePartenaire'] ??
        json['NomStructurePartenaire'] ??
        json['nomEntreprisePartenaire'] ??
        json['NomEntreprisePartenaire'];
    final statut = json['statut'] ?? json['Statut'];
    return AdhesionPartner(
      id: _asInt(id),
      nom: (nom ?? '').toString().trim(),
      statut: statut == null ? true : _asBool(statut),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'nom': nom, 'statut': statut};
}

int _asInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  return value?.toString().toLowerCase() == 'true' || value?.toString() == '1';
}
