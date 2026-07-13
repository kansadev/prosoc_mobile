/// DTO GET /api/Adhesion/en-ligne-sans-gestionnaire
class AdhesionEnLigneSansGestionnaireModel {
  final int idAdhesion;
  final int idAffilie;
  final String codeAdhesion;
  final String nomComplet;
  final String telephone;
  final String? emailAffilie;
  final String? provinceResidence;
  final String? typeAdhesion;
  final String statutDossier;
  final DateTime? dateAdhesion;
  final String? modePaiementAdhesion;

  AdhesionEnLigneSansGestionnaireModel({
    required this.idAdhesion,
    required this.idAffilie,
    required this.codeAdhesion,
    required this.nomComplet,
    required this.telephone,
    this.emailAffilie,
    this.provinceResidence,
    this.typeAdhesion,
    required this.statutDossier,
    this.dateAdhesion,
    this.modePaiementAdhesion,
  });

  factory AdhesionEnLigneSansGestionnaireModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdhesionEnLigneSansGestionnaireModel(
      idAdhesion: _int(json['idAdhesion'] ?? json['IdAdhesion']),
      idAffilie: _int(json['idAffilie'] ?? json['IdAffilie']),
      codeAdhesion: (json['codeAdhesion'] ?? json['CodeAdhesion'] ?? '')
          .toString(),
      nomComplet: (json['nomComplet'] ?? json['NomComplet'] ?? '').toString(),
      telephone: (json['telephone'] ?? json['Telephone'] ?? '').toString(),
      emailAffilie: json['emailAffilie']?.toString(),
      provinceResidence: json['provinceResidence']?.toString(),
      typeAdhesion: json['typeAdhesion']?.toString(),
      statutDossier:
          (json['statutDossier'] ?? json['StatutDossier'] ?? '').toString(),
      dateAdhesion: _date(json['dateAdhesion'] ?? json['DateAdhesion']),
      modePaiementAdhesion: json['modePaiementAdhesion']?.toString(),
    );
  }
}

class LienParenteModel {
  final String code;
  final String libelle;

  LienParenteModel({required this.code, required this.libelle});

  factory LienParenteModel.fromJson(Map<String, dynamic> json) {
    return LienParenteModel(
      code: (json['code'] ?? json['Code'] ?? '').toString(),
      libelle: (json['libelle'] ?? json['Libelle'] ?? json['nom'] ?? '')
          .toString(),
    );
  }
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _date(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

/// Liste paginée GET /api/Adhesion/en-ligne-sans-gestionnaire
class PaginatedAdhesionsEnLigne {
  final List<AdhesionEnLigneSansGestionnaireModel> items;
  final int totalItems;
  final int currentPage;
  final bool hasNext;

  PaginatedAdhesionsEnLigne({
    required this.items,
    required this.totalItems,
    required this.currentPage,
    required this.hasNext,
  });
}
