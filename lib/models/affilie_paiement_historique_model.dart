// GET /api/Affilie/paiements/historique
// GET /api/Collecte/by-agent/{agentId}

import '../utils/currency_formatter.dart';

class AffiliePaiementHistoriqueModel {
  final int idCollecte;
  final String typeCollecte;
  final int fraisId;
  final String fraisLibelle;
  final double fraisMontant;
  final int cotisationAffilieId;
  final String cotisationPeriodicite;
  final double cotisationMontantReference;
  final int cotisationTypeAdhesionId;
  final String cotisationTypeAdhesionLibelle;
  final int affilieId;
  final String affilieNom;
  final int agentId;
  final String agentNom;
  final double montant;
  final String referencePaiement;
  final String modePaiement;
  final String operateur;
  final String statutPaiement;
  final int souscriptionPrestationId;
  final String prestationLibelle;
  final double montantRecu;
  final double montantAttendu;
  final int deviseId;
  final String deviseNom;
  final String deviseCode;
  final DateTime? dateCollecte;
  final int mois;
  final int annee;
  final String observation;
  final DateTime? dateCreation;
  final DateTime? dateModification;
  final bool statut;

  AffiliePaiementHistoriqueModel({
    required this.idCollecte,
    required this.typeCollecte,
    required this.fraisId,
    required this.fraisLibelle,
    required this.fraisMontant,
    required this.cotisationAffilieId,
    required this.cotisationPeriodicite,
    required this.cotisationMontantReference,
    required this.cotisationTypeAdhesionId,
    required this.cotisationTypeAdhesionLibelle,
    required this.affilieId,
    required this.affilieNom,
    required this.agentId,
    required this.agentNom,
    required this.montant,
    required this.referencePaiement,
    required this.modePaiement,
    required this.operateur,
    required this.statutPaiement,
    required this.souscriptionPrestationId,
    required this.prestationLibelle,
    required this.montantRecu,
    required this.montantAttendu,
    required this.deviseId,
    required this.deviseNom,
    required this.deviseCode,
    this.dateCollecte,
    required this.mois,
    required this.annee,
    required this.observation,
    this.dateCreation,
    this.dateModification,
    required this.statut,
  });

  factory AffiliePaiementHistoriqueModel.fromJson(Map<String, dynamic> json) {
    return AffiliePaiementHistoriqueModel(
      idCollecte: _int(json['idCollecte']),
      typeCollecte: json['typeCollecte']?.toString() ?? '',
      fraisId: _int(json['fraisId']),
      fraisLibelle: json['fraisLibelle']?.toString() ?? '',
      fraisMontant: _double(json['fraisMontant']),
      cotisationAffilieId: _int(json['cotisationAffilieId']),
      cotisationPeriodicite: json['cotisationPeriodicite']?.toString() ?? '',
      cotisationMontantReference:
          _double(json['cotisationMontantReference']),
      cotisationTypeAdhesionId: _int(json['cotisationTypeAdhesionId']),
      cotisationTypeAdhesionLibelle:
          json['cotisationTypeAdhesionLibelle']?.toString() ?? '',
      affilieId: _int(json['affilieId']),
      affilieNom: json['affilieNom']?.toString() ?? '',
      agentId: _int(json['agentId']),
      agentNom: json['agentNom']?.toString() ?? '',
      montant: _double(json['montant']),
      referencePaiement: json['referencePaiement']?.toString() ?? '',
      modePaiement: json['modePaiement']?.toString() ?? '',
      operateur: json['operateur']?.toString() ?? '',
      statutPaiement: json['statutPaiement']?.toString() ?? '',
      souscriptionPrestationId: _int(json['souscriptionPrestationId']),
      prestationLibelle: json['prestationLibelle']?.toString() ?? '',
      montantRecu: _double(json['montantRecu']),
      montantAttendu: _double(json['montantAttendu']),
      deviseId: _int(json['deviseId']),
      deviseNom: json['deviseNom']?.toString() ?? '',
      deviseCode: json['deviseCode']?.toString() ?? '',
      dateCollecte: _date(json['dateCollecte']),
      mois: _int(json['mois']),
      annee: _int(json['annee']),
      observation: json['observation']?.toString() ?? '',
      dateCreation: _date(json['dateCreation']),
      dateModification: _date(json['dateModification']),
      statut: _bool(json['statut']),
    );
  }

  String get displayTitle {
    if (prestationLibelle.trim().isNotEmpty) return prestationLibelle.trim();
    if (fraisLibelle.trim().isNotEmpty) return fraisLibelle.trim();
    if (cotisationTypeAdhesionLibelle.trim().isNotEmpty) {
      return cotisationTypeAdhesionLibelle.trim();
    }
    if (typeCollecte.trim().isNotEmpty) return _humanizeTypeCollecte(typeCollecte);
    return 'Paiement';
  }

  String get formattedMontant {
    return CurrencyFormatter.formatMovementAmount(
      amount: montant,
      deviseId: deviseId > 0 ? deviseId : null,
      deviseCode: deviseCode.isNotEmpty ? deviseCode : null,
      withSign: false,
    );
  }

  String get typeCollecteLabel => _humanizeTypeCollecte(typeCollecte);

  static String _humanizeTypeCollecte(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return 'Collecte';
    if (normalized == 'frais') return 'Frais';
    if (normalized == 'souscription') return 'Souscription';
    if (normalized == 'cotisation') return 'Cotisation';
    return value.trim().replaceAll('_', ' ');
  }

  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static double _double(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  static bool _bool(dynamic v) {
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    return false;
  }

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}
