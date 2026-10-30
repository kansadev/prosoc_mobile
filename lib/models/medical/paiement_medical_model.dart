import 'medical_json.dart';

/// Modes de paiement acceptés par `POST /api/PaiementMedical`.
abstract final class PaiementMedicalModes {
  // Encaissement synchrone par un opérateur (jamais par un membre).
  static const espece = 'ESPECE';
  static const cheque = 'CHEQUE';
  static const virementBancaire = 'VIREMENT_BANCAIRE';
  static const virtualAccount = 'VIRTUAL_ACCOUNT';

  // Initiation électronique (membre ou opérateur).
  static const mobileMoney = 'MOBILE_MONEY';
  static const carteBancaire = 'CARTE_BANCAIRE';

  static const Map<String, String> guichet = {
    virtualAccount: 'Compte virtuel',
    espece: 'Espèces',
    cheque: 'Chèque',
    virementBancaire: 'Virement bancaire',
  };

  /// `CARTE_BANCAIRE_MOKO` n'est pas proposé : pas d'intégration Moko côté app.
  static const Map<String, String> electronique = {
    mobileMoney: 'Mobile money',
    carteBancaire: 'Carte',
  };

  /// Chèque / virement : réception des fonds à confirmer avant saisie.
  static bool exigeConfirmationFonds(String mode) =>
      mode == cheque || mode == virementBancaire;
}

/// Encaissement finalisé (`201` du guichet, `GET PaiementMedical/{id}`).
class PaiementMedicalRead {
  final String idPaiement;
  final int? collecteId;
  final int periodeCouvertureMedicaleId;

  /// Montant dans la devise de paiement.
  final double montant;
  final int deviseId;

  /// Montant crédité sur la période, dans la devise du tarif.
  final double montantCredite;
  final int deviseTarifId;

  const PaiementMedicalRead({
    required this.idPaiement,
    this.collecteId,
    required this.periodeCouvertureMedicaleId,
    required this.montant,
    required this.deviseId,
    required this.montantCredite,
    required this.deviseTarifId,
  });

  factory PaiementMedicalRead.fromJson(Map<String, dynamic> json) {
    return PaiementMedicalRead(
      idPaiement: MedicalJson.asString(json['idPaiement']),
      collecteId: MedicalJson.asIntOrNull(json['collecteId']),
      periodeCouvertureMedicaleId: MedicalJson.asInt(
        json['periodeCouvertureMedicaleId'],
      ),
      montant: MedicalJson.asDouble(json['montant']),
      deviseId: MedicalJson.asInt(json['deviseId']),
      montantCredite: MedicalJson.asDouble(json['montantCredite']),
      deviseTarifId: MedicalJson.asInt(json['deviseTarifId']),
    );
  }
}

/// Corps d'un encaissement au guichet. Le même [idPaiement] et le même corps
/// doivent être renvoyés pour reprendre après un timeout.
class PaiementMedicalGuichetRequest {
  final String idPaiement;
  final int periodeCouvertureMedicaleId;
  final double montant;
  final int deviseId;
  final String modePaiement;

  const PaiementMedicalGuichetRequest({
    required this.idPaiement,
    required this.periodeCouvertureMedicaleId,
    required this.montant,
    required this.deviseId,
    required this.modePaiement,
  });

  Map<String, dynamic> toJson() => {
    'idPaiement': idPaiement,
    'periodeCouvertureMedicaleId': periodeCouvertureMedicaleId,
    'montant': montant,
    'deviseId': deviseId,
    'modePaiement': modePaiement,
  };
}
