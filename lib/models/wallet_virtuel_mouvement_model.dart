// ============================================
// MODÈLE MOUVEMENT WALLET VIRTUEL AGENT
// ============================================

int _mouvementInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

class WalletVirtuelMouvementModel {
  final int idWalletVirtuelMouvement;
  final int walletVirtuelId;
  final double montant;
  final String typeOperation;
  final String source;
  final String description;
  final int? referenceExterne;
  final DateTime dateOperation;
  final int agentId;
  final String agentNom;
  final String agentMatricule;

  WalletVirtuelMouvementModel({
    required this.idWalletVirtuelMouvement,
    required this.walletVirtuelId,
    required this.montant,
    required this.typeOperation,
    required this.source,
    required this.description,
    this.referenceExterne,
    required this.dateOperation,
    required this.agentId,
    required this.agentNom,
    required this.agentMatricule,
  });

  factory WalletVirtuelMouvementModel.fromJson(Map<String, dynamic> json) {
    return WalletVirtuelMouvementModel(
      idWalletVirtuelMouvement: _mouvementInt(json['idWalletVirtuelMouvement']),
      walletVirtuelId: _mouvementInt(json['walletVirtuelId']),
      montant: (json['montant'] as num?)?.toDouble() ?? 0.0,
      typeOperation: json['typeOperation']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      description: json['description'] == null
          ? ''
          : json['description'].toString(),
      referenceExterne: json['referenceExterne'] is int
          ? json['referenceExterne'] as int
          : int.tryParse(json['referenceExterne']?.toString() ?? ''),
      dateOperation:
          DateTime.tryParse(json['dateOperation']?.toString() ?? '') ??
          DateTime.now(),
      agentId: _mouvementInt(json['agentId']),
      agentNom: json['agentNom']?.toString() ?? '',
      agentMatricule: json['agentMatricule']?.toString() ?? '',
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

  String get formattedMontant {
    final sign = isCredit && !isDebit ? '+' : (isDebit ? '-' : '');
    return '$sign${montant.toStringAsFixed(2)} \$';
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
      case 'AJOUT_SOLDE':
        return 'Recharge de solde';
      case 'COLLECTE_COMPTE_VIRTUEL':
      case 'COLLECTE_VIRTUEL':
        if (referenceExterne != null && referenceExterne! > 0) {
          return 'Collecte n° $referenceExterne';
        }
        final desc = description.trim();
        if (desc.isNotEmpty) return desc;
        return 'Paiement via collecte';
      case 'COMM_COLLECTE':
      case 'COMMISSION_COLLECTE':
        return 'Commission sur collecte';
      case 'RETRAIT':
        return 'Retrait de fonds';
      case 'DEPOT':
        return 'Dépôt sur le compte';
      default:
        return _humanizeToken(source);
    }
  }

  /// Titre utilisateur selon le type d'opération et la source API.
  String get title {
    switch (_sourceKey) {
      case 'AJOUT_SOLDE':
        return isCredit ? 'Recharge du compte' : 'Ajustement de solde';
      case 'COLLECTE_COMPTE_VIRTUEL':
      case 'COLLECTE_VIRTUEL':
        return isDebit ? 'Vous avez été débité' : 'Crédit sur le compte';
      case 'COMM_COLLECTE':
      case 'COMMISSION_COLLECTE':
        return isCredit ? 'Commission perçue' : 'Commission débitée';
      case 'RETRAIT':
        return 'Retrait effectué';
      case 'DEPOT':
        return 'Dépôt reçu';
      default:
        if (isCredit) return 'Crédit sur le compte';
        if (isDebit) return 'Débit sur le compte';
        return sourceDisplay;
    }
  }

  String get _sourceKey => source.trim().toUpperCase();

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
