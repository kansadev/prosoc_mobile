import '../utils/currency_formatter.dart';

/// Pénalité affilié liée à un arriéré.
/// GET /api/penalite-affilie/arriere/{arrieresAffilieId}
/// GET /api/penalite-affilie/mes-penalites
class PenaliteAffilieModel {
  final int idPenaliteAffilie;
  final int affilieId;
  final int arrieresAffilieId;
  final int fraisId;
  final int typePenalite;
  final double montant;
  final int deviseId;
  final int joursRetard;
  final String motif;
  final String statut;
  final String motifAnnulation;
  final DateTime? dateApplication;
  final DateTime? datePaiement;
  final DateTime? dateAnnulation;
  final bool statutActif;
  final DateTime? dateCreation;
  final DateTime? dateModification;
  final bool estDue;

  const PenaliteAffilieModel({
    required this.idPenaliteAffilie,
    required this.affilieId,
    required this.arrieresAffilieId,
    required this.fraisId,
    required this.typePenalite,
    required this.montant,
    required this.deviseId,
    required this.joursRetard,
    required this.motif,
    required this.statut,
    required this.motifAnnulation,
    this.dateApplication,
    this.datePaiement,
    this.dateAnnulation,
    required this.statutActif,
    this.dateCreation,
    this.dateModification,
    required this.estDue,
  });

  factory PenaliteAffilieModel.fromJson(Map<String, dynamic> json) {
    return PenaliteAffilieModel(
      idPenaliteAffilie:
          _asInt(json['idPenaliteAffilie'] ?? json['IdPenaliteAffilie']),
      affilieId: _asInt(json['affilieId'] ?? json['AffilieId']),
      arrieresAffilieId:
          _asInt(json['arrieresAffilieId'] ?? json['ArrieresAffilieId']),
      fraisId: _asInt(json['fraisId'] ?? json['FraisId']),
      typePenalite: _asInt(json['typePenalite'] ?? json['TypePenalite']),
      montant: _asDouble(json['montant'] ?? json['Montant']),
      deviseId: _asInt(json['deviseId'] ?? json['DeviseId']),
      joursRetard: _asInt(json['joursRetard'] ?? json['JoursRetard']),
      motif: (json['motif'] ?? json['Motif'] ?? '').toString(),
      statut: (json['statut'] ?? json['Statut'] ?? '').toString(),
      motifAnnulation:
          (json['motifAnnulation'] ?? json['MotifAnnulation'] ?? '').toString(),
      dateApplication: _asDateTime(json['dateApplication'] ?? json['DateApplication']),
      datePaiement: _asDateTime(json['datePaiement'] ?? json['DatePaiement']),
      dateAnnulation:
          _asDateTime(json['dateAnnulation'] ?? json['DateAnnulation']),
      statutActif: json['statutActif'] == true || json['StatutActif'] == true,
      dateCreation: _asDateTime(json['dateCreation'] ?? json['DateCreation']),
      dateModification:
          _asDateTime(json['dateModification'] ?? json['DateModification']),
      estDue: json['estDue'] == true || json['EstDue'] == true,
    );
  }

  bool get estPayable => estDue && statutActif && montant > 0;

  String get typePenaliteLabel {
    switch (typePenalite) {
      case 1:
        return 'Retard de paiement';
      case 2:
        return 'Pénalité administrative';
      default:
        return 'Pénalité';
    }
  }

  String get libelle {
    if (motif.trim().isNotEmpty) return motif.trim();
    if (joursRetard > 0) {
      return '$typePenaliteLabel ($joursRetard jour${joursRetard > 1 ? 's' : ''})';
    }
    return typePenaliteLabel;
  }

  String formattedMontant({String? deviseCode}) => CurrencyFormatter.format(
        amount: montant,
        deviseId: deviseId,
        deviseCode: deviseCode,
      );

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  static double _asDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
