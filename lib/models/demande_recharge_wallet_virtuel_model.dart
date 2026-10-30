// GET/POST /api/DemandeRechargeWalletVirtuel
//
// Le montant n'est jamais saisi par l'agent : il est calculé par le serveur
// (`montantCalcule`) à partir du plafond et du solde au moment de la demande.

import '../utils/currency_formatter.dart';

double _rechargeDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _rechargeDoubleOrNull(dynamic value) {
  if (value is num) return value.toDouble();
  if (value == null) return null;
  return double.tryParse(value.toString());
}

int _rechargeInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _rechargeIntOrNull(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value == null) return null;
  return int.tryParse(value.toString());
}

DateTime? _rechargeDate(dynamic value) {
  if (value is DateTime) return value;
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

class DemandeRechargeWalletVirtuel {
  final int idDemande;
  final int agentId;
  final String agentNom;
  final String agentMatricule;
  final double montantCalcule;
  final double soldeAuMomentDemande;
  final double plafondAuMomentDemande;
  final String statutDemande;
  final String motif;
  final String motifRejet;
  final DateTime? dateDemande;
  final DateTime? dateConfirmation;
  final DateTime? dateRejet;
  final int? demandeParUtilisateurId;
  final String demandeParNom;
  final int? confirmeParUtilisateurId;
  final String confirmeParNom;
  final int? rejeteParUtilisateurId;
  final String rejeteParNom;
  final int? walletVirtuelMouvementId;
  final double? montantCredite;
  final double? soldeAvantCredit;
  final double? soldeApresCredit;
  final DateTime? dateCreation;
  final DateTime? dateModification;
  final bool actif;

  /// Devise du wallet virtuel rechargé. Renseignée si l'API la fournit,
  /// sinon injectée par l'écran (devise principale configurée) via
  /// [withDevise] — sans elle, le formatage retomberait sur le CDF.
  final int? deviseId;
  final String? deviseCode;
  final String? deviseSymbole;

  const DemandeRechargeWalletVirtuel({
    required this.idDemande,
    required this.agentId,
    required this.agentNom,
    required this.agentMatricule,
    required this.montantCalcule,
    required this.soldeAuMomentDemande,
    required this.plafondAuMomentDemande,
    required this.statutDemande,
    required this.motif,
    required this.motifRejet,
    required this.dateDemande,
    required this.dateConfirmation,
    required this.dateRejet,
    required this.demandeParUtilisateurId,
    required this.demandeParNom,
    required this.confirmeParUtilisateurId,
    required this.confirmeParNom,
    required this.rejeteParUtilisateurId,
    required this.rejeteParNom,
    required this.walletVirtuelMouvementId,
    required this.montantCredite,
    required this.soldeAvantCredit,
    required this.soldeApresCredit,
    required this.dateCreation,
    required this.dateModification,
    required this.actif,
    this.deviseId,
    this.deviseCode,
    this.deviseSymbole,
  });

  factory DemandeRechargeWalletVirtuel.fromJson(Map<String, dynamic> json) {
    // La devise peut arriver à plat ou imbriquée dans le wallet virtuel.
    final walletRaw = json['walletVirtuel'] ?? json['WalletVirtuel'];
    final walletMap = walletRaw is Map
        ? Map<String, dynamic>.from(walletRaw)
        : null;
    final deviseIdRaw =
        json['deviseId'] ??
        json['DeviseId'] ??
        walletMap?['deviseId'] ??
        walletMap?['DeviseId'];
    final deviseCodeRaw =
        json['deviseCode'] ??
        json['DeviseCode'] ??
        walletMap?['deviseCode'] ??
        walletMap?['DeviseCode'];
    final deviseSymboleRaw =
        json['deviseSymbole'] ??
        json['DeviseSymbole'] ??
        walletMap?['deviseSymbole'] ??
        walletMap?['DeviseSymbole'];

    return DemandeRechargeWalletVirtuel(
      idDemande: _rechargeInt(json['idDemande']),
      agentId: _rechargeInt(json['agentId']),
      agentNom: json['agentNom']?.toString() ?? '',
      agentMatricule: json['agentMatricule']?.toString() ?? '',
      montantCalcule: _rechargeDouble(json['montantCalcule']),
      soldeAuMomentDemande: _rechargeDouble(json['soldeAuMomentDemande']),
      plafondAuMomentDemande: _rechargeDouble(json['plafondAuMomentDemande']),
      statutDemande: json['statutDemande']?.toString() ?? '',
      motif: json['motif']?.toString() ?? '',
      motifRejet: json['motifRejet']?.toString() ?? '',
      dateDemande: _rechargeDate(json['dateDemande']),
      dateConfirmation: _rechargeDate(json['dateConfirmation']),
      dateRejet: _rechargeDate(json['dateRejet']),
      demandeParUtilisateurId: _rechargeIntOrNull(
        json['demandeParUtilisateurId'],
      ),
      demandeParNom: json['demandeParNom']?.toString() ?? '',
      confirmeParUtilisateurId: _rechargeIntOrNull(
        json['confirmeParUtilisateurId'],
      ),
      confirmeParNom: json['confirmeParNom']?.toString() ?? '',
      rejeteParUtilisateurId: _rechargeIntOrNull(
        json['rejeteParUtilisateurId'],
      ),
      rejeteParNom: json['rejeteParNom']?.toString() ?? '',
      walletVirtuelMouvementId: _rechargeIntOrNull(
        json['walletVirtuelMouvementId'],
      ),
      montantCredite: _rechargeDoubleOrNull(json['montantCredite']),
      soldeAvantCredit: _rechargeDoubleOrNull(json['soldeAvantCredit']),
      soldeApresCredit: _rechargeDoubleOrNull(json['soldeApresCredit']),
      dateCreation: _rechargeDate(json['dateCreation']),
      dateModification: _rechargeDate(json['dateModification']),
      actif: json['statut'] == true,
      deviseId: _rechargeIntOrNull(deviseIdRaw),
      deviseCode: deviseCodeRaw?.toString(),
      deviseSymbole: deviseSymboleRaw?.toString(),
    );
  }

  /// Injecte la devise résolue (devise principale configurée) dans une copie,
  /// pour un formatage cohérent entre demande, rechargement et wallet.
  DemandeRechargeWalletVirtuel withDevise({
    int? deviseId,
    String? deviseCode,
    String? deviseSymbole,
  }) {
    return DemandeRechargeWalletVirtuel(
      idDemande: idDemande,
      agentId: agentId,
      agentNom: agentNom,
      agentMatricule: agentMatricule,
      montantCalcule: montantCalcule,
      soldeAuMomentDemande: soldeAuMomentDemande,
      plafondAuMomentDemande: plafondAuMomentDemande,
      statutDemande: statutDemande,
      motif: motif,
      motifRejet: motifRejet,
      dateDemande: dateDemande,
      dateConfirmation: dateConfirmation,
      dateRejet: dateRejet,
      demandeParUtilisateurId: demandeParUtilisateurId,
      demandeParNom: demandeParNom,
      confirmeParUtilisateurId: confirmeParUtilisateurId,
      confirmeParNom: confirmeParNom,
      rejeteParUtilisateurId: rejeteParUtilisateurId,
      rejeteParNom: rejeteParNom,
      walletVirtuelMouvementId: walletVirtuelMouvementId,
      montantCredite: montantCredite,
      soldeAvantCredit: soldeAvantCredit,
      soldeApresCredit: soldeApresCredit,
      dateCreation: dateCreation,
      dateModification: dateModification,
      actif: actif,
      deviseId: deviseId ?? this.deviseId,
      deviseCode: deviseCode ?? this.deviseCode,
      deviseSymbole: deviseSymbole ?? this.deviseSymbole,
    );
  }

  String get formattedMontantCalcule => CurrencyFormatter.format(
    amount: montantCalcule,
    deviseId: deviseId,
    deviseCode: deviseCode,
    deviseSymbole: deviseSymbole,
  );

  String get formattedPlafond => CurrencyFormatter.format(
    amount: plafondAuMomentDemande,
    deviseId: deviseId,
    deviseCode: deviseCode,
    deviseSymbole: deviseSymbole,
  );

  String get formattedSoldeAuMomentDemande => CurrencyFormatter.format(
    amount: soldeAuMomentDemande,
    deviseId: deviseId,
    deviseCode: deviseCode,
    deviseSymbole: deviseSymbole,
  );

  String? get formattedMontantCredite {
    final montant = montantCredite;
    if (montant == null) return null;
    return CurrencyFormatter.format(
      amount: montant,
      deviseId: deviseId,
      deviseCode: deviseCode,
      deviseSymbole: deviseSymbole,
    );
  }

  String? get formattedSoldeApresCredit {
    final solde = soldeApresCredit;
    if (solde == null) return null;
    return CurrencyFormatter.format(
      amount: solde,
      deviseId: deviseId,
      deviseCode: deviseCode,
      deviseSymbole: deviseSymbole,
    );
  }

  /// Statut normalisé pour l'affichage, tolérant aux libellés backend.
  String get statutLabel {
    final brut = statutDemande.trim();
    switch (brut.toLowerCase()) {
      case '':
        return 'En attente';
      case 'enattente':
      case 'en attente':
      case 'pending':
      case 'en_cours':
      case 'encours':
        return 'En attente';
      case 'confirme':
      case 'confirmee':
      case 'confirmer':
      case 'valide':
      case 'validee':
      case 'approved':
      case 'approuve':
        return 'Confirmée';
      case 'rejete':
      case 'rejetee':
      case 'rejeter':
      case 'refuse':
      case 'refusee':
        return 'Rejetée';
      case 'annule':
      case 'annulee':
        return 'Annulée';
      default:
        return brut;
    }
  }

  bool get isEnAttente => statutLabel == 'En attente';
  bool get isConfirmee => statutLabel == 'Confirmée';
  bool get isRejetee => statutLabel == 'Rejetée';
  bool get isAnnulee => statutLabel == 'Annulée';
  bool get isTerminee => isConfirmee || isRejetee || isAnnulee;
}
