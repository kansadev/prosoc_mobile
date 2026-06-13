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

  factory RecentAffilieModel.fromJson(Map<String, dynamic> json) {
    return RecentAffilieModel(
      idAffilie: _asInt(json['idAffilie'] ?? json['affilieId'] ?? json['id']),
      nom: (json['nom'] ?? '').toString(),
      prenom: (json['prenom'] ?? '').toString(),
      telephone: (json['telephone'] ?? json['phone'] ?? '').toString(),
      dateAdhesion: _tryParseDate(json['dateAdhesion']),
      typeAdhesion: (json['typeAdhesion'] ?? '').toString(),
      derniereCollecte: json['derniereCollecte'] as num?,
      derniereCollecteDate: _tryParseDate(json['derniereCollecteDate']),
      nombreCollectes: json['nombreCollectes'] as int?,
      totalCollectes: json['totalCollectes'] as num?,
      statutDossier: json['statutDossier']?.toString(),
    );
  }
}

