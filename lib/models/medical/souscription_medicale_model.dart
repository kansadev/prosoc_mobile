import 'medical_json.dart';

class SouscriptionMedicale {
  final int id;
  final int affilieId;
  final int hopitalPartenaireId;
  final int offreMedicaleHopitalId;
  final bool statut;
  final DateTime? dateSouscriptionUtc;

  const SouscriptionMedicale({
    required this.id,
    required this.affilieId,
    required this.hopitalPartenaireId,
    required this.offreMedicaleHopitalId,
    required this.statut,
    this.dateSouscriptionUtc,
  });

  factory SouscriptionMedicale.fromJson(Map<String, dynamic> json) {
    return SouscriptionMedicale(
      id: MedicalJson.asInt(json['id']),
      affilieId: MedicalJson.asInt(json['affilieId']),
      hopitalPartenaireId: MedicalJson.asInt(json['hopitalPartenaireId']),
      offreMedicaleHopitalId: MedicalJson.asInt(json['offreMedicaleHopitalId']),
      statut: MedicalJson.asBool(json['statut']),
      dateSouscriptionUtc: MedicalJson.asDateOrNull(json['dateSouscriptionUtc']),
    );
  }
}

/// État d'affichage d'une période, dérivé des réponses serveur (aucun statut
/// serveur n'est inventé).
enum EtatPeriodeMedicale {
  aPayer('À payer'),
  paiementPartiel('Paiement partiel'),
  payeAVenir('Payé — à venir'),
  couvert('Couvert'),
  expire('Expiré'),
  droitsIndisponibles('Droits indisponibles');

  const EtatPeriodeMedicale(this.label);
  final String label;
}

class PeriodeCouvertureMedicale {
  final int id;
  final int souscriptionMedicaleId;

  /// Version figée à la préparation : prix et soins de cette période.
  final int versionOffreMedicaleId;
  final int annee;
  final int mois;
  final double montantDu;
  final double montantValide;
  final double soldeRestant;
  final int deviseId;
  final DateTime? dateDebutDroitsUtc;

  /// Borne de fin **exclusive** de la couverture.
  final DateTime? dateFinExclusiveUtc;

  /// Seule source de vérité pour l'ouverture des droits.
  final bool droitsOuverts;

  const PeriodeCouvertureMedicale({
    required this.id,
    required this.souscriptionMedicaleId,
    required this.versionOffreMedicaleId,
    required this.annee,
    required this.mois,
    required this.montantDu,
    required this.montantValide,
    required this.soldeRestant,
    required this.deviseId,
    this.dateDebutDroitsUtc,
    this.dateFinExclusiveUtc,
    required this.droitsOuverts,
  });

  factory PeriodeCouvertureMedicale.fromJson(Map<String, dynamic> json) {
    return PeriodeCouvertureMedicale(
      id: MedicalJson.asInt(json['id']),
      souscriptionMedicaleId: MedicalJson.asInt(json['souscriptionMedicaleId']),
      versionOffreMedicaleId: MedicalJson.asInt(json['versionOffreMedicaleId']),
      annee: MedicalJson.asInt(json['annee']),
      mois: MedicalJson.asInt(json['mois']),
      montantDu: MedicalJson.asDouble(json['montantDu']),
      montantValide: MedicalJson.asDouble(json['montantValide']),
      soldeRestant: MedicalJson.asDouble(json['soldeRestant']),
      deviseId: MedicalJson.asInt(json['deviseId']),
      dateDebutDroitsUtc: MedicalJson.asDateOrNull(json['dateDebutDroitsUtc']),
      dateFinExclusiveUtc: MedicalJson.asDateOrNull(json['dateFinExclusiveUtc']),
      droitsOuverts: MedicalJson.asBool(json['droitsOuverts']),
    );
  }

  bool get estSoldee => soldeRestant <= 0;

  /// « 10/2026 ».
  String get libelleMois => '${mois.toString().padLeft(2, '0')}/$annee';

  EtatPeriodeMedicale etat({DateTime? now}) {
    final instant = (now ?? DateTime.now()).toUtc();
    if (droitsOuverts) return EtatPeriodeMedicale.couvert;
    final fin = dateFinExclusiveUtc;
    if (fin != null && !instant.isBefore(fin)) return EtatPeriodeMedicale.expire;
    if (montantValide <= 0) return EtatPeriodeMedicale.aPayer;
    if (soldeRestant > 0) return EtatPeriodeMedicale.paiementPartiel;
    final debut = dateDebutDroitsUtc;
    if (debut != null && instant.isBefore(debut)) {
      return EtatPeriodeMedicale.payeAVenir;
    }
    // Soldée sans droits ouverts et sans cause lisible dans la réponse.
    return EtatPeriodeMedicale.droitsIndisponibles;
  }
}
