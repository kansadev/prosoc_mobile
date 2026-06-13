// ============================================
// MODÈLE DASHBOARD AGENT
// ============================================

dynamic _dashField(Map<String, dynamic> json, String camelKey) {
  if (json.containsKey(camelKey)) return json[camelKey];
  if (camelKey.isEmpty) return null;
  final pascalKey = camelKey[0].toUpperCase() + camelKey.substring(1);
  return json[pascalKey];
}

double _dashDouble(Map<String, dynamic> json, String key) {
  final value = _dashField(json, key);
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _dashInt(Map<String, dynamic> json, String key) {
  final value = _dashField(json, key);
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _dashString(Map<String, dynamic> json, String key) {
  final value = _dashField(json, key);
  return value?.toString() ?? '';
}

Map<String, dynamic>? unwrapDashboardAgentJson(dynamic decoded) {
  if (decoded is! Map<String, dynamic>) return null;

  const rootKeys = [
    'agentId',
    'AgentId',
    'totalCollectes',
    'TotalCollectes',
    'totalAffilies',
    'TotalAffilies',
  ];
  if (rootKeys.any(decoded.containsKey)) return decoded;

  for (final key in const ['data', 'Data', 'result', 'Result', 'payload']) {
    final nested = decoded[key];
    if (nested is Map<String, dynamic>) return nested;
  }

  return decoded;
}

class DashboardAgentModel {
  final int agentId;
  final String agentNom;
  final int totalAffilies;
  final double totalCollectes;
  final double totalCommissions;
  final int classement;
  final double progressionMois;
  final double progressionAnnee;
  final double tauxReussite;
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
  final DateTime derniereActivite;
  final int nombreJoursActifs;
  final double montantCommissions;
  final double netAPercevoir;

  DashboardAgentModel({
    required this.agentId,
    required this.agentNom,
    required this.totalAffilies,
    required this.totalCollectes,
    required this.totalCommissions,
    required this.classement,
    required this.progressionMois,
    required this.progressionAnnee,
    required this.tauxReussite,
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
    required this.derniereActivite,
    required this.nombreJoursActifs,
    required this.montantCommissions,
    required this.netAPercevoir,
  });

  factory DashboardAgentModel.fromJson(Map<String, dynamic> json) {
    final derniereActiviteRaw = _dashField(json, 'derniereActivite');
    final derniereActivite = derniereActiviteRaw != null
        ? DateTime.tryParse(derniereActiviteRaw.toString()) ?? DateTime.now()
        : DateTime.now();

    return DashboardAgentModel(
      agentId: _dashInt(json, 'agentId'),
      agentNom: _dashString(json, 'agentNom'),
      totalAffilies: _dashInt(json, 'totalAffilies'),
      totalCollectes: _dashDouble(json, 'totalCollectes'),
      totalCommissions: _dashDouble(json, 'totalCommissions'),
      classement: _dashInt(json, 'classement'),
      progressionMois: _dashDouble(json, 'progressionMois'),
      progressionAnnee: _dashDouble(json, 'progressionAnnee'),
      tauxReussite: _dashDouble(json, 'tauxReussite'),
      nomAgent: _dashString(json, 'nomAgent'),
      montantTotal: _dashDouble(json, 'montantTotal'),
      nombreTransactions: _dashInt(json, 'nombreTransactions'),
      montantMoyen: _dashDouble(json, 'montantMoyen'),
      tauxSucces: _dashDouble(json, 'tauxSucces'),
      performanceMoyenne: _dashDouble(json, 'performanceMoyenne'),
      objectifPersonnel: _dashDouble(json, 'objectifPersonnel'),
      atteinteObjectif: _dashDouble(json, 'atteinteObjectif'),
      rangEquipe: _dashInt(json, 'rangEquipe'),
      progression: _dashDouble(json, 'progression'),
      derniereActivite: derniereActivite,
      nombreJoursActifs: _dashInt(json, 'nombreJoursActifs'),
      montantCommissions: _dashDouble(json, 'montantCommissions'),
      netAPercevoir: _dashDouble(json, 'netAPercevoir'),
    );
  }

  // Format helpers
  String get formattedTotalCollectes => '${totalCollectes.toStringAsFixed(2)} CDF';
  String get formattedTotalCommissions => '${totalCommissions.toStringAsFixed(2)} CDF';
  String get formattedNetAPercevoir => '${netAPercevoir.toStringAsFixed(2)} CDF';
  String get formattedMontantTotal => '${montantTotal.toStringAsFixed(2)} CDF';
  String get formattedProgressionMois => '${progressionMois.toStringAsFixed(1)}%';
  String get formattedProgressionAnnee => '${progressionAnnee.toStringAsFixed(1)}%';
  String get formattedTauxReussite => '${tauxReussite.toStringAsFixed(1)}%';
}
