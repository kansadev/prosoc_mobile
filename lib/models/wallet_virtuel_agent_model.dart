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

/// Réponse PUT /api/WalletVirtuelAgent/{id}/ajouter-solde
class WalletVirtuelAjouterSoldeResult {
  final WalletVirtuelAgentModel wallet;
  final double ancienSolde;
  final double montantAjoute;
  final double nouveauSolde;

  WalletVirtuelAjouterSoldeResult({
    required this.wallet,
    required this.ancienSolde,
    required this.montantAjoute,
    required this.nouveauSolde,
  });

  factory WalletVirtuelAjouterSoldeResult.fromJson(Map<String, dynamic> json) {
    final walletRaw = json['wallet'] ?? json['Wallet'];
    final walletMap = walletRaw is Map<String, dynamic>
        ? walletRaw
        : walletRaw is Map
            ? Map<String, dynamic>.from(walletRaw)
            : json;

    return WalletVirtuelAjouterSoldeResult(
      wallet: WalletVirtuelAgentModel.fromJson(walletMap),
      ancienSolde: _virtuelDouble(json['ancienSolde'] ?? json['AncienSolde']),
      montantAjoute:
          _virtuelDouble(json['montantAjoute'] ?? json['MontantAjoute']),
      nouveauSolde:
          _virtuelDouble(json['nouveauSolde'] ?? json['NouveauSolde']),
    );
  }

  String formattedNouveauSolde(WalletVirtuelAgentModel wallet) =>
      CurrencyFormatter.format(
        amount: nouveauSolde,
        deviseId: wallet.deviseId,
        deviseCode: wallet.deviseCode,
        deviseSymbole: wallet.deviseSymbole,
      );
}
