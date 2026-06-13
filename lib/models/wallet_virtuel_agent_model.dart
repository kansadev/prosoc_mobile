import '../utils/currency_formatter.dart';

// ============================================
// MODÈLE WALLET VIRTUEL AGENT
// ============================================

double _virtuelDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _virtuelInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

class WalletVirtuelAgentModel {
  final int idWalletVirtuelAgent;
  final int agentId;
  final int? deviseId;
  final String deviseCode;
  final String deviseNom;
  final String deviseSymbole;
  final double soldeVirtuel;
  final DateTime dateCreation;
  final DateTime dateModification;
  final bool statut;
  final String agentNom;
  final String agentMatricule;

  WalletVirtuelAgentModel({
    required this.idWalletVirtuelAgent,
    required this.agentId,
    this.deviseId,
    this.deviseCode = '',
    this.deviseNom = '',
    this.deviseSymbole = '',
    required this.soldeVirtuel,
    required this.dateCreation,
    required this.dateModification,
    required this.statut,
    required this.agentNom,
    required this.agentMatricule,
  });

  factory WalletVirtuelAgentModel.fromJson(Map<String, dynamic> json) {
    final deviseRaw = json['deviseId'] ?? json['DeviseId'];
    return WalletVirtuelAgentModel(
      idWalletVirtuelAgent: _virtuelInt(
        json['idWalletVirtuelAgent'] ?? json['IdWalletVirtuelAgent'],
      ),
      agentId: _virtuelInt(json['agentId'] ?? json['AgentId']),
      deviseId: deviseRaw == null ? null : _virtuelInt(deviseRaw),
      deviseCode: json['deviseCode']?.toString() ?? '',
      deviseNom: json['deviseNom']?.toString() ?? '',
      deviseSymbole: json['deviseSymbole']?.toString() ?? '',
      soldeVirtuel: _virtuelDouble(json['soldeVirtuel']),
      dateCreation: DateTime.tryParse(json['dateCreation']?.toString() ?? '') ??
          DateTime.now(),
      dateModification:
          DateTime.tryParse(json['dateModification']?.toString() ?? '') ??
          DateTime.now(),
      statut: json['statut'] ?? true,
      agentNom: json['agentNom']?.toString() ?? '',
      agentMatricule: json['agentMatricule']?.toString() ?? '',
    );
  }

  String get formattedSolde => CurrencyFormatter.format(
        amount: soldeVirtuel,
        deviseId: deviseId,
        deviseCode: deviseCode,
        deviseSymbole: deviseSymbole,
      );
}
