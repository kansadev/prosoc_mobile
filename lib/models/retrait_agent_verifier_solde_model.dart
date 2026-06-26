// POST /api/RetraitAgent/verifier-solde

import '../utils/currency_formatter.dart';

double _verifDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _verifInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

Map<String, dynamic>? unwrapRetraitVerifierSoldeJson(dynamic decoded) {
  if (decoded is! Map) return null;
  final map = decoded is Map<String, dynamic>
      ? decoded
      : Map<String, dynamic>.from(decoded);
  if (map.containsKey('soldeSuffisant') ||
      map.containsKey('SoldeSuffisant')) {
    return map;
  }
  for (final key in const ['data', 'Data', 'result', 'Result']) {
    final nested = map[key];
    if (nested is Map) {
      return unwrapRetraitVerifierSoldeJson(nested);
    }
  }
  return map;
}

class RetraitAgentVerifierSolde {
  final int agentId;
  final String agentNom;
  final double soldeDisponible;
  final double montantDemande;
  final bool soldeSuffisant;
  final double difference;
  final String message;
  final int deviseId;
  final String deviseCode;
  final String deviseSymbole;

  const RetraitAgentVerifierSolde({
    required this.agentId,
    required this.agentNom,
    required this.soldeDisponible,
    required this.montantDemande,
    required this.soldeSuffisant,
    required this.difference,
    required this.message,
    required this.deviseId,
    required this.deviseCode,
    required this.deviseSymbole,
  });

  factory RetraitAgentVerifierSolde.fromJson(Map<String, dynamic> json) {
    return RetraitAgentVerifierSolde(
      agentId: _verifInt(json['agentId']),
      agentNom: json['agentNom']?.toString() ?? '',
      soldeDisponible: _verifDouble(json['soldeDisponible']),
      montantDemande: _verifDouble(json['montantDemande']),
      soldeSuffisant: json['soldeSuffisant'] == true,
      difference: _verifDouble(json['difference']),
      message: json['message']?.toString() ?? '',
      deviseId: _verifInt(json['deviseId']),
      deviseCode: json['deviseCode']?.toString() ?? '',
      deviseSymbole: json['deviseSymbole']?.toString() ?? '',
    );
  }

  String get formattedSoldeDisponible => CurrencyFormatter.format(
        amount: soldeDisponible,
        deviseId: deviseId,
        deviseCode: deviseCode,
        deviseSymbole: deviseSymbole,
      );

  String get formattedMontantDemande => CurrencyFormatter.format(
        amount: montantDemande,
        deviseId: deviseId,
        deviseCode: deviseCode,
        deviseSymbole: deviseSymbole,
      );
}
