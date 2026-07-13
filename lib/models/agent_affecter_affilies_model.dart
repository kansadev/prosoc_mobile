/// Résultat PUT /api/Agent/{agentId}/affecter-affilies
class AgentAffecterAffiliesResultModel {
  final int agentId;
  final int totalDemandes;
  final int totalReussites;
  final int totalEchecs;
  final List<AgentAffecterAffilieItemResult> resultats;

  AgentAffecterAffiliesResultModel({
    required this.agentId,
    required this.totalDemandes,
    required this.totalReussites,
    required this.totalEchecs,
    required this.resultats,
  });

  factory AgentAffecterAffiliesResultModel.fromJson(Map<String, dynamic> json) {
    final rows = json['resultats'] ?? json['Resultats'];
    return AgentAffecterAffiliesResultModel(
      agentId: _int(json['agentId'] ?? json['AgentId']),
      totalDemandes: _int(json['totalDemandes'] ?? json['TotalDemandes']),
      totalReussites: _int(json['totalReussites'] ?? json['TotalReussites']),
      totalEchecs: _int(json['totalEchecs'] ?? json['TotalEchecs']),
      resultats: rows is List
          ? rows
              .whereType<Map>()
              .map(
                (row) => AgentAffecterAffilieItemResult.fromJson(
                  Map<String, dynamic>.from(row),
                ),
              )
              .toList()
          : const [],
    );
  }
}

class AgentAffecterAffilieItemResult {
  final int affilieId;
  final bool succes;
  final int? adhesionId;
  final int? ancienAgentId;
  final String message;

  AgentAffecterAffilieItemResult({
    required this.affilieId,
    required this.succes,
    this.adhesionId,
    this.ancienAgentId,
    required this.message,
  });

  factory AgentAffecterAffilieItemResult.fromJson(Map<String, dynamic> json) {
    return AgentAffecterAffilieItemResult(
      affilieId: _int(json['affilieId'] ?? json['AffilieId']),
      succes: json['succes'] == true || json['Succes'] == true,
      adhesionId: _nullableInt(json['adhesionId'] ?? json['AdhesionId']),
      ancienAgentId:
          _nullableInt(json['ancienAgentId'] ?? json['AncienAgentId']),
      message: (json['message'] ?? json['Message'] ?? '').toString(),
    );
  }
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _nullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
