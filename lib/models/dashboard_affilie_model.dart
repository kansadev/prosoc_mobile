// ============================================
// MODÈLE DASHBOARD AFFILIÉ — GET /api/DashboardAffilie/resume/{affilieId}
// ============================================

double _affilieDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _affilieInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

bool _affilieBool(dynamic v) {
  if (v is bool) return v;
  if (v is String) return v.toLowerCase() == 'true';
  return false;
}

DateTime? _affilieDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

class DashboardAffilieResumeModel {
  final DashboardAffilieKpis kpis;
  final DashboardAffilieInformations informations;
  final List<DashboardAffilieNotification> notificationsRecentes;
  final List<DashboardAffilieCotisation> cotisationsRecentes;
  final List<DashboardAffiliePrestation> prestationsRecentes;
  final List<DashboardAffilieBeneficiaire> beneficiaires;
  final DashboardAffilieGraphiques? graphiques;
  final List<DashboardAffilieDocument> documentsEnAttente;
  final DashboardAffiliePreferences? preferences;

  DashboardAffilieResumeModel({
    required this.kpis,
    required this.informations,
    required this.notificationsRecentes,
    required this.cotisationsRecentes,
    required this.prestationsRecentes,
    required this.beneficiaires,
    this.graphiques,
    required this.documentsEnAttente,
    this.preferences,
  });

