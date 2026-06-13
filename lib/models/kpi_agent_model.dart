// ============================================
// MODÈLE KPI AGENT
// ============================================

class KpiAgentModel {
  final int totalAffilies;
  final int collectesMois;
  final double totalCommissionsMois;
  final double totalCollectesMois;
  final int nouvellesAdhesionsMois;
  final int collectesEnAttente;
  final double tauxConversion;
  final double moyenneCollecte;
  final double objectifMois;
  final double progressionObjectif;

  KpiAgentModel({
    required this.totalAffilies,
    required this.collectesMois,
    required this.totalCommissionsMois,
    required this.totalCollectesMois,
    required this.nouvellesAdhesionsMois,
    required this.collectesEnAttente,
    required this.tauxConversion,
    required this.moyenneCollecte,
    required this.objectifMois,
    required this.progressionObjectif,
  });

  factory KpiAgentModel.fromJson(Map<String, dynamic> json) {
    return KpiAgentModel(
      totalAffilies: json['totalAffilies'] ?? 0,
      collectesMois: json['collectesMois'] ?? 0,
      totalCommissionsMois:
          (json['totalCommissionsMois'] as num?)?.toDouble() ?? 0.0,
      totalCollectesMois:
          (json['totalCollectesMois'] as num?)?.toDouble() ?? 0.0,
      nouvellesAdhesionsMois: json['nouvellesAdhesionsMois'] ?? 0,
      collectesEnAttente: json['collectesEnAttente'] ?? 0,
      tauxConversion: (json['tauxConversion'] as num?)?.toDouble() ?? 0.0,
      moyenneCollecte: (json['moyenneCollecte'] as num?)?.toDouble() ?? 0.0,
      objectifMois: (json['objectifMois'] as num?)?.toDouble() ?? 0.0,
      progressionObjectif:
          (json['progressionObjectif'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAffilies': totalAffilies,
      'collectesMois': collectesMois,
      'totalCommissionsMois': totalCommissionsMois,
      'totalCollectesMois': totalCollectesMois,
      'nouvellesAdhesionsMois': nouvellesAdhesionsMois,
      'collectesEnAttente': collectesEnAttente,
      'tauxConversion': tauxConversion,
      'moyenneCollecte': moyenneCollecte,
      'objectifMois': objectifMois,
      'progressionObjectif': progressionObjectif,
    };
  }

  // Formatted getters
  String get formattedTotalCollectes =>
      '${totalCollectesMois.toStringAsFixed(2)} USD';
  String get formattedCommissions =>
      '${totalCommissionsMois.toStringAsFixed(2)} USD';
  String get formattedMoyenneCollecte =>
      '${moyenneCollecte.toStringAsFixed(2)} USD';
  String get formattedObjectif => '${objectifMois.toStringAsFixed(2)} USD';
  String get formattedProgression =>
      '${progressionObjectif.toStringAsFixed(1)}%';
}
