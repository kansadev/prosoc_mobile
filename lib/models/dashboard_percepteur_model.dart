// GET /api/DashboardPercepteur/summary

dynamic _percField(Map<String, dynamic> json, String camelKey) {
  if (json.containsKey(camelKey)) return json[camelKey];
  if (camelKey.isEmpty) return null;
  final pascalKey = camelKey[0].toUpperCase() + camelKey.substring(1);
  if (json.containsKey(pascalKey)) return json[pascalKey];
  return null;
}

double _percDouble(Map<String, dynamic> json, String key) {
  final value = _percField(json, key);
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _percInt(Map<String, dynamic> json, String key) {
  final value = _percField(json, key);
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _percString(Map<String, dynamic> json, String key) {
  final value = _percField(json, key);
  return value?.toString() ?? '';
}

DateTime? _percDateTime(Map<String, dynamic> json, String key) {
  final raw = _percField(json, key);
  if (raw == null) return null;
  final parsed = DateTime.tryParse(raw.toString());
  if (parsed == null || parsed.year <= 1) return null;
  return parsed;
}

List<Map<String, dynamic>> _percListMap(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

class PercepteurKpis {
  final double montantTotalPercu;
  final double montantDuJour;
  final double montantSemaine;
  final double montantMois;
  final double montantAnnee;
  final int nombreTotalTransactions;
  final int transactionsDuJour;
  final int transactionsSemaine;
  final int transactionsMois;
  final double montantMoyenTransaction;
  final double tauxCroissance;
  final double objectifJournalier;
  final double atteinteObjectifJournalier;
  final int nombreAgentsActifs;
  final double tauxSucces;
  final String devisePrincipaleCode;

  PercepteurKpis({
    required this.montantTotalPercu,
    required this.montantDuJour,
    required this.montantSemaine,
    required this.montantMois,
    required this.montantAnnee,
    required this.nombreTotalTransactions,
    required this.transactionsDuJour,
    required this.transactionsSemaine,
    required this.transactionsMois,
    required this.montantMoyenTransaction,
    required this.tauxCroissance,
    required this.objectifJournalier,
    required this.atteinteObjectifJournalier,
    required this.nombreAgentsActifs,
    required this.tauxSucces,
    required this.devisePrincipaleCode,
  });

  factory PercepteurKpis.fromJson(Map<String, dynamic> json) {
    return PercepteurKpis(
      montantTotalPercu: _percField(json, 'montantTotalPerçu') != null
          ? _percDouble(json, 'montantTotalPerçu')
          : _percDouble(json, 'montantTotalPercu'),
      montantDuJour: _percDouble(json, 'montantDuJour'),
      montantSemaine: _percDouble(json, 'montantSemaine'),
      montantMois: _percDouble(json, 'montantMois'),
      montantAnnee: _percDouble(json, 'montantAnnee'),
      nombreTotalTransactions: _percInt(json, 'nombreTotalTransactions'),
      transactionsDuJour: _percInt(json, 'transactionsDuJour'),
      transactionsSemaine: _percInt(json, 'transactionsSemaine'),
      transactionsMois: _percInt(json, 'transactionsMois'),
      montantMoyenTransaction: _percDouble(json, 'montantMoyenTransaction'),
      tauxCroissance: _percDouble(json, 'tauxCroissance'),
      objectifJournalier: _percDouble(json, 'objectifJournalier'),
      atteinteObjectifJournalier: _percDouble(json, 'atteinteObjectifJournalier'),
      nombreAgentsActifs: _percInt(json, 'nombreAgentsActifs'),
      tauxSucces: _percDouble(json, 'tauxSucces'),
      devisePrincipaleCode: _percString(json, 'devisePrincipaleCode'),
    );
  }

  String formatMontant(double value) {
    final code = devisePrincipaleCode.isNotEmpty ? devisePrincipaleCode : 'CDF';
    return '${value.toStringAsFixed(0)} $code';
  }

  String get formattedMontantTotal => formatMontant(montantTotalPercu);
  String get formattedMontantMois => formatMontant(montantMois);
  String get formattedMontantJour => formatMontant(montantDuJour);
  String get formattedTauxSucces => '${tauxSucces.toStringAsFixed(1)} %';
}

class PercepteurResumeMensuel {
  final String mois;
  final double montantTotal;
  final int nombreTransactions;
  final double montantMoyen;
  final double objectifMensuel;
  final double atteinteObjectif;
  final double croissance;
  final double netAPercevoir;
  final int nombreAgentsActifs;
  final double tauxSucces;

  PercepteurResumeMensuel({
    required this.mois,
    required this.montantTotal,
    required this.nombreTransactions,
    required this.montantMoyen,
    required this.objectifMensuel,
    required this.atteinteObjectif,
    required this.croissance,
    required this.netAPercevoir,
    required this.nombreAgentsActifs,
    required this.tauxSucces,
  });

  factory PercepteurResumeMensuel.fromJson(Map<String, dynamic> json) {
    return PercepteurResumeMensuel(
      mois: _percString(json, 'mois'),
      montantTotal: _percDouble(json, 'montantTotal'),
      nombreTransactions: _percInt(json, 'nombreTransactions'),
      montantMoyen: _percDouble(json, 'montantMoyen'),
      objectifMensuel: _percDouble(json, 'objectifMensuel'),
      atteinteObjectif: _percDouble(json, 'atteinteObjectif'),
      croissance: _percDouble(json, 'croissance'),
      netAPercevoir: _percDouble(json, 'netAPercevoir'),
      nombreAgentsActifs: _percInt(json, 'nombreAgentsActifs'),
      tauxSucces: _percDouble(json, 'tauxSucces'),
    );
  }
}

class PercepteurTendance {
  final String periode;
  final double montantTotal;
  final int nombreTransactions;
  final double montantMoyen;
  final double tauxCroissance;
  final double tauxSucces;
  final double netAPercevoir;

  PercepteurTendance({
    required this.periode,
    required this.montantTotal,
    required this.nombreTransactions,
    required this.montantMoyen,
    required this.tauxCroissance,
    required this.tauxSucces,
    required this.netAPercevoir,
  });

  factory PercepteurTendance.fromJson(Map<String, dynamic> json) {
    return PercepteurTendance(
      periode: _percString(json, 'periode'),
      montantTotal: _percDouble(json, 'montantTotal'),
      nombreTransactions: _percInt(json, 'nombreTransactions'),
      montantMoyen: _percDouble(json, 'montantMoyen'),
      tauxCroissance: _percDouble(json, 'tauxCroissance'),
      tauxSucces: _percDouble(json, 'tauxSucces'),
      netAPercevoir: _percDouble(json, 'netAPercevoir'),
    );
  }
}

/// GET /api/DashboardPercepteur/evolution-transactions
class PercepteurEvolutionTransaction {
  final String periode;
  final double montantTotal;
  final int nombreTransactions;
  final double montantMoyen;
  final double tauxCroissance;
  final double tauxSucces;
  final double montantCommissions;
  final double montantFrais;
  final double netAPercevoir;

  PercepteurEvolutionTransaction({
    required this.periode,
    required this.montantTotal,
    required this.nombreTransactions,
    required this.montantMoyen,
    required this.tauxCroissance,
    required this.tauxSucces,
    required this.montantCommissions,
    required this.montantFrais,
    required this.netAPercevoir,
  });

  factory PercepteurEvolutionTransaction.fromJson(Map<String, dynamic> json) {
    return PercepteurEvolutionTransaction(
      periode: _percString(json, 'periode'),
      montantTotal: _percDouble(json, 'montantTotal'),
      nombreTransactions: _percInt(json, 'nombreTransactions'),
      montantMoyen: _percDouble(json, 'montantMoyen'),
      tauxCroissance: _percDouble(json, 'tauxCroissance'),
      tauxSucces: _percDouble(json, 'tauxSucces'),
      montantCommissions: _percDouble(json, 'montantCommissions'),
      montantFrais: _percDouble(json, 'montantFrais'),
      netAPercevoir: _percDouble(json, 'netAPercevoir'),
    );
  }
}

class TopAgentPercepteur {
  final int agentId;
  final String nomAgent;
  final double montantTotal;
  final int nombreTransactions;
  final double montantMoyen;
  final double tauxSucces;
  final double netAPercevoir;
  final int rang;
  final DateTime? derniereTransaction;

  TopAgentPercepteur({
    required this.agentId,
    required this.nomAgent,
    required this.montantTotal,
    required this.nombreTransactions,
    required this.montantMoyen,
    required this.tauxSucces,
    required this.netAPercevoir,
    required this.rang,
    this.derniereTransaction,
  });

  factory TopAgentPercepteur.fromJson(Map<String, dynamic> json) {
    return TopAgentPercepteur(
      agentId: _percInt(json, 'agentId'),
      nomAgent: _percString(json, 'nomAgent'),
      montantTotal: _percDouble(json, 'montantTotal'),
      nombreTransactions: _percInt(json, 'nombreTransactions'),
      montantMoyen: _percDouble(json, 'montantMoyen'),
      tauxSucces: _percDouble(json, 'tauxSucces'),
      netAPercevoir: _percDouble(json, 'netAPercevoir'),
      rang: _percInt(json, 'rang'),
      derniereTransaction: _percDateTime(json, 'derniereTransaction'),
    );
  }
}

class PercepteurAgentStats {
  final int agentId;
  final String nomAgent;
  final double montantTotal;
  final int nombreTransactions;
  final double tauxSucces;
  final double netAPercevoir;
  final int nombreJoursActifs;
  final DateTime? derniereTransaction;

  PercepteurAgentStats({
    required this.agentId,
    required this.nomAgent,
    required this.montantTotal,
    required this.nombreTransactions,
    required this.tauxSucces,
    required this.netAPercevoir,
    required this.nombreJoursActifs,
    this.derniereTransaction,
  });

  factory PercepteurAgentStats.fromJson(Map<String, dynamic> json) {
    return PercepteurAgentStats(
      agentId: _percInt(json, 'agentId'),
      nomAgent: _percString(json, 'nomAgent'),
      montantTotal: _percDouble(json, 'montantTotal'),
      nombreTransactions: _percInt(json, 'nombreTransactions'),
      tauxSucces: _percDouble(json, 'tauxSucces'),
      netAPercevoir: _percDouble(json, 'netAPercevoir'),
      nombreJoursActifs: _percInt(json, 'nombreJoursActifs'),
      derniereTransaction: _percDateTime(json, 'derniereTransaction'),
    );
  }
}

class PercepteurTransaction {
  final int idTransaction;
  final DateTime? dateTransaction;
  final double montant;
  final String typeTransaction;
  final String statut;
  final String reference;
  final String nomAgent;
  final String nomAffilie;
  final String modePaiement;
  final double commission;
  final double frais;
  final double netAPercevoir;
  final String notes;

  PercepteurTransaction({
    required this.idTransaction,
    this.dateTransaction,
    required this.montant,
    required this.typeTransaction,
    required this.statut,
    required this.reference,
    required this.nomAgent,
    required this.nomAffilie,
    required this.modePaiement,
    required this.commission,
    required this.frais,
    required this.netAPercevoir,
    required this.notes,
  });

  factory PercepteurTransaction.fromJson(Map<String, dynamic> json) {
    return PercepteurTransaction(
      idTransaction: _percInt(json, 'idTransaction'),
      dateTransaction: _percDateTime(json, 'dateTransaction'),
      montant: _percDouble(json, 'montant'),
      typeTransaction: _percString(json, 'typeTransaction'),
      statut: _percString(json, 'statut'),
      reference: _percString(json, 'reference'),
      nomAgent: _percString(json, 'nomAgent'),
      nomAffilie: _percString(json, 'nomAffilie'),
      modePaiement: _percString(json, 'modePaiement'),
      commission: _percDouble(json, 'commission'),
      frais: _percDouble(json, 'frais'),
      netAPercevoir: _percDouble(json, 'netAPercevoir'),
      notes: _percString(json, 'notes'),
    );
  }

  String get displayTitle {
    if (nomAffilie.isNotEmpty) return nomAffilie;
    if (typeTransaction.isNotEmpty) return typeTransaction;
    if (reference.isNotEmpty) return reference;
    return 'Transaction #$idTransaction';
  }

  String buildSubtitle() {
    final parts = <String>[
      if (nomAgent.isNotEmpty) nomAgent,
      if (typeTransaction.isNotEmpty && nomAffilie.isNotEmpty) typeTransaction,
      if (modePaiement.isNotEmpty) modePaiement,
      if (statut.isNotEmpty) statut,
    ];
    return parts.join(' · ');
  }
}

class ObjectifPercepteur {
  final String typeObjectif;
  final double objectif;
  final double realise;
  final double atteinte;

  ObjectifPercepteur({
    required this.typeObjectif,
    required this.objectif,
    required this.realise,
    required this.atteinte,
  });

  factory ObjectifPercepteur.fromJson(Map<String, dynamic> json) {
    return ObjectifPercepteur(
      typeObjectif: _percString(json, 'typeObjectif'),
      objectif: _percDouble(json, 'objectif'),
      realise: _percDouble(json, 'realise'),
      atteinte: _percDouble(json, 'atteinte'),
    );
  }
}

class PercepteurGraphs {
  final List<PercepteurResumeMensuel> resumeMensuels;
  final List<PercepteurTendance> tendances;

  PercepteurGraphs({
    required this.resumeMensuels,
    required this.tendances,
  });

  factory PercepteurGraphs.fromJson(Map<String, dynamic> json) {
    return PercepteurGraphs(
      resumeMensuels: _percListMap(_percField(json, 'resumeMensuels'))
          .map(PercepteurResumeMensuel.fromJson)
          .toList(),
      tendances: _percListMap(_percField(json, 'tendances'))
          .map(PercepteurTendance.fromJson)
          .toList(),
    );
  }
}

class DashboardPercepteurModel {
  final PercepteurKpis? kpis;
  final PercepteurGraphs? graphs;
  final List<TopAgentPercepteur> topAgents;
  final List<PercepteurAgentStats> agentsStats;
  final List<ObjectifPercepteur> objectifs;
  final List<PercepteurTransaction> transactionsRecentes;
  final DateTime? derniereMiseAJour;
  final double soldeAPercevoir;
  final double montantEnAttente;
  final int transactionsEnAttente;

  DashboardPercepteurModel({
    this.kpis,
    this.graphs,
    required this.topAgents,
    required this.agentsStats,
    required this.objectifs,
    required this.transactionsRecentes,
    this.derniereMiseAJour,
    required this.soldeAPercevoir,
    required this.montantEnAttente,
    required this.transactionsEnAttente,
  });

  factory DashboardPercepteurModel.fromJson(Map<String, dynamic> json) {
    final kpisRaw = _percField(json, 'kpis');
    final graphsRaw = _percField(json, 'graphs');

    return DashboardPercepteurModel(
      kpis: kpisRaw is Map
          ? PercepteurKpis.fromJson(Map<String, dynamic>.from(kpisRaw))
          : null,
      graphs: graphsRaw is Map
          ? PercepteurGraphs.fromJson(Map<String, dynamic>.from(graphsRaw))
          : null,
      topAgents: _percListMap(_percField(json, 'topAgents'))
          .map(TopAgentPercepteur.fromJson)
          .toList(),
      agentsStats: _percListMap(_percField(json, 'agentsStats'))
          .map(PercepteurAgentStats.fromJson)
          .toList(),
      objectifs: _percListMap(_percField(json, 'objectifs'))
          .map(ObjectifPercepteur.fromJson)
          .toList(),
      transactionsRecentes:
          _percListMap(_percField(json, 'transactionsRecentes'))
              .map(PercepteurTransaction.fromJson)
              .toList(),
      derniereMiseAJour: _percDateTime(json, 'derniereMiseAJour'),
      soldeAPercevoir: _percDouble(json, 'soldeAPercevoir'),
      montantEnAttente: _percDouble(json, 'montantEnAttente'),
      transactionsEnAttente: _percInt(json, 'transactionsEnAttente'),
    );
  }

  String formatMontant(double value) =>
      kpis?.formatMontant(value) ?? '${value.toStringAsFixed(0)} CDF';
}
