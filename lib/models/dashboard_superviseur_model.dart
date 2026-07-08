// ============================================
// MODÈLE DASHBOARD SUPERVISEUR
// GET /api/DashboardSuperviseur/dashboard/{superviseurId}
// ============================================

dynamic _supField(Map<String, dynamic> json, String camelKey) {
  if (json.containsKey(camelKey)) return json[camelKey];
  if (camelKey.isEmpty) return null;
  final pascalKey = camelKey[0].toUpperCase() + camelKey.substring(1);
  return json[pascalKey];
}

double _supDouble(Map<String, dynamic> json, String key) {
  final value = _supField(json, key);
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _supInt(Map<String, dynamic> json, String key) {
  final value = _supField(json, key);
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _supString(Map<String, dynamic> json, String key) {
  final value = _supField(json, key);
  return value?.toString() ?? '';
}

DateTime? _supDateTime(Map<String, dynamic> json, String key) {
  final raw = _supField(json, key);
  if (raw == null) return null;
  final parsed = DateTime.tryParse(raw.toString());
  if (parsed == null) return null;
  if (parsed.year <= 1) return null;
  return parsed;
}

List<Map<String, dynamic>> _supListMap(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

class SuperviseurAgentPerformance {
  final int agentId;
  final String nomAgent;
  final double montantTotal;
  final int nombreTransactions;
  final double montantMoyen;
  final double tauxSucces;
  final double performanceMoyenne;
  final double objectifPersonnel;
  final double atteinteObjectif;
  final int rangEquipe;
  final double progression;
  final DateTime? derniereActivite;
  final int nombreJoursActifs;
  final double montantCommissions;
  final double netAPercevoir;
  final int totalAffilies;
  final double totalCollectes;
  final double totalCommissions;
  final int classement;
  final double progressionMois;
  final double progressionAnnee;
  final double tauxReussite;

  SuperviseurAgentPerformance({
    required this.agentId,
    required this.nomAgent,
    required this.montantTotal,
    required this.nombreTransactions,
    required this.montantMoyen,
    required this.tauxSucces,
    required this.performanceMoyenne,
    required this.objectifPersonnel,
    required this.atteinteObjectif,
    required this.rangEquipe,
    required this.progression,
    this.derniereActivite,
    required this.nombreJoursActifs,
    required this.montantCommissions,
    required this.netAPercevoir,
    required this.totalAffilies,
    required this.totalCollectes,
    required this.totalCommissions,
    required this.classement,
    required this.progressionMois,
    required this.progressionAnnee,
    required this.tauxReussite,
  });

  factory SuperviseurAgentPerformance.fromJson(Map<String, dynamic> json) {
    final nom = _supString(json, 'nomAgent');
    final agentNom = _supString(json, 'agentNom');
    final nomComplet = _supString(json, 'nomComplet');
    final agentId = _supInt(json, 'agentId');
    return SuperviseurAgentPerformance(
      agentId: agentId != 0 ? agentId : _supInt(json, 'idAgent'),
      nomAgent: nom.isNotEmpty
          ? nom
          : (agentNom.isNotEmpty ? agentNom : nomComplet),
      montantTotal: _supDouble(json, 'montantTotal'),
      nombreTransactions: _supInt(json, 'nombreTransactions'),
      montantMoyen: _supDouble(json, 'montantMoyen'),
      tauxSucces: _supDouble(json, 'tauxSucces'),
      performanceMoyenne: _supDouble(json, 'performanceMoyenne'),
      objectifPersonnel: _supDouble(json, 'objectifPersonnel'),
      atteinteObjectif: _supDouble(json, 'atteinteObjectif'),
      rangEquipe: _supInt(json, 'rangEquipe'),
      progression: _supDouble(json, 'progression'),
      derniereActivite: _supDateTime(json, 'derniereActivite'),
      nombreJoursActifs: _supInt(json, 'nombreJoursActifs'),
      montantCommissions: _supDouble(json, 'montantCommissions'),
      netAPercevoir: _supDouble(json, 'netAPercevoir'),
      totalAffilies: _supInt(json, 'totalAffilies'),
      totalCollectes: _supDouble(json, 'totalCollectes'),
      totalCommissions: _supDouble(json, 'totalCommissions'),
      classement: _supInt(json, 'classement'),
      progressionMois: _supDouble(json, 'progressionMois'),
      progressionAnnee: _supDouble(json, 'progressionAnnee'),
      tauxReussite: _supDouble(json, 'tauxReussite'),
    );
  }
}

class SuperviseurTendanceEquipe {
  final int superviseurId;
  final String periode;
  final double montantPeriode;
  final int nombreAgentsPeriode;
  final double performanceMoyennePeriode;
  final double tauxSuccesPeriode;
  final double croissance;
  final double objectifPeriode;
  final double atteinteObjectifPeriode;
  final int nombreTransactionsPeriode;
  final double montantCommissionsPeriode;

  SuperviseurTendanceEquipe({
    required this.superviseurId,
    required this.periode,
    required this.montantPeriode,
    required this.nombreAgentsPeriode,
    required this.performanceMoyennePeriode,
    required this.tauxSuccesPeriode,
    required this.croissance,
    required this.objectifPeriode,
    required this.atteinteObjectifPeriode,
    required this.nombreTransactionsPeriode,
    required this.montantCommissionsPeriode,
  });

  factory SuperviseurTendanceEquipe.fromJson(Map<String, dynamic> json) {
    return SuperviseurTendanceEquipe(
      superviseurId: _supInt(json, 'superviseurId'),
      periode: _supString(json, 'periode'),
      montantPeriode: _supDouble(json, 'montantPeriode'),
      nombreAgentsPeriode: _supInt(json, 'nombreAgentsPeriode'),
      performanceMoyennePeriode: _supDouble(json, 'performanceMoyennePeriode'),
      tauxSuccesPeriode: _supDouble(json, 'tauxSuccesPeriode'),
      croissance: _supDouble(json, 'croissance'),
      objectifPeriode: _supDouble(json, 'objectifPeriode'),
      atteinteObjectifPeriode: _supDouble(json, 'atteinteObjectifPeriode'),
      nombreTransactionsPeriode: _supInt(json, 'nombreTransactionsPeriode'),
      montantCommissionsPeriode: _supDouble(json, 'montantCommissionsPeriode'),
    );
  }
}

class SuperviseurRapportPerformance {
  final int superviseurId;
  final String nomSuperviseur;
  final DateTime? debutPeriode;
  final DateTime? finPeriode;
  final int nombreAgents;
  final double montantTotalEquipe;
  final double montantMoyenParAgent;
  final int totalTransactionsEquipe;
  final double tauxSuccesEquipe;
  final double objectifEquipe;
  final double atteinteObjectifEquipe;
  final List<SuperviseurAgentPerformance> performancesAgents;
  final double croissanceParRapportPrecedent;
  final int rangParmiSuperviseurs;
  final String commentairePerformance;
  final DateTime? dateGenerationRapport;

  SuperviseurRapportPerformance({
    required this.superviseurId,
    required this.nomSuperviseur,
    this.debutPeriode,
    this.finPeriode,
    required this.nombreAgents,
    required this.montantTotalEquipe,
    required this.montantMoyenParAgent,
    required this.totalTransactionsEquipe,
    required this.tauxSuccesEquipe,
    required this.objectifEquipe,
    required this.atteinteObjectifEquipe,
    required this.performancesAgents,
    required this.croissanceParRapportPrecedent,
    required this.rangParmiSuperviseurs,
    required this.commentairePerformance,
    this.dateGenerationRapport,
  });

  factory SuperviseurRapportPerformance.fromJson(Map<String, dynamic> json) {
    return SuperviseurRapportPerformance(
      superviseurId: _supInt(json, 'superviseurId'),
      nomSuperviseur: _supString(json, 'nomSuperviseur'),
      debutPeriode: _supDateTime(json, 'debutPeriode'),
      finPeriode: _supDateTime(json, 'finPeriode'),
      nombreAgents: _supInt(json, 'nombreAgents'),
      montantTotalEquipe: _supDouble(json, 'montantTotalEquipe'),
      montantMoyenParAgent: _supDouble(json, 'montantMoyenParAgent'),
      totalTransactionsEquipe: _supInt(json, 'totalTransactionsEquipe'),
      tauxSuccesEquipe: _supDouble(json, 'tauxSuccesEquipe'),
      objectifEquipe: _supDouble(json, 'objectifEquipe'),
      atteinteObjectifEquipe: _supDouble(json, 'atteinteObjectifEquipe'),
      performancesAgents: _supListMap(_supField(json, 'performancesAgents'))
          .map(SuperviseurAgentPerformance.fromJson)
          .toList(),
      croissanceParRapportPrecedent:
          _supDouble(json, 'croissanceParRapportPrecedent'),
      rangParmiSuperviseurs: _supInt(json, 'rangParmiSuperviseurs'),
      commentairePerformance: _supString(json, 'commentairePerformance'),
      dateGenerationRapport: _supDateTime(json, 'dateGenerationRapport'),
    );
  }
}

class StatsSuperviseur {
  final int superviseurId;
  final String nomSuperviseur;
  final int nombreAgentsDirects;
  final int nombreAgentsTotal;
  final double montantTotalEquipe;
  final double performanceMoyenneEquipe;
  final double montantTotalSuperviseur;
  final int nombreTransactionsSuperviseur;
  final double tauxSuccesEquipe;
  final double objectifEquipe;
  final double atteinteObjectifEquipe;
  final List<SuperviseurAgentPerformance> agentsSupervises;
  final DateTime? derniereMiseAJour;

  StatsSuperviseur({
    required this.superviseurId,
    required this.nomSuperviseur,
    required this.nombreAgentsDirects,
    required this.nombreAgentsTotal,
    required this.montantTotalEquipe,
    required this.performanceMoyenneEquipe,
    required this.montantTotalSuperviseur,
    required this.nombreTransactionsSuperviseur,
    required this.tauxSuccesEquipe,
    required this.objectifEquipe,
    required this.atteinteObjectifEquipe,
    required this.agentsSupervises,
    this.derniereMiseAJour,
  });

  factory StatsSuperviseur.fromJson(Map<String, dynamic> json) {
    return StatsSuperviseur(
      superviseurId: _supInt(json, 'superviseurId'),
      nomSuperviseur: _supString(json, 'nomSuperviseur'),
      nombreAgentsDirects: _supInt(json, 'nombreAgentsDirects'),
      nombreAgentsTotal: _supInt(json, 'nombreAgentsTotal'),
      montantTotalEquipe: _supDouble(json, 'montantTotalEquipe'),
      performanceMoyenneEquipe: _supDouble(json, 'performanceMoyenneEquipe'),
      montantTotalSuperviseur: _supDouble(json, 'montantTotalSuperviseur'),
      nombreTransactionsSuperviseur:
          _supInt(json, 'nombreTransactionsSuperviseur'),
      tauxSuccesEquipe: _supDouble(json, 'tauxSuccesEquipe'),
      objectifEquipe: _supDouble(json, 'objectifEquipe'),
      atteinteObjectifEquipe: _supDouble(json, 'atteinteObjectifEquipe'),
      agentsSupervises: _supListMap(_supField(json, 'agentsSupervises'))
          .map(SuperviseurAgentPerformance.fromJson)
          .toList(),
      derniereMiseAJour: _supDateTime(json, 'derniereMiseAJour'),
    );
  }

  String get formattedMontantEquipe =>
      '${montantTotalEquipe.toStringAsFixed(0)} CDF';
  String get formattedPerformance =>
      '${performanceMoyenneEquipe.toStringAsFixed(1)}%';
  String get formattedAtteinteObjectif =>
      '${atteinteObjectifEquipe.toStringAsFixed(1)}%';
  String get formattedTauxSucces => '${tauxSuccesEquipe.toStringAsFixed(1)}%';
}

/// GET /api/DashboardSuperviseur/indicateurs-performance/{superviseurId}
class SuperviseurIndicateursPerformance {
  final String performanceGlobale;
  final String tendancePerformance;
  final String efficaciteEquipe;
  final String niveauActivite;
  final String niveauRisque;
  final List<String> recommandations;

  SuperviseurIndicateursPerformance({
    required this.performanceGlobale,
    required this.tendancePerformance,
    required this.efficaciteEquipe,
    required this.niveauActivite,
    required this.niveauRisque,
    required this.recommandations,
  });

  factory SuperviseurIndicateursPerformance.fromJson(
    Map<String, dynamic> json,
  ) {
    final raw = _supField(json, 'recommandations');
    return SuperviseurIndicateursPerformance(
      performanceGlobale: _supString(json, 'performanceGlobale'),
      tendancePerformance: _supString(json, 'tendancePerformance'),
      efficaciteEquipe: _supString(json, 'efficaciteEquipe'),
      niveauActivite: _supString(json, 'niveauActivite'),
      niveauRisque: _supString(json, 'niveauRisque'),
      recommandations: raw is List
          ? raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
          : const [],
    );
  }
}

class DashboardSuperviseurModel {
  final StatsSuperviseur? statsSuperviseur;
  final List<SuperviseurAgentPerformance> topAgents;
  final List<SuperviseurTendanceEquipe> tendancesEquipe;
  final SuperviseurRapportPerformance? rapportPerformance;
  final DateTime? derniereMiseAJour;
  final double montantTotalHierarchie;
  final int nombreTotalAgentsHierarchie;
  final double performanceMoyenneHierarchie;

  DashboardSuperviseurModel({
    this.statsSuperviseur,
    required this.topAgents,
    required this.tendancesEquipe,
    this.rapportPerformance,
    this.derniereMiseAJour,
    required this.montantTotalHierarchie,
    required this.nombreTotalAgentsHierarchie,
    required this.performanceMoyenneHierarchie,
  });

  factory DashboardSuperviseurModel.fromJson(Map<String, dynamic> json) {
    final statsRaw = _supField(json, 'statsSuperviseur');
    final rapportRaw = _supField(json, 'rapportPerformance');

    return DashboardSuperviseurModel(
      statsSuperviseur: statsRaw is Map
          ? StatsSuperviseur.fromJson(Map<String, dynamic>.from(statsRaw))
          : null,
      topAgents: _supListMap(_supField(json, 'topAgents'))
          .map(SuperviseurAgentPerformance.fromJson)
          .toList(),
      tendancesEquipe: _supListMap(_supField(json, 'tendancesEquipe'))
          .map(SuperviseurTendanceEquipe.fromJson)
          .toList(),
      rapportPerformance: rapportRaw is Map
          ? SuperviseurRapportPerformance.fromJson(
              Map<String, dynamic>.from(rapportRaw),
            )
          : null,
      derniereMiseAJour: _supDateTime(json, 'derniereMiseAJour'),
      montantTotalHierarchie: _supDouble(json, 'montantTotalHierarchie'),
      nombreTotalAgentsHierarchie: _supInt(json, 'nombreTotalAgentsHierarchie'),
      performanceMoyenneHierarchie:
          _supDouble(json, 'performanceMoyenneHierarchie'),
    );
  }

  StatsSuperviseur? get stats => statsSuperviseur;

  int get superviseurId => stats?.superviseurId ?? 0;
  String get nomSuperviseur => stats?.nomSuperviseur ?? '';
  int get nombreAgentsDirects => stats?.nombreAgentsDirects ?? 0;
  int get nombreAgentsTotal =>
      stats?.nombreAgentsTotal ?? nombreTotalAgentsHierarchie;
  double get montantTotalEquipe =>
      stats?.montantTotalEquipe ?? montantTotalHierarchie;
  double get performanceMoyenneEquipe =>
      stats?.performanceMoyenneEquipe ?? performanceMoyenneHierarchie;
  double get objectifEquipe =>
      stats?.objectifEquipe ?? rapportPerformance?.objectifEquipe ?? 0;
  double get atteinteObjectifEquipe =>
      stats?.atteinteObjectifEquipe ??
      rapportPerformance?.atteinteObjectifEquipe ??
      0;
  int get nombreTransactions =>
      stats?.nombreTransactionsSuperviseur ??
      rapportPerformance?.totalTransactionsEquipe ??
      0;
  double get tauxSuccesEquipe =>
      stats?.tauxSuccesEquipe ?? rapportPerformance?.tauxSuccesEquipe ?? 0;

  List<SuperviseurAgentPerformance> get agentsEquipe {
    if (stats?.agentsSupervises.isNotEmpty == true) {
      return stats!.agentsSupervises;
    }
    if (topAgents.isNotEmpty) return topAgents;
    return rapportPerformance?.performancesAgents ?? const [];
  }

  SuperviseurTendanceEquipe? get derniereTendance {
    if (tendancesEquipe.isEmpty) return null;
    return tendancesEquipe.last;
  }

  String get formattedMontantEquipe =>
      '${montantTotalEquipe.toStringAsFixed(0)} CDF';
  String get formattedPerformance =>
      '${performanceMoyenneEquipe.toStringAsFixed(1)}%';
  String get formattedAtteinteObjectif =>
      '${atteinteObjectifEquipe.toStringAsFixed(1)}%';
  String get formattedTauxSucces => '${tauxSuccesEquipe.toStringAsFixed(1)}%';
}

/// GET /api/Superviseur/hierarchie/{superviseurId}
class SuperviseurHierarchieModel {
  final int superviseurId;
  final String nomSuperviseur;
  final int niveauHierarchique;
  final List<SuperviseurAgentPerformance> agentsSupervises;
  final List<SuperviseurHierarchieModel> sousSuperviseurs;
  final int totalAgentsDansHierarchie;
  final double montantTotalHierarchie;

  SuperviseurHierarchieModel({
    required this.superviseurId,
    required this.nomSuperviseur,
    required this.niveauHierarchique,
    required this.agentsSupervises,
    required this.sousSuperviseurs,
    required this.totalAgentsDansHierarchie,
    required this.montantTotalHierarchie,
  });

  factory SuperviseurHierarchieModel.fromJson(Map<String, dynamic> json) {
    return SuperviseurHierarchieModel(
      superviseurId: _supInt(json, 'superviseurId'),
      nomSuperviseur: _supString(json, 'nomSuperviseur'),
      niveauHierarchique: _supInt(json, 'niveauHierarchique'),
      agentsSupervises: _supListMap(_supField(json, 'agentsSupervises'))
          .map(SuperviseurAgentPerformance.fromJson)
          .toList(),
      sousSuperviseurs: _supListMap(_supField(json, 'sousSuperviseurs'))
          .map(SuperviseurHierarchieModel.fromJson)
          .toList(),
      totalAgentsDansHierarchie: _supInt(json, 'totalAgentsDansHierarchie'),
      montantTotalHierarchie: _supDouble(json, 'montantTotalHierarchie'),
    );
  }

  /// Agents directs + agents des sous-superviseurs (récursif).
  List<SuperviseurAgentPerformance> get allAgents {
    final result = <SuperviseurAgentPerformance>[];
    result.addAll(agentsSupervises);
    for (final sub in sousSuperviseurs) {
      result.addAll(sub.allAgents);
    }
    return result;
  }

  String get formattedMontantHierarchie =>
      '${montantTotalHierarchie.toStringAsFixed(2)}';
}
