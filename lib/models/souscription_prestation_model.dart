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

/// Collecte imbriquée — POST /api/SouscriptionPrestation?affilieId=
class SouscriptionPrestationCollecteRequest {
  final int agentId;
  final double montant;
  final int mois;
  final int annee;
  final int deviseId;
  final String modePaiement;
  final double montantRecu;
  final double montantAttendu;
  final String statutPaiement;
  final bool statut;
  final String? referencePaiement;
  final String? observation;

  const SouscriptionPrestationCollecteRequest({
    required this.agentId,
    required this.montant,
    required this.mois,
    required this.annee,
    required this.deviseId,
    required this.modePaiement,
    required this.montantRecu,
    required this.montantAttendu,
    required this.statutPaiement,
    this.statut = true,
    this.referencePaiement,
    this.observation,
  });

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'agentId': agentId,
      'montant': montant,
      'mois': mois,
      'annee': annee,
      'deviseId': deviseId,
      'modePaiement': modePaiement,
      'montantRecu': montantRecu,
      'montantAttendu': montantAttendu,
      'statutPaiement': statutPaiement,
      'statut': statut,
    };
    final ref = referencePaiement?.trim();
    if (ref != null && ref.isNotEmpty) {
      payload['referencePaiement'] = ref;
    }
    final obs = observation?.trim();
    if (obs != null && obs.isNotEmpty) {
      payload['observation'] = obs;
    }
    return payload;
  }
}

/// Corps POST /api/SouscriptionPrestation?affilieId=
class SouscriptionPrestationCreateRequest {
  final int prestationId;
  final DateTime dateSouscription;
  final bool statut;
  final SouscriptionPrestationCollecteRequest collecte;

  const SouscriptionPrestationCreateRequest({
    required this.prestationId,
    required this.dateSouscription,
    required this.statut,
    required this.collecte,
  });

  Map<String, dynamic> toJson() => {
        'prestationId': prestationId,
        'dateSouscription': dateSouscription.toUtc().toIso8601String(),
        'statut': statut,
        'collecte': collecte.toJson(),
      };
}

/// Corps POST /api/SouscriptionPrestation/paiement-electronique
/// (création d'une **nouvelle** souscription + FlexPay).
class SouscriptionPrestationPaiementElectroniqueRequest {
  final int affilieId;
  final String modePaiement;
  final String telephonePaiement;
  final int devisePaiementId;
  final SouscriptionPrestationCreateRequest achat;

  const SouscriptionPrestationPaiementElectroniqueRequest({
    required this.affilieId,
    required this.modePaiement,
    required this.telephonePaiement,
    required this.devisePaiementId,
    required this.achat,
  });

  Map<String, dynamic> toJson() => {
        'affilieId': affilieId,
        'modePaiement': modePaiement,
        'telephonePaiement': telephonePaiement,
        'devisePaiementId': devisePaiementId,
        'achat': achat.toJson(),
      };
}

/// Réponse POST /api/SouscriptionPrestation (extrait utile).
class SouscriptionPrestationCreateResult {
  final Map<String, dynamic> raw;

  SouscriptionPrestationCreateResult(this.raw);

  factory SouscriptionPrestationCreateResult.fromJson(
    Map<String, dynamic> json,
  ) =>
      SouscriptionPrestationCreateResult(json);
}
