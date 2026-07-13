/// Demande de bon d'envoi — GET /api/DemandeBonEnvoi/by-affilie/{affilieId}.
class DemandeBonEnvoiModel {
  final int idDemande;
  final int affilieId;
  final String affilieNom;
  final int prestationId;
  final String prestationNom;
  final String typeDemande;
  final String motifDemande;
  final int agentId;
  final String agentNom;
  final String observationAgent;
  final DateTime? dateDemande;
  final DateTime? dateValidation;
  final String statutDemande;
  final int bonEnvoiId;
  final String bonEnvoiNumero;
  final int jetonMedicalId;
  final String jetonMedicalCode;
  final String qrCodePayload;
  final String qrCodeImageBase64;
  final DateTime? dateCreation;
  final DateTime? dateModification;
  final bool statut;

  DemandeBonEnvoiModel({
    required this.idDemande,
    required this.affilieId,
    required this.affilieNom,
    required this.prestationId,
    required this.prestationNom,
    required this.typeDemande,
    required this.motifDemande,
    required this.agentId,
    required this.agentNom,
    required this.observationAgent,
    this.dateDemande,
    this.dateValidation,
    required this.statutDemande,
    required this.bonEnvoiId,
    required this.bonEnvoiNumero,
    required this.jetonMedicalId,
    required this.jetonMedicalCode,
    required this.qrCodePayload,
    required this.qrCodeImageBase64,
    this.dateCreation,
    this.dateModification,
    required this.statut,
  });

  factory DemandeBonEnvoiModel.fromJson(Map<String, dynamic> json) {
    return DemandeBonEnvoiModel(
      idDemande: _asInt(json['idDemande'] ?? json['id']),
      affilieId: _asInt(json['affilieId']),
      affilieNom: json['affilieNom']?.toString() ?? '',
      prestationId: _asInt(json['prestationId']),
      prestationNom: json['prestationNom']?.toString() ?? '',
      typeDemande: json['typeDemande']?.toString() ?? '',
      motifDemande: json['motifDemande']?.toString() ?? '',
      agentId: _asInt(json['agentId']),
      agentNom: json['agentNom']?.toString() ?? '',
      observationAgent: json['observationAgent']?.toString() ?? '',
      dateDemande: _parseDate(json['dateDemande']),
      dateValidation: _parseDate(json['dateValidation']),
      statutDemande: json['statutDemande']?.toString() ?? '',
      bonEnvoiId: _asInt(json['bonEnvoiId']),
      bonEnvoiNumero: json['bonEnvoiNumero']?.toString() ?? '',
      jetonMedicalId: _asInt(
        json['jetonMedicalId'] ?? json['JetonMedicalId'],
      ),
      jetonMedicalCode: json['jetonMedicalCode']?.toString() ??
          json['JetonMedicalCode']?.toString() ??
          '',
      qrCodePayload: json['qrCodePayload']?.toString() ?? '',
      qrCodeImageBase64: json['qrCodeImageBase64']?.toString() ?? '',
      dateCreation: _parseDate(json['dateCreation']),
      dateModification: _parseDate(json['dateModification']),
      statut: _asBool(json['statut'], defaultValue: true),
    );
  }

  bool get isEnAttente {
    final s = statutDemande.trim().toUpperCase();
    return s.contains('ATTENTE') || s.contains('PENDING') || s.isEmpty;
  }

  bool get isValidee {
    final s = statutDemande.trim().toUpperCase();
    return s.contains('VALID') || s.contains('APPROUV') || hasCoupleBonJeton;
  }

  bool get isTraitee {
    final s = statutDemande.trim().toUpperCase();
    return s.contains('TRAIT') ||
        s.contains('UTILIS') ||
        s.contains('CLOTUR');
  }

  bool get hasCoupleBonJeton => bonEnvoiId > 0 && jetonMedicalId > 0;

  bool get hasQr =>
      qrCodeImageBase64.trim().isNotEmpty || qrCodePayload.trim().isNotEmpty;

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

/// Résultat GET /api/DemandeBonEnvoi/verifier-eligibilite/{affilieId}.
class DemandeBonEligibilite {
  final bool eligible;
  final String message;

  const DemandeBonEligibilite({
    required this.eligible,
    this.message = '',
  });

  factory DemandeBonEligibilite.fromJson(dynamic raw) {
    if (raw is bool) {
      return DemandeBonEligibilite(eligible: raw);
    }
    if (raw is! Map) {
      return const DemandeBonEligibilite(
        eligible: false,
        message: 'Réponse d\'éligibilité invalide.',
      );
    }
    final json = raw is Map<String, dynamic>
        ? raw
        : Map<String, dynamic>.from(raw);

    bool? eligible;
    for (final key in [
      'eligible',
      'estEligible',
      'peutDemander',
      'isEligible',
      'success',
    ]) {
      final v = json[key];
      if (v is bool) {
        eligible = v;
        break;
      }
    }

    final message = (json['message'] ??
            json['motif'] ??
            json['raison'] ??
            json['detail'] ??
            '')
        .toString()
        .trim();

    return DemandeBonEligibilite(
      eligible: eligible ?? false,
      message: message.isNotEmpty
          ? message
          : (eligible == false
              ? 'Vous n\'êtes pas éligible à une demande de bon.'
              : ''),
    );
  }
}
