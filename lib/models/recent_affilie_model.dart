// ============================================
// MODÈLE AFFILIÉ RÉCENT (Dashboard Agent)
// ============================================

class RecentAffilieModel {
  final int idAffilie;
  final String nom;
  final String prenom;
  final String telephone;
  final DateTime? dateAdhesion;
  final String typeAdhesion;
  final num? derniereCollecte;
  final DateTime? derniereCollecteDate;
  final int? nombreCollectes;
  final num? totalCollectes;
  final String? statutDossier;

  RecentAffilieModel({
    required this.idAffilie,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.dateAdhesion,
    required this.typeAdhesion,
    this.derniereCollecte,
    this.derniereCollecteDate,
    this.nombreCollectes,
    this.totalCollectes,
    this.statutDossier,
  });

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static int? _asNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return int.tryParse(trimmed);
    }
    return null;
  }

  static num? _asNullableNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return num.tryParse(trimmed.replaceAll(',', '.'));
    }
    return null;
  }

  factory RecentAffilieModel.fromJson(Map<String, dynamic> json) {
    return RecentAffilieModel(
      idAffilie: _asInt(json['idAffilie'] ?? json['affilieId'] ?? json['id']),
      nom: (json['nom'] ?? '').toString(),
      prenom: (json['prenom'] ?? '').toString(),
      telephone: (json['telephone'] ?? json['phone'] ?? '').toString(),
      dateAdhesion: _tryParseDate(
        json['dateAdhesion'] ??
            json['dateCreationAffilie'] ??
            json['dateCreation'],
      ),
      typeAdhesion: (json['typeAdhesion'] ?? '').toString(),
      derniereCollecte: _asNullableNum(json['derniereCollecte']),
      derniereCollecteDate: _tryParseDate(json['derniereCollecteDate']),
      nombreCollectes: _asNullableInt(json['nombreCollectes']),
      totalCollectes: _asNullableNum(json['totalCollectes']),
      statutDossier: json['statutDossier']?.toString(),
    );
  }
}

