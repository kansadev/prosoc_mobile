import 'medical_json.dart';

/// Statuts serveur d'une prise en charge. `estUtilise` est indépendant : une
/// prise en charge consommée peut rester `VALIDEE`.
abstract final class StatutPriseEnCharge {
  static const enAttente = 'EN_ATTENTE';
  static const validee = 'VALIDEE';
  static const rejetee = 'REJETEE';
}

/// Badge d'affichage dérivé (aucun statut `UTILISE` / `EXPIRE` côté serveur).
enum BadgePriseEnCharge {
  enAttente('En attente'),
  validee('Validée'),
  rejetee('Rejetée'),
  utilisee('Utilisée'),
  expiree('Expirée'),
  inconnu('Statut inconnu');

  const BadgePriseEnCharge(this.label);
  final String label;
}

class PriseEnChargeMedicale {
  final int id;
  final int periodeCouvertureMedicaleId;
  final int affilieId;
  final int hopitalPartenaireId;
  final int soinId;
  final String? soinNom;
  final String statut;
  final String? motif;
  final DateTime? dateDemandeUtc;
  final int? agentId;
  final String? numeroBon;
  final int? jetonMedicalId;
  final String? codeJeton;

  /// Chaîne signée à transmettre telle quelle au scanner.
  final String? qrCodePayload;

  /// PNG en base64, sans préfixe data URI.
  final String? qrCodeImageBase64;
  final DateTime? dateExpirationUtc;
  final bool estUtilise;
  final String? observation;
  final DateTime? dateConfirmationUtc;

  const PriseEnChargeMedicale({
    required this.id,
    required this.periodeCouvertureMedicaleId,
    required this.affilieId,
    required this.hopitalPartenaireId,
    required this.soinId,
    this.soinNom,
    required this.statut,
    this.motif,
    this.dateDemandeUtc,
    this.agentId,
    this.numeroBon,
    this.jetonMedicalId,
    this.codeJeton,
    this.qrCodePayload,
    this.qrCodeImageBase64,
    this.dateExpirationUtc,
    required this.estUtilise,
    this.observation,
    this.dateConfirmationUtc,
  });

  factory PriseEnChargeMedicale.fromJson(Map<String, dynamic> json) {
    return PriseEnChargeMedicale(
      id: MedicalJson.asInt(json['id']),
      periodeCouvertureMedicaleId: MedicalJson.asInt(
        json['periodeCouvertureMedicaleId'],
      ),
      affilieId: MedicalJson.asInt(json['affilieId']),
      hopitalPartenaireId: MedicalJson.asInt(json['hopitalPartenaireId']),
      soinId: MedicalJson.asInt(json['soinId']),
      soinNom: MedicalJson.asStringOrNull(json['soinNom']),
      statut: MedicalJson.asString(json['statut']).toUpperCase(),
      motif: MedicalJson.asStringOrNull(json['motif']),
      dateDemandeUtc: MedicalJson.asDateOrNull(json['dateDemandeUtc']),
      agentId: MedicalJson.asIntOrNull(json['agentId']),
      numeroBon: MedicalJson.asStringOrNull(json['numeroBon']),
      jetonMedicalId: MedicalJson.asIntOrNull(json['jetonMedicalId']),
      codeJeton: MedicalJson.asStringOrNull(json['codeJeton']),
      qrCodePayload: MedicalJson.asStringOrNull(json['qrCodePayload']),
      qrCodeImageBase64: MedicalJson.asStringOrNull(json['qrCodeImageBase64']),
      dateExpirationUtc: MedicalJson.asDateOrNull(json['dateExpirationUtc']),
      estUtilise: MedicalJson.asBool(json['estUtilise']),
      observation: MedicalJson.asStringOrNull(json['observation']),
      dateConfirmationUtc: MedicalJson.asDateOrNull(json['dateConfirmationUtc']),
    );
  }

  bool get estEnAttente => statut == StatutPriseEnCharge.enAttente;
  bool get estValidee => statut == StatutPriseEnCharge.validee;

  BadgePriseEnCharge badge({DateTime? now}) {
    switch (statut) {
      case StatutPriseEnCharge.enAttente:
        return BadgePriseEnCharge.enAttente;
      case StatutPriseEnCharge.rejetee:
        return BadgePriseEnCharge.rejetee;
      case StatutPriseEnCharge.validee:
        if (estUtilise) return BadgePriseEnCharge.utilisee;
        final expiration = dateExpirationUtc;
        final instant = (now ?? DateTime.now()).toUtc();
        if (expiration != null && !instant.isBefore(expiration)) {
          return BadgePriseEnCharge.expiree;
        }
        return BadgePriseEnCharge.validee;
      default:
        return BadgePriseEnCharge.inconnu;
    }
  }
}
