// ============================================
// MODÈLE MOUVEMENT WALLET
// ============================================

import '../utils/currency_formatter.dart';

int _walletMouvementInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

class WalletMouvementModel {
  final int idWalletMouvement;
  final int walletId;
  final double montant;
  final String typeOperation;
  final String source;
  final String description;
  final DateTime dateOperation;
  final int walletAgentId;
  final String agentNom;
  final String agentMatricule;
  final int deviseId;
  final String deviseCode;
  final String deviseNom;
  final String deviseSymbole;

  WalletMouvementModel({
    required this.idWalletMouvement,
    required this.walletId,
    required this.montant,
    required this.typeOperation,
    required this.source,
    required this.description,
    required this.dateOperation,
    required this.walletAgentId,
    required this.agentNom,
    required this.agentMatricule,
    this.deviseId = 0,
    this.deviseCode = '',
    this.deviseNom = '',
    this.deviseSymbole = '',
  });

  factory WalletMouvementModel.fromJson(Map<String, dynamic> json) {
    return WalletMouvementModel(
      idWalletMouvement: _walletMouvementInt(json['idWalletMouvement']),
      walletId: _walletMouvementInt(json['walletId']),
      montant: (json['montant'] as num?)?.toDouble() ?? 0.0,
      typeOperation: json['typeOperation']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      description: json['description'] == null
          ? ''
          : json['description'].toString(),
      dateOperation:
          DateTime.tryParse(json['dateOperation']?.toString() ?? '') ??
          DateTime.now(),
      walletAgentId: _walletMouvementInt(json['walletAgentId']),
      agentNom: json['agentNom']?.toString() ?? '',
      agentMatricule: json['agentMatricule']?.toString() ?? '',
      deviseId: _walletMouvementInt(json['deviseId']),
      deviseCode: json['deviseCode']?.toString() ?? '',
      deviseNom: json['deviseNom']?.toString() ?? '',
      deviseSymbole: json['deviseSymbole']?.toString() ?? '',
    );
  }

  String formattedMontant({bool withSign = false}) {
    return CurrencyFormatter.formatMovementAmount(
      amount: montant,
      deviseId: deviseId > 0 ? deviseId : null,
      deviseCode: deviseCode.isNotEmpty ? deviseCode : null,
      deviseSymbole: deviseSymbole.isNotEmpty ? deviseSymbole : null,
      withSign: withSign,
    );
  }

  bool get isCredit {
    final type = typeOperation.toUpperCase();
    return type == 'CREDIT' || type.contains('CREDIT') || type == 'ENTREE';
  }

  bool get isDebit {
    final type = typeOperation.toUpperCase();
    return type == 'DEBIT' || type.contains('DEBIT') || type == 'SORTIE';
  }

  String get formattedDate {
    final d = dateOperation;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  String get sourceDisplay {
    switch (_sourceKey) {
      case 'COMM_COLLECTE':
      case 'COMMISSION_COLLECTE':
        return _commissionCollecteDetail();
      case 'RETRAIT':
        return 'Retrait de fonds';
      case 'DEPOT':
        return 'Dépôt sur le compte';
      case 'AJOUT_SOLDE':
        return 'Recharge de solde';
      default:
        final desc = description.trim();
        if (desc.isNotEmpty) return desc;
        return _humanizeToken(source);
    }
  }

  String get title {
    switch (_sourceKey) {
      case 'COMM_COLLECTE':
      case 'COMMISSION_COLLECTE':
        return isCredit ? 'Commission perçue' : 'Commission débitée';
      case 'RETRAIT':
        return 'Retrait effectué';
      case 'DEPOT':
        return 'Dépôt reçu';
      case 'AJOUT_SOLDE':
        return isCredit ? 'Recharge du compte' : 'Ajustement de solde';
      default:
        if (isCredit) return 'Crédit sur le wallet';
        if (isDebit) return 'Débit sur le wallet';
        return sourceDisplay;
    }
  }

  String get _sourceKey => source.trim().toUpperCase();

  String? get _collecteNumber {
    final match = RegExp(r'#(\d+)').firstMatch(description);
    return match?.group(1);
  }

  String? get _affilieRef {
    final match = RegExp(
      r'Affili[eé]\s*(\d+)',
      caseSensitive: false,
    ).firstMatch(description);
    return match?.group(1);
  }

  String _commissionCollecteDetail() {
    final collecte = _collecteNumber;
    final affilie = _affilieRef;
    if (collecte != null && affilie != null) {
      return 'Collecte n° $collecte · Affilié $affilie';
    }
    if (collecte != null) return 'Collecte n° $collecte';
    final desc = description.trim();
    if (desc.isNotEmpty) return desc;
    return 'Commission sur collecte';
  }

  static String _humanizeToken(String value) {
    if (value.trim().isEmpty) return 'Opération';
    return value
        .trim()
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) => part.length == 1
              ? part.toUpperCase()
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }
}
