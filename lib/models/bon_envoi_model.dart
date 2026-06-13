/// Bon d'envoi — GET /api/BonEnvoi/by-affilie/{affilieId}/paginated.
class BonEnvoiModel {
  final int idBonEnvoi;
  final String numeroBon;
  final int affilieId;
  final String affilieNom;
  final int prestationId;
  final String prestationNom;
  final DateTime? dateEmission;
  final DateTime? dateUtilisation;
  final bool estUtilise;
  final bool statut;
  final DateTime? dateCreation;
  final DateTime? dateModification;
  final String qrCodePayload;
  final String qrCodeImageBase64;

  BonEnvoiModel({
    required this.idBonEnvoi,
    required this.numeroBon,
    required this.affilieId,
    required this.affilieNom,
    required this.prestationId,
    required this.prestationNom,
    this.dateEmission,
    this.dateUtilisation,
    required this.estUtilise,
    required this.statut,
    this.dateCreation,
    this.dateModification,
    required this.qrCodePayload,
    required this.qrCodeImageBase64,
  });

  factory BonEnvoiModel.fromJson(Map<String, dynamic> json) {
    return BonEnvoiModel(
      idBonEnvoi: _asInt(json['idBonEnvoi'] ?? json['id']),
      numeroBon: json['numeroBon']?.toString() ?? '',
      affilieId: _asInt(json['affilieId']),
      affilieNom: json['affilieNom']?.toString() ?? '',
      prestationId: _asInt(json['prestationId']),
      prestationNom: json['prestationNom']?.toString() ?? '',
      dateEmission: _parseDate(json['dateEmission']),
      dateUtilisation: _parseDate(json['dateUtilisation']),
      estUtilise: _asBool(json['estUtilise'], defaultValue: false),
      statut: _asBool(json['statut'], defaultValue: true),
      dateCreation: _parseDate(json['dateCreation']),
      dateModification: _parseDate(json['dateModification']),
      qrCodePayload: json['qrCodePayload']?.toString() ?? '',
      qrCodeImageBase64: json['qrCodeImageBase64']?.toString() ?? '',
    );
  }

  String get statutLabel => estUtilise ? 'Utilisé' : 'Disponible';

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? fallback;
    return fallback;
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
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
