// ============================================
// SOUSCRIPTION PRESTATION — GET /api/SouscriptionPrestation/by-affilie/{affilieId}
// ============================================

class SouscriptionPrestationModel {
  final int id;
  final int affilieId;
  final String affilieNom;
  final String affiliePrenom;
  final int prestationId;
  final String prestationNom;
  final String prestationDescription;
  final DateTime? dateSouscription;
  final DateTime? dateCreation;
  final DateTime? dateModification;
  final bool statut;
  final int nombreCollectes;
  final double totalCollectes;

  SouscriptionPrestationModel({
    required this.id,
    required this.affilieId,
    required this.affilieNom,
    required this.affiliePrenom,
    required this.prestationId,
    required this.prestationNom,
    required this.prestationDescription,
    this.dateSouscription,
    this.dateCreation,
    this.dateModification,
    required this.statut,
    required this.nombreCollectes,
    required this.totalCollectes,
  });

  factory SouscriptionPrestationModel.fromJson(Map<String, dynamic> json) {
    return SouscriptionPrestationModel(
      id: _asInt(json['id'] ?? json['idSouscriptionPrestation']),
      affilieId: _asInt(json['affilieId']),
      affilieNom: json['affilieNom']?.toString() ?? '',
      affiliePrenom: json['affiliePrenom']?.toString() ?? '',
      prestationId: _asInt(json['prestationId']),
      prestationNom: json['prestationNom']?.toString() ?? '',
      prestationDescription: json['prestationDescription']?.toString() ?? '',
      dateSouscription: _parseDate(json['dateSouscription']),
      dateCreation: _parseDate(json['dateCreation']),
      dateModification: _parseDate(json['dateModification']),
      statut: _asBool(json['statut'], defaultValue: true),
      nombreCollectes: _asInt(json['nombreCollectes']),
      totalCollectes: _asDouble(json['totalCollectes']),
    );
  }

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static bool _asBool(dynamic value, {required bool defaultValue}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final n = value.trim().toLowerCase();
      if (n == 'true') return true;
      if (n == 'false') return false;
    }
    return defaultValue;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
