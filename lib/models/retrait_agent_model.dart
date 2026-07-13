// ============================================
// MODELE DEMANDE RETRAIT AGENT
// ============================================

import '../utils/currency_formatter.dart';

class DemandeRetraitAgentModel {
  final int idDemande;
  final int agentId;
  final String agentNom;
  final String agentMatricule;
  final double montantDemande;
  final String typeRetrait;
  final String statutDemande;
  final String motifRetrait;
  final String motifRejet;
  final int deviseId;
  final String deviseCode;
  final String deviseSymbole;
  final DateTime? dateDemande;
  final DateTime? dateValidation;
  final DateTime? dateTraitement;
  final int agentValidationId;
  final String agentValidationNom;
  final int jetonRetraitId;
  final String jetonRetraitCode;
  final DateTime? dateCreation;
  final DateTime? dateModification;
  final bool statut;

  DemandeRetraitAgentModel({
    required this.idDemande,
    required this.agentId,
    required this.agentNom,
    required this.agentMatricule,
    required this.montantDemande,
    required this.typeRetrait,
    required this.statutDemande,
    required this.motifRetrait,
    required this.motifRejet,
    required this.deviseId,
    required this.deviseCode,
    required this.deviseSymbole,
    this.dateDemande,
    this.dateValidation,
    this.dateTraitement,
    required this.agentValidationId,
    required this.agentValidationNom,
    required this.jetonRetraitId,
    required this.jetonRetraitCode,
    this.dateCreation,
    this.dateModification,
    required this.statut,
  });

  DateTime? get dateReference =>
      dateDemande ?? dateCreation ?? dateValidation ?? dateTraitement;

  bool get hasJeton => jetonRetraitCode.trim().isNotEmpty;

  bool get isEnAttente {
    final s = statutDemande.trim().toUpperCase();
    return s.contains('ATTENTE') || s.contains('PENDING') || s.isEmpty;
  }

  bool get isValidee {
    final s = statutDemande.trim().toUpperCase();
    return s.contains('VALID') ||
        s.contains('APPROUV') ||
        hasJeton && !s.contains('TRAIT');
  }

  bool get isRejetee {
    final s = statutDemande.trim().toUpperCase();
    return s.contains('REJET');
  }

  String get formattedMontant => CurrencyFormatter.format(
        amount: montantDemande,
        deviseId: deviseId,
        deviseCode: deviseCode,
        deviseSymbole: deviseSymbole,
      );

  factory DemandeRetraitAgentModel.fromJson(Map<String, dynamic> json) {
    return DemandeRetraitAgentModel(
      idDemande: _retraitInt(json['idDemande'] ?? json['id']),
      agentId: _retraitInt(json['agentId']),
      agentNom: (json['agentNom'] ?? '').toString(),
      agentMatricule: (json['agentMatricule'] ?? '').toString(),
      montantDemande: _retraitDouble(json['montantDemande'] ?? json['montant']),
      typeRetrait: (json['typeRetrait'] ?? '').toString(),
      statutDemande: (json['statutDemande'] ?? json['statut'] ?? '').toString(),
      motifRetrait: (json['motifRetrait'] ?? '').toString(),
      motifRejet: (json['motifRejet'] ?? '').toString(),
      deviseId: _retraitInt(json['deviseId']),
      deviseCode: (json['deviseCode'] ?? '').toString(),
      deviseSymbole: (json['deviseSymbole'] ?? '').toString(),
      dateDemande: _retraitDate(json['dateDemande']),
      dateValidation: _retraitDate(json['dateValidation']),
      dateTraitement: _retraitDate(json['dateTraitement']),
      agentValidationId: _retraitInt(json['agentValidationId']),
      agentValidationNom: (json['agentValidationNom'] ?? '').toString(),
      jetonRetraitId: _retraitInt(json['jetonRetraitId']),
      jetonRetraitCode: (json['jetonRetraitCode'] ?? json['tokenRetrait'] ?? '')
          .toString(),
      dateCreation: _retraitDate(json['dateCreation']),
      dateModification: _retraitDate(json['dateModification']),
      statut: json['statut'] == true || json['statut'] == 1,
    );
  }
}

