// ============================================
// Arriérés affilié
// GET /api/arrieres-affilie/affilie/{affilieId}
// GET /api/arrieres-affilie/mes-arrieres
// ============================================

class TarifCotisationArriereModel {
  final int idCotisationAffilie;
  final double montant;
  final String periodicite;
  final int typeAdhesionId;
  final int deviseId;
  final bool statut;
  final DateTime? dateCreation;
  final DateTime? dateModification;

  TarifCotisationArriereModel({
    required this.idCotisationAffilie,
    required this.montant,
    required this.periodicite,
    required this.typeAdhesionId,
    required this.deviseId,
    required this.statut,
    required this.dateCreation,
    required this.dateModification,
  });

  factory TarifCotisationArriereModel.fromJson(Map<String, dynamic> json) {
    return TarifCotisationArriereModel(
      idCotisationAffilie: _asInt(json['idCotisationAffilie']),
      montant: _asDouble(json['montant']),
      periodicite: _asString(json['periodicite']),
      typeAdhesionId: _asInt(json['typeAdhesionId']),
      deviseId: _asInt(json['deviseId']),
      statut: json['statut'] == true,
      dateCreation: _asDateTime(json['dateCreation']),
      dateModification: _asDateTime(json['dateModification']),
    );
  }
}

class ArriereAffilieModel {
  final int idArrieresAffilie;
  final int affilieId;
  final String typeObligation;
  final int? fraisId;
  final int? souscriptionPrestationId;
  final int? cotisationAffilieId;
  final int? mois;
  final int? annee;
  final DateTime? dateEcheance;
  final String periodicite;
  final double montantAttendu;
  final double montantPaye;
  final double restAPayer;
  final int deviseId;
  final String description;
  final String statutPaiement;
  final bool statut;
  final DateTime? dateCreation;
  final DateTime? dateModification;
  final DateTime? dateDernierPaiement;
  final String periode;
  final double tauxPaiement;
  final bool estCompletementPaye;
  final TarifCotisationArriereModel? tarifCotisation;

  ArriereAffilieModel({
    required this.idArrieresAffilie,
    required this.affilieId,
    required this.typeObligation,
    required this.fraisId,
    required this.souscriptionPrestationId,
    required this.cotisationAffilieId,
    required this.mois,
    required this.annee,
    required this.dateEcheance,
    required this.periodicite,
    required this.montantAttendu,
    required this.montantPaye,
    required this.restAPayer,
    required this.deviseId,
    required this.description,
    required this.statutPaiement,
    required this.statut,
    required this.dateCreation,
    required this.dateModification,
    required this.dateDernierPaiement,
    required this.periode,
    required this.tauxPaiement,
    required this.estCompletementPaye,
    required this.tarifCotisation,
  });

  factory ArriereAffilieModel.fromJson(Map<String, dynamic> json) {
    final tarifRaw = json['tarifCotisation'];
    TarifCotisationArriereModel? tarif;
    if (tarifRaw is Map) {
      final tarifMap = tarifRaw is Map<String, dynamic>
          ? tarifRaw
          : Map<String, dynamic>.from(tarifRaw);
      tarif = TarifCotisationArriereModel.fromJson(tarifMap);
    }

    return ArriereAffilieModel(
      idArrieresAffilie: _asInt(json['idArrieresAffilie']),
      affilieId: _asInt(json['affilieId']),
      typeObligation: _asString(json['typeObligation']),
      fraisId: _asNullableInt(json['fraisId']),
      souscriptionPrestationId:
          _asNullableInt(json['souscriptionPrestationId']),
      cotisationAffilieId: _asNullableInt(json['cotisationAffilieId']),
      mois: _asNullableInt(json['mois']),
      annee: _asNullableInt(json['annee']),
      dateEcheance: _asDateTime(json['dateEcheance']),
      periodicite: _asString(json['periodicite']),
      montantAttendu: _asDouble(json['montantAttendu']),
      montantPaye: _asDouble(json['montantPaye']),
      restAPayer: _asDouble(json['restAPayer']),
      deviseId: _asInt(json['deviseId']),
      description: _asString(json['description']),
      statutPaiement: _asString(json['statutPaiement']),
      statut: json['statut'] == true,
      dateCreation: _asDateTime(json['dateCreation']),
      dateModification: _asDateTime(json['dateModification']),
      dateDernierPaiement: _asDateTime(json['dateDernierPaiement']),
      periode: _asString(json['periode']),
      tauxPaiement: _asDouble(json['tauxPaiement']),
      estCompletementPaye: json['estCompletementPaye'] == true,
      tarifCotisation: tarif,
    );
  }

  bool get estImpaye => !estCompletementPaye && restAPayer > 0;

  String get typeObligationLabel {
    switch (typeObligation.toUpperCase()) {
      case 'FRAIS':
        return 'Frais';
      case 'COTISATION':
        return 'Cotisation';
      case 'SOUSCRIPTION':
        return 'Souscription';
      default:
        return typeObligation.isNotEmpty ? typeObligation : 'Obligation';
    }
  }

  String get titre {
    if (description.trim().isNotEmpty) return description.trim();
    if (periode.trim().isNotEmpty) {
      return '$typeObligationLabel — $periode';
    }
    return typeObligationLabel;
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  final parsed = _asInt(value, fallback: -1);
  return parsed >= 0 ? parsed : null;
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? fallback;
  return fallback;
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
