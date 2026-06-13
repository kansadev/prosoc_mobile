// ============================================
// MODELE DEMANDE RETRAIT AGENT
// ============================================

class DemandeRetraitAgentModel {
  final int id;
  final int agentId;
  final double montant;
  final String statut;
  final DateTime dateCreation;
  final DateTime? dateValidation;
  final String? motifRejet;
  final String? tokenRetrait;
  final DateTime? dateUtilisation;
  final String agentNom;
  final String agentMatricule;

  DemandeRetraitAgentModel({
    required this.id,
    required this.agentId,
    required this.montant,
    required this.statut,
    required this.dateCreation,
    this.dateValidation,
    this.motifRejet,
    this.tokenRetrait,
    this.dateUtilisation,
    required this.agentNom,
    required this.agentMatricule,
  });

  factory DemandeRetraitAgentModel.fromJson(Map<String, dynamic> json) {
    return DemandeRetraitAgentModel(
      id: json['id'] ?? 0,
      agentId: json['agentId'] ?? 0,
      montant: (json['montant'] ?? 0).toDouble(),
      statut: json['statut'] ?? '',
      dateCreation: DateTime.parse(json['dateCreation'] ?? DateTime.now().toIso8601String()),
      dateValidation: json['dateValidation'] != null ? DateTime.parse(json['dateValidation']) : null,
      motifRejet: json['motifRejet'],
      tokenRetrait: json['tokenRetrait'],
      dateUtilisation: json['dateUtilisation'] != null ? DateTime.parse(json['dateUtilisation']) : null,
      agentNom: json['agentNom'] ?? '',
      agentMatricule: json['agentMatricule'] ?? '',
    );
  }
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
