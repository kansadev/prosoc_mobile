import '../utils/currency_formatter.dart';

// ============================================
// MODÈLE WALLET AGENT
// ============================================

/// Identifiants devises API Prosoc.
abstract final class WalletAgentDeviseIds {
  static const int cdf = 1;
  static const int usd = 2;

  static String labelForId(int deviseId) {
    if (deviseId == usd) return 'USD';
    if (deviseId == cdf) return 'CDF';
    return 'devise';
  }
}

double _walletDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

class WalletAgentModel {
  final int idWalletAgent;
  final int agentId;
  final int deviseId;
  final String deviseCode;
  final String deviseNom;
  final String deviseSymbole;
  final double soldeCourant;
  final double soldeDisponible;
  final DateTime dateCreation;
  final DateTime? dateModification;
  final bool statut;
  final String agentNom;
  final String agentMatricule;

  WalletAgentModel({
    required this.idWalletAgent,
    required this.agentId,
    this.deviseId = 0,
    this.deviseCode = '',
    this.deviseNom = '',
    this.deviseSymbole = '',
    required this.soldeCourant,
    this.soldeDisponible = 0,
    required this.dateCreation,
    this.dateModification,
    required this.statut,
    required this.agentNom,
    required this.agentMatricule,
  });

  factory WalletAgentModel.fromJson(Map<String, dynamic> json) {
    return WalletAgentModel(
      idWalletAgent: json['idWalletAgent'] ?? 0,
      agentId: json['agentId'] ?? 0,
      deviseId: json['deviseId'] ?? 0,
      deviseCode: json['deviseCode']?.toString() ?? '',
      deviseNom: json['deviseNom']?.toString() ?? '',
      deviseSymbole: json['deviseSymbole']?.toString() ?? '',
      soldeCourant: _walletDouble(json['soldeCourant']),
      soldeDisponible: _walletDouble(json['soldeDisponible']),
      dateCreation: DateTime.parse(
        json['dateCreation'] ?? DateTime.now().toIso8601String(),
      ),
      dateModification: json['dateModification'] != null
          ? DateTime.tryParse(json['dateModification'].toString())
          : null,
      statut: json['statut'] ?? true,
      agentNom: json['agentNom']?.toString() ?? '',
      agentMatricule: json['agentMatricule']?.toString() ?? '',
    );
  }

  String get currencyLabel {
    if (deviseCode.isNotEmpty) return deviseCode;
    if (deviseId == WalletAgentDeviseIds.usd) return 'USD';
    if (deviseId == WalletAgentDeviseIds.cdf) return 'CDF';
    return '';
  }

  String get formattedSolde => CurrencyFormatter.format(
        amount: soldeCourant,
        deviseId: deviseId,
        deviseCode: deviseCode,
        deviseSymbole: deviseSymbole,
      );

  String get formattedSoldeDisponible => CurrencyFormatter.format(
        amount: soldeDisponible,
        deviseId: deviseId,
        deviseCode: deviseCode,
        deviseSymbole: deviseSymbole,
      );

  bool get hasRetenue => soldeCourant > soldeDisponible;
}

// ============================================
// RÉPONSE PAGINÉE WALLET AGENT
// ============================================

class WalletAgentPaginatedResponse {
  final List<WalletAgentModel> data;
  final int currentPage;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final int startItem;
  final int endItem;

  WalletAgentPaginatedResponse({
    required this.data,
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.startItem,
    required this.endItem,
  });

  factory WalletAgentPaginatedResponse.fromJson(Map<String, dynamic> json) {
    return WalletAgentPaginatedResponse(
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => WalletAgentModel.fromJson(item))
          .toList() ?? [],
      currentPage: json['currentPage'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
      totalItems: json['totalItems'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPreviousPage: json['hasPreviousPage'] ?? false,
      startItem: json['startItem'] ?? 0,
      endItem: json['endItem'] ?? 0,
    );
  }
}