int _retraitInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _retraitDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _retraitDate(dynamic value) {
  if (value == null) return null;
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

/// Réponse POST valider-et-generer-jeton / POST création demande
class RetraitWorkflowResultModel {
  final bool succes;
  final String message;
  final int? demandeId;
  final int? jetonId;
  final String? jetonCode;
  final double? montantRetrait;
  final String? typeRetrait;
  final DateTime? dateEmission;
  final DateTime? dateExpiration;

  RetraitWorkflowResultModel({
    required this.succes,
    required this.message,
    this.demandeId,
    this.jetonId,
    this.jetonCode,
    this.montantRetrait,
    this.typeRetrait,
    this.dateEmission,
    this.dateExpiration,
  });

  factory RetraitWorkflowResultModel.fromJson(Map<String, dynamic> json) {
    return RetraitWorkflowResultModel(
      succes: json['succes'] == true || json['Succes'] == true,
      message: (json['message'] ?? json['Message'] ?? '').toString(),
      demandeId: _retraitNullableInt(json['demandeId'] ?? json['DemandeId']),
      jetonId: _retraitNullableInt(json['jetonId'] ?? json['JetonId']),
      jetonCode: (json['jetonCode'] ?? json['JetonCode'])?.toString(),
      montantRetrait:
          _retraitDouble(json['montantRetrait'] ?? json['MontantRetrait']),
      typeRetrait: json['typeRetrait']?.toString(),
      dateEmission: _retraitDate(json['dateEmission'] ?? json['DateEmission']),
      dateExpiration:
          _retraitDate(json['dateExpiration'] ?? json['DateExpiration']),
    );
  }
}

int? _retraitNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

// ============================================
// MODELE JETON RETRAIT
// ============================================

class JetonRetraitModel {
  final int id;
  final String jeton;
  final int demandeRetraitId;
  final bool estUtilise;
  final DateTime dateExpiration;
  final DateTime dateUtilisation;

  JetonRetraitModel({
    required this.id,
    required this.jeton,
    required this.demandeRetraitId,
    required this.estUtilise,
    required this.dateExpiration,
    required this.dateUtilisation,
  });

  factory JetonRetraitModel.fromJson(Map<String, dynamic> json) {
    return JetonRetraitModel(
      id: json['id'] ?? 0,
      jeton: json['jeton'] ?? '',
      demandeRetraitId: json['demandeRetraitId'] ?? 0,
      estUtilise: json['estUtilise'] ?? false,
      dateExpiration: DateTime.parse(json['dateExpiration'] ?? DateTime.now().toIso8601String()),
      dateUtilisation: DateTime.parse(json['dateUtilisation'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// ============================================
// MODELE DASHBOARD AFFILIE
// ============================================

class DashboardAffilieModel {
  // KPIs principaux
  final double totalCotisations;
  final double totalPrestations;
  final double soldeActuel;
  final int nombreBeneficiaires;
  
  // Statistiques
  final double tauxUtilisation;
  final int nombrePrestationsEnCours;
  final DateTime? lastCotisation;
  final DateTime? lastPrestation;
  
  // Listes
  final List<CotisationPeriode> historiqueCotisations;
  final List<PrestationPeriode> historiquePrestations;

  DashboardAffilieModel({
    required this.totalCotisations,
    required this.totalPrestations,
    required this.soldeActuel,
    required this.nombreBeneficiaires,
    required this.tauxUtilisation,
    required this.nombrePrestationsEnCours,
    this.lastCotisation,
    this.lastPrestation,
    required this.historiqueCotisations,
    required this.historiquePrestations,
  });

  factory DashboardAffilieModel.fromJson(Map<String, dynamic> json) {
    return DashboardAffilieModel(
      totalCotisations: (json['totalCotisations'] ?? 0).toDouble(),
      totalPrestations: (json['totalPrestations'] ?? 0).toDouble(),
      soldeActuel: (json['soldeActuel'] ?? 0).toDouble(),
      nombreBeneficiaires: json['nombreBeneficiaires'] ?? 0,
      tauxUtilisation: (json['tauxUtilisation'] ?? 0).toDouble(),
      nombrePrestationsEnCours: json['nombrePrestationsEnCours'] ?? 0,
      lastCotisation: json['derniereCotisation'] != null ? DateTime.parse(json['derniereCotisation']) : null,
      lastPrestation: json['dernierePrestation'] != null ? DateTime.parse(json['dernierePrestation']) : null,
      historiqueCotisations: (json['historiqueCotisations'] as List<dynamic>?)
          ?.map((e) => CotisationPeriode.fromJson(e))
          .toList() ?? [],
      historiquePrestations: (json['historiquePrestations'] as List<dynamic>?)
          ?.map((e) => PrestationPeriode.fromJson(e))
          .toList() ?? [],
          
    );
  }
}

class CotisationPeriode {
  final String periode;
  final double montant;
  final DateTime date;

  CotisationPeriode({
    required this.periode,
    required this.montant,
    required this.date,
  });

  factory CotisationPeriode.fromJson(Map<String, dynamic> json) {
    return CotisationPeriode(
      periode: json['periode'] ?? '',
      montant: (json['montant'] ?? 0).toDouble(),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class PrestationPeriode {
  final String periode;
  final double montant;
  final DateTime date;
  final String type;

  PrestationPeriode({
    required this.periode,
    required this.montant,
    required this.date,
    required this.type,
  });

  factory PrestationPeriode.fromJson(Map<String, dynamic> json) {
    return PrestationPeriode(
      periode: json['periode'] ?? '',
      montant: (json['montant'] ?? 0).toDouble(),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      type: json['type'] ?? '',
    );
  }
}