  factory DashboardAffilieResumeModel.fromJson(Map<String, dynamic> json) {
    return DashboardAffilieResumeModel(
      kpis: DashboardAffilieKpis.fromJson(
        json['kpis'] as Map<String, dynamic>? ?? {},
      ),
      informations: DashboardAffilieInformations.fromJson(
        json['informations'] as Map<String, dynamic>? ?? {},
      ),
      notificationsRecentes: _mapList(
        json['notificationsRecentes'],
        DashboardAffilieNotification.fromJson,
      ),
      cotisationsRecentes: _mapList(
        json['cotisationsRecentes'],
        DashboardAffilieCotisation.fromJson,
      ),
      prestationsRecentes: _mapList(
        json['prestationsRecentes'],
        DashboardAffiliePrestation.fromJson,
      ),
      beneficiaires: _mapList(
        json['beneficiaires'],
        DashboardAffilieBeneficiaire.fromJson,
      ),
      graphiques: _parseGraphiques(json['graphiques']),
      documentsEnAttente: _mapList(
        json['documentsEnAttente'],
        DashboardAffilieDocument.fromJson,
      ),
      preferences: json['preferences'] != null
          ? DashboardAffiliePreferences.fromJson(
              json['preferences'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

List<T> _mapList<T>(
  dynamic raw,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (raw == null || raw is! List) return <T>[];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(fromJson)
      .toList();
}

class DashboardAffilieKpis {
  final int idAffilie;
  final String codeAdhesion;
  final String nomComplet;
  final double soldeTotal;
  final double soldeDisponible;
  final double totalCotisations;
  final double totalPrestations;
  final int nombrePrestations;
  final double montantDerniereCotisation;
  final DateTime? dateDerniereCotisation;
  final double montantDernierePrestation;
  final DateTime? dateDernierePrestation;
  final String statutAdhesion;
  final DateTime? dateAdhesion;
  final int ancienneteMois;
  final double tauxUtilisation;
  final double tauxCouverture;
  final bool estActif;
  final int nombreBeneficiaires;
  final double montantPlafond;
  final double restePlafond;

  DashboardAffilieKpis({
    required this.idAffilie,
    required this.codeAdhesion,
    required this.nomComplet,
    required this.soldeTotal,
    required this.soldeDisponible,
    required this.totalCotisations,
    required this.totalPrestations,
    required this.nombrePrestations,
    required this.montantDerniereCotisation,
    this.dateDerniereCotisation,
    required this.montantDernierePrestation,
    this.dateDernierePrestation,
    required this.statutAdhesion,
    this.dateAdhesion,
    required this.ancienneteMois,
    required this.tauxUtilisation,
    required this.tauxCouverture,
    required this.estActif,
    required this.nombreBeneficiaires,
    required this.montantPlafond,
    required this.restePlafond,
  });

  factory DashboardAffilieKpis.fromJson(Map<String, dynamic> json) {
    return DashboardAffilieKpis(
      idAffilie: _affilieInt(json['idAffilie']),
      codeAdhesion: json['codeAdhesion']?.toString() ?? '',
      nomComplet: json['nomComplet']?.toString() ?? '',
      soldeTotal: _affilieDouble(json['soldeTotal']),
      soldeDisponible: _affilieDouble(json['soldeDisponible']),
      totalCotisations: _affilieDouble(json['totalCotisations']),
      totalPrestations: _affilieDouble(json['totalPrestations']),
      nombrePrestations: _affilieInt(json['nombrePrestations']),
      montantDerniereCotisation:
          _affilieDouble(json['montantDerniereCotisation']),
      dateDerniereCotisation: _affilieDate(json['dateDerniereCotisation']),
      montantDernierePrestation:
          _affilieDouble(json['montantDernierePrestation']),
      dateDernierePrestation: _affilieDate(json['dateDernierePrestation']),
      statutAdhesion: json['statutAdhesion']?.toString() ?? '',
      dateAdhesion: _affilieDate(json['dateAdhesion']),
      ancienneteMois: _affilieInt(json['ancienneteMois']),
      tauxUtilisation: _affilieDouble(json['tauxUtilisation']),
      tauxCouverture: _affilieDouble(json['tauxCouverture']),
      estActif: _affilieBool(json['estActif']),
      nombreBeneficiaires: _affilieInt(json['nombreBeneficiaires']),
      montantPlafond: _affilieDouble(json['montantPlafond']),
      restePlafond: _affilieDouble(json['restePlafond']),
    );
  }
}

class DashboardAffilieInformations {
  final int idAffilie;
  final String codeAdhesion;
  final String nomComplet;
  final String telephone;
  final String email;
  final DateTime? dateNaissance;
  final String photoUrl;
  final DateTime? dateAdhesion;
  final String statutAdhesion;
  final bool estActif;
  final String provinceResidence;
  final String communeResidence;
  final String typeAdhesion;
  final String categorieAdhesion;
  final int nombreBeneficiaires;

  DashboardAffilieInformations({
    required this.idAffilie,
    required this.codeAdhesion,
    required this.nomComplet,
    required this.telephone,
    required this.email,
    this.dateNaissance,
    required this.photoUrl,
    this.dateAdhesion,
    required this.statutAdhesion,
    required this.estActif,
    required this.provinceResidence,
    required this.communeResidence,
    required this.typeAdhesion,
    required this.categorieAdhesion,
    required this.nombreBeneficiaires,
  });

  factory DashboardAffilieInformations.fromJson(Map<String, dynamic> json) {
    return DashboardAffilieInformations(
      idAffilie: _affilieInt(json['idAffilie']),
      codeAdhesion: json['codeAdhesion']?.toString() ?? '',
      nomComplet: json['nomComplet']?.toString() ?? '',
      telephone: json['telephone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      dateNaissance: _affilieDate(json['dateNaissance']),
      photoUrl: json['photoUrl']?.toString() ?? '',
      dateAdhesion: _affilieDate(json['dateAdhesion']),
      statutAdhesion: json['statutAdhesion']?.toString() ?? '',
      estActif: _affilieBool(json['estActif']),
      provinceResidence: json['provinceResidence']?.toString() ?? '',
      communeResidence: json['communeResidence']?.toString() ?? '',
      typeAdhesion: json['typeAdhesion']?.toString() ?? '',
      categorieAdhesion: json['categorieAdhesion']?.toString() ?? '',
      nombreBeneficiaires: _affilieInt(json['nombreBeneficiaires']),
    );
  }
}

class DashboardAffilieNotification {
  final int idNotification;
  final String typeNotification;
  final String titre;
  final String message;
  final DateTime? dateNotification;
  final bool estLue;
  final String priorite;
  final String categorie;
  final bool estActionRequise;

  DashboardAffilieNotification({
    required this.idNotification,
    required this.typeNotification,
    required this.titre,
    required this.message,
    this.dateNotification,
    required this.estLue,
    required this.priorite,
    required this.categorie,
    required this.estActionRequise,
  });

  factory DashboardAffilieNotification.fromJson(Map<String, dynamic> json) {
    return DashboardAffilieNotification(
      idNotification: _affilieInt(json['idNotification']),
      typeNotification: json['typeNotification']?.toString() ?? '',
      titre: json['titre']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      dateNotification: _affilieDate(json['dateNotification']),
      estLue: _affilieBool(json['estLue']),
      priorite: json['priorite']?.toString() ?? '',
      categorie: json['categorie']?.toString() ?? '',
      estActionRequise: _affilieBool(json['estActionRequise']),
    );
  }
}

class DashboardAffilieCotisation {
  final int idCotisation;
  final double montant;
  final DateTime? dateCotisation;
  final String typeCotisation;
  final String reference;
  final String statut;
  final String agentCollecteur;
  final String modePaiement;
  final String periodicite;
  final double cumulMois;
  final double cumulAnnee;
  final bool estEnRetard;
  final int joursRetard;

  DashboardAffilieCotisation({
    required this.idCotisation,
    required this.montant,
    this.dateCotisation,
    required this.typeCotisation,
    required this.reference,
    required this.statut,
    required this.agentCollecteur,
    required this.modePaiement,
    required this.periodicite,
    required this.cumulMois,
    required this.cumulAnnee,
    required this.estEnRetard,
    required this.joursRetard,
  });

  factory DashboardAffilieCotisation.fromJson(Map<String, dynamic> json) {
    return DashboardAffilieCotisation(
      idCotisation: _affilieInt(json['idCotisation']),
      montant: _affilieDouble(json['montant']),
      dateCotisation: _affilieDate(json['dateCotisation']),
      typeCotisation: json['typeCotisation']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      statut: json['statut']?.toString() ?? '',
      agentCollecteur: json['agentCollecteur']?.toString() ?? '',
      modePaiement: json['modePaiement']?.toString() ?? '',
      periodicite: json['periodicite']?.toString() ?? '',
      cumulMois: _affilieDouble(json['cumulMois']),
      cumulAnnee: _affilieDouble(json['cumulAnnee']),
      estEnRetard: _affilieBool(json['estEnRetard']),
      joursRetard: _affilieInt(json['joursRetard']),
    );
  }

  static List<DashboardAffilieCotisation> listFromJson(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(DashboardAffilieCotisation.fromJson)
        .toList();
  }
}

class DashboardAffilieCotisationMensuelle {
  final int mois;
  final int annee;
  final String moisAnnee;
  final double montantCotise;
  final double objectifCotisation;
  final double tauxRealisation;
  final int nombreCotisations;
  final double cumulAnnee;

  DashboardAffilieCotisationMensuelle({
    required this.mois,
    required this.annee,
    required this.moisAnnee,
    required this.montantCotise,
    required this.objectifCotisation,
    required this.tauxRealisation,
    required this.nombreCotisations,
    required this.cumulAnnee,
  });

  factory DashboardAffilieCotisationMensuelle.fromJson(
    Map<String, dynamic> json,
  ) {
    return DashboardAffilieCotisationMensuelle(
      mois: _affilieInt(json['mois']),
      annee: _affilieInt(json['annee']),
      moisAnnee: json['moisAnnee']?.toString() ?? '',
      montantCotise: _affilieDouble(json['montantCotise']),
      objectifCotisation: _affilieDouble(json['objectifCotisation']),
      tauxRealisation: _affilieDouble(json['tauxRealisation']),
      nombreCotisations: _affilieInt(json['nombreCotisations']),
      cumulAnnee: _affilieDouble(json['cumulAnnee']),
    );
  }

  String get labelCourt {
    if (moisAnnee.trim().isNotEmpty) {
      final parts = moisAnnee.trim().split(RegExp(r'\s+'));
      if (parts.isNotEmpty) return parts.first;
      return moisAnnee;
    }
    const moisLabels = [
      '',
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];
    if (mois >= 1 && mois <= 12) return moisLabels[mois];
    return '$mois';
  }
}

class DashboardAffiliePrestation {
  final int idPrestation;
  final double montantTotal;
  final double montantRembourse;
  final double montantPriseEnCharge;
  final double tauxRemboursement;
  final DateTime? datePrestation;
  final DateTime? dateDemande;
  final DateTime? dateRemboursement;
  final String typePrestation;
  final String prestationNom;
  final String statut;
  final String beneficiaire;
  final String structureSante;
  final String referenceFacture;
  final String medecinTraitant;
  final int delaiTraitementJours;
  final bool estUrgent;
  final double franchiseAppliquee;
  final double plafondDepasse;
  final String motifRejet;

  DashboardAffiliePrestation({
    required this.idPrestation,
    required this.montantTotal,
    required this.montantRembourse,
    required this.montantPriseEnCharge,
    required this.tauxRemboursement,
    this.datePrestation,
    this.dateDemande,
    this.dateRemboursement,
    required this.typePrestation,
    required this.prestationNom,
    required this.statut,
    required this.beneficiaire,
    required this.structureSante,
    required this.referenceFacture,
    required this.medecinTraitant,
    required this.delaiTraitementJours,
    required this.estUrgent,
    required this.franchiseAppliquee,
    required this.plafondDepasse,
    required this.motifRejet,
  });

  factory DashboardAffiliePrestation.fromJson(Map<String, dynamic> json) {
    return DashboardAffiliePrestation(
      idPrestation: _affilieInt(json['idPrestation']),
      montantTotal: _affilieDouble(json['montantTotal']),
      montantRembourse: _affilieDouble(json['montantRembourse']),
      montantPriseEnCharge: _affilieDouble(json['montantPriseEnCharge']),
      tauxRemboursement: _affilieDouble(json['tauxRemboursement']),
      datePrestation: _affilieDate(json['datePrestation']),
      dateDemande: _affilieDate(json['dateDemande']),
      dateRemboursement: _affilieDate(json['dateRemboursement']),
      typePrestation: json['typePrestation']?.toString() ?? '',
      prestationNom: json['prestationNom']?.toString() ?? '',
      statut: json['statut']?.toString() ?? '',
      beneficiaire: json['beneficiaire']?.toString() ?? '',
      structureSante: json['structureSante']?.toString() ?? '',
      referenceFacture: json['referenceFacture']?.toString() ?? '',
      medecinTraitant: json['medecinTraitant']?.toString() ?? '',
      delaiTraitementJours: _affilieInt(json['delaiTraitementJours']),
      estUrgent: _affilieBool(json['estUrgent']),
      franchiseAppliquee: _affilieDouble(json['franchiseAppliquee']),
      plafondDepasse: _affilieDouble(json['plafondDepasse']),
      motifRejet: json['motifRejet']?.toString() ?? '',
    );
  }

  static List<DashboardAffiliePrestation> listFromJson(dynamic raw) {
    if (raw == null || raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(DashboardAffiliePrestation.fromJson)
        .toList();
  }
}

class DashboardAffilieBeneficiaire {
  final int idBeneficiaire;
  final String nomComplet;
  final String lienParente;
  final String typeBeneficiaire;
  final bool estActif;
  final bool estPrincipal;

  DashboardAffilieBeneficiaire({
    required this.idBeneficiaire,
    required this.nomComplet,
    required this.lienParente,
    required this.typeBeneficiaire,
    required this.estActif,
    required this.estPrincipal,
  });

  factory DashboardAffilieBeneficiaire.fromJson(Map<String, dynamic> json) {
    return DashboardAffilieBeneficiaire(
      idBeneficiaire: _affilieInt(json['idBeneficiaire']),
      nomComplet: json['nomComplet']?.toString() ?? '',
      lienParente: json['lienParente']?.toString() ?? '',
      typeBeneficiaire: json['typeBeneficiaire']?.toString() ?? '',
      estActif: _affilieBool(json['estActif']),
      estPrincipal: _affilieBool(json['estPrincipal']),
    );
  }
}

DashboardAffilieGraphiques? _parseGraphiques(dynamic raw) {
  if (raw == null) return null;
  if (raw is! Map<String, dynamic>) return null;
  return DashboardAffilieGraphiques.fromJson(raw);
}

class DashboardAffilieGraphiques {
  final List<DashboardAffilieCotisationMensuelle> cotisationsMensuelles;
  final DashboardAffilieResumeAnnuel? resumeAnnuel;

  DashboardAffilieGraphiques({
    List<DashboardAffilieCotisationMensuelle>? cotisationsMensuelles,
    this.resumeAnnuel,
  }) : cotisationsMensuelles = cotisationsMensuelles ?? const [];

  factory DashboardAffilieGraphiques.fromJson(Map<String, dynamic> json) {
    return DashboardAffilieGraphiques(
      cotisationsMensuelles: _mapList(
        json['cotisationsMensuelles'],
        DashboardAffilieCotisationMensuelle.fromJson,
      ),
      resumeAnnuel: json['resumeAnnuel'] is Map<String, dynamic>
          ? DashboardAffilieResumeAnnuel.fromJson(
              json['resumeAnnuel'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  List<DashboardAffilieCotisationMensuelle> forYear(int year) {
    final filtered = cotisationsMensuelles
        .where((m) => m.annee == year)
        .toList();
    filtered.sort((a, b) => a.mois.compareTo(b.mois));
    return filtered;
  }
}

class DashboardAffilieResumeAnnuel {
  final int annee;
  final double totalCotisations;
  final double totalPrestations;
  final double tauxUtilisationMoyen;

  DashboardAffilieResumeAnnuel({
    required this.annee,
    required this.totalCotisations,
    required this.totalPrestations,
    required this.tauxUtilisationMoyen,
  });

  factory DashboardAffilieResumeAnnuel.fromJson(Map<String, dynamic> json) {
    return DashboardAffilieResumeAnnuel(
      annee: _affilieInt(json['annee']),
      totalCotisations: _affilieDouble(json['totalCotisations']),
      totalPrestations: _affilieDouble(json['totalPrestations']),
      tauxUtilisationMoyen: _affilieDouble(json['tauxUtilisationMoyen']),
    );
  }
}

class DashboardAffilieDocument {
  final int idDocument;
  final String typeDocument;
  final String nomDocument;
  final bool estObligatoire;
  final bool estValide;

  DashboardAffilieDocument({
    required this.idDocument,
    required this.typeDocument,
    required this.nomDocument,
    required this.estObligatoire,
    required this.estValide,
  });

  factory DashboardAffilieDocument.fromJson(Map<String, dynamic> json) {
    return DashboardAffilieDocument(
      idDocument: _affilieInt(json['idDocument']),
      typeDocument: json['typeDocument']?.toString() ?? '',
      nomDocument: json['nomDocument']?.toString() ?? '',
      estObligatoire: _affilieBool(json['estObligatoire']),
      estValide: _affilieBool(json['estValide']),
    );
  }
}

class DashboardAffiliePreferences {
  final bool notificationsEmail;
  final bool notificationsSMS;
  final String languePreferee;

  DashboardAffiliePreferences({
    required this.notificationsEmail,
    required this.notificationsSMS,
    required this.languePreferee,
  });

  factory DashboardAffiliePreferences.fromJson(Map<String, dynamic> json) {
    return DashboardAffiliePreferences(
      notificationsEmail: _affilieBool(json['notificationsEmail']),
      notificationsSMS: _affilieBool(json['notificationsSMS']),
      languePreferee: json['languePreferee']?.toString() ?? 'fr',
    );
  }
}
