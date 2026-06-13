// ============================================
// MODÈLE CRÉATION ADHÉSION AVEC AFFILIÉ
// ============================================

/// Valeurs alignées sur le contrat API (Swagger / good_request_body.json).
class AdhesionApiValues {
  AdhesionApiValues._();

  static const typeCollecteFrais = 'FRAIS';
  /// Adhésion groupée (`/api/adhesion/with-affilie`).
  static const typeCollecteSouscription = 'SOUSCRIPTION';
  /// Collecte unitaire (`POST /api/Collecte`) — `souscriptionPrestationId` = id prestation.
  static const typeCollecteSouscriptionCollecte = 'Souscription';
  static const statutDossierComplet = 'COMPLET';
  static const statutDossierEnAttente = 'En Attente';
}

class AdhesionWithAffilieRequest {
  final String? codeAdhesion;
  final String nom;
  final String prenom;
  final String postnom;
  final DateTime dateNaissance;
  final String telephone;
  final String? emailAffilie;
  final String provinceResidence;
  final String? communeResidence;
  final String? quartierResidence;
  final String? avenueResidence;
  final String? numeroResidence;
  final String? communeActivite;
  final String? quartierActivite;
  final String? avenueActivite;
  final String? numeroActivite;
  final String? photoBase64;
  final String? photoContentType;
  final String? carteIdentiteBase64;
  final String? carteIdentiteContentType;
  final bool affilieStatut;
  final String? statutDossier;
  final int typeAdhesionId;
  final int agentId;
  final bool adhesionStatut;
  final List<CollecteRequest>? collectes;
  final List<DependantRequest>? dependants;
  final List<AntecedantRequest>? antecedants;

  AdhesionWithAffilieRequest({
    this.codeAdhesion,
    required this.nom,
    required this.prenom,
    required this.postnom,
    required this.dateNaissance,
    required this.telephone,
    this.emailAffilie,
    required this.provinceResidence,
    this.communeResidence,
    this.quartierResidence,
    this.avenueResidence,
    this.numeroResidence,
    this.communeActivite,
    this.quartierActivite,
    this.avenueActivite,
    this.numeroActivite,
    this.photoBase64,
    this.photoContentType,
    this.carteIdentiteBase64,
    this.carteIdentiteContentType,
    required this.affilieStatut,
    this.statutDossier,
    required this.typeAdhesionId,
    required this.agentId,
    required this.adhesionStatut,
    this.collectes,
    this.dependants,
    this.antecedants,
  });

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'nom': nom,
      'prenom': prenom,
      'postnom': postnom,
      'dateNaissance': _formatDateOnly(dateNaissance),
      'telephone': telephone,
      'provinceResidence': provinceResidence,
      'affilieStatut': affilieStatut,
      'typeAdhesionId': typeAdhesionId,
      'agentId': agentId,
      'adhesionStatut': adhesionStatut,
      'collectes': (collectes ?? const <CollecteRequest>[])
          .map((c) => c.toJson())
          .toList(),
      'dependants': (dependants ?? const <DependantRequest>[])
          .map((d) => d.toJson())
          .toList(),
      'antecedants': (antecedants ?? const <AntecedantRequest>[])
          .map((a) => a.toJson())
          .toList(),
    };

    if (codeAdhesion != null) payload['codeAdhesion'] = codeAdhesion;
    if (emailAffilie != null) payload['emailAffilie'] = emailAffilie;
    if (communeResidence != null) payload['communeResidence'] = communeResidence;
    if (quartierResidence != null) {
      payload['quartierResidence'] = quartierResidence;
    }
    if (avenueResidence != null) payload['avenueResidence'] = avenueResidence;
    if (numeroResidence != null) payload['numeroResidence'] = numeroResidence;
    if (communeActivite != null) payload['communeActivite'] = communeActivite;
    if (quartierActivite != null) payload['quartierActivite'] = quartierActivite;
    if (avenueActivite != null) payload['avenueActivite'] = avenueActivite;
    if (numeroActivite != null) payload['numeroActivite'] = numeroActivite;
    if (photoBase64 != null) payload['photoBase64'] = photoBase64;
    if (photoContentType != null) payload['photoContentType'] = photoContentType;
    if (carteIdentiteBase64 != null) {
      payload['carteIdentiteBase64'] = carteIdentiteBase64;
    }
    if (carteIdentiteContentType != null) {
      payload['carteIdentiteContentType'] = carteIdentiteContentType;
    }
    if (statutDossier != null) payload['statutDossier'] = statutDossier;

    return payload;
  }

  static String _formatDateOnly(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class SouscriptionRequest {
  final int prestationId;
  final DateTime? dateSouscription;
  final bool statut;

  SouscriptionRequest({
    required this.prestationId,
    this.dateSouscription,
    required this.statut,
  });

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'prestationId': prestationId,
      'statut': statut,
    };
    if (dateSouscription != null) {
      payload['dateSouscription'] = dateSouscription!.toIso8601String();
    }
    return payload;
  }
}

class CollecteRequest {
  final SouscriptionRequest? subscription;
  final String typeCollecte;
  final int? fraisId;
  final double montant;
  final int mois;
  final int annee;
  final String? referencePaiement;
  final String? modePaiement;
  final String? operateur;
  final String? statutPaiement;
  final double montantRecu;
  final double montantAttendu;
  final int? deviseId;
  final String? observation;
  final bool statut;

  CollecteRequest({
    this.subscription,
    required this.typeCollecte,
    this.fraisId,
    required this.montant,
    required this.mois,
    required this.annee,
    this.referencePaiement,
    this.modePaiement,
    this.operateur,
    this.statutPaiement,
    required this.montantRecu,
    required this.montantAttendu,
    this.deviseId,
    this.observation,
    required this.statut,
  });

  Map<String, dynamic> toJson() {
    final normalizedType = typeCollecte.trim().toUpperCase();
    final isFrais = normalizedType == AdhesionApiValues.typeCollecteFrais;
    final isSouscription =
        normalizedType == AdhesionApiValues.typeCollecteSouscription;

    return {
      'souscription': isSouscription ? subscription?.toJson() : null,
      'typeCollecte': isFrais || isSouscription
          ? normalizedType
          : typeCollecte.trim(),
      'fraisId': isFrais ? fraisId : null,
      'cotisationAffilieId': null,
      'montant': montant,
      'mois': mois,
      'annee': annee,
      'referencePaiement':
          referencePaiement != null && referencePaiement!.isNotEmpty
              ? referencePaiement
              : null,
      'modePaiement': modePaiement,
      'operateur':
          operateur != null && operateur!.isNotEmpty ? operateur : null,
      'statutPaiement': statutPaiement,
      'montantRecu': montantRecu,
      'montantAttendu': montantAttendu,
      'deviseId': deviseId,
      'observation':
          observation != null && observation!.isNotEmpty ? observation : null,
      'statut': statut,
    };
  }
}

class DependantRequest {
  final String nom;
  final String? adresse;
  final String lienParente;
  final int? affilieId;
  final DateTime dateNaissance;
  final String? certificatScolariteBase64;
  final String? certificatScolariteContentType;

  DependantRequest({
    required this.nom,
    this.adresse,
    required this.lienParente,
    this.affilieId,
    required this.dateNaissance,
    this.certificatScolariteBase64,
    this.certificatScolariteContentType,
  });

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'nom': nom,
      'lienParente': lienParente,
      'dateNaissance': _formatDateNaissance(dateNaissance),
    };
    if (adresse != null && adresse!.isNotEmpty) payload['adresse'] = adresse;
    if (affilieId != null) payload['affilieId'] = affilieId;
    if (certificatScolariteBase64 != null) {
      payload['certificatScolariteBase64'] = certificatScolariteBase64;
    }
    if (certificatScolariteContentType != null) {
      payload['certificatScolariteContentType'] = certificatScolariteContentType;
    }
    return payload;
  }

  static String _formatDateNaissance(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class AntecedantRequest {
  final String description;
  final int? affilieId;
  final bool statut;

  AntecedantRequest({
    required this.description,
    this.affilieId,
    required this.statut,
  });

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'description': description,
      'statut': statut,
    };
    if (affilieId != null) payload['affilieId'] = affilieId;
    return payload;
  }
}

// ============================================
// RÉPONSE CRÉATION ADHÉSION
// ============================================

class AdhesionResponse {
  final int id;
  final String? statutDossier;
  final int typeAdhesionId;
  final String? typeAdhesionLibelle;
  final int agentId;
  final String? agentNom;
  final DateTime dateCreation;
  final DateTime? dateModification;
  final bool statut;
  final int affilieId;
  final String codeAdhesion;
  final Map<String, dynamic>? affilie;
  final List<Map<String, dynamic>>? souscriptions;
  final List<Map<String, dynamic>>? collectes;
  final List<Map<String, dynamic>>? dependants;
  final List<Map<String, dynamic>>? antecedants;
  final String? message;

  AdhesionResponse({
    required this.id,
    this.statutDossier,
    required this.typeAdhesionId,
    this.typeAdhesionLibelle,
    required this.agentId,
    this.agentNom,
    required this.dateCreation,
    this.dateModification,
    required this.statut,
    required this.affilieId,
    required this.codeAdhesion,
    this.affilie,
    this.souscriptions,
    this.collectes,
    this.dependants,
    this.antecedants,
    this.message,
  });

  factory AdhesionResponse.fromJson(Map<String, dynamic> json) {
    return AdhesionResponse(
      id: json['id'] ?? 0,
      statutDossier: json['statutDossier'],
      typeAdhesionId: json['typeAdhesionId'] ?? 0,
      typeAdhesionLibelle: json['typeAdhesionLibelle'],
      agentId: json['agentId'] ?? 0,
      agentNom: json['agentNom'],
      dateCreation: DateTime.parse(
        json['dateCreation'] ?? DateTime.now().toIso8601String(),
      ),
      dateModification: json['dateModification'] != null
          ? DateTime.parse(json['dateModification'])
          : null,
      statut: json['statut'] ?? false,
      affilieId: json['affilieId'] ?? 0,
      codeAdhesion: json['codeAdhesion'] ?? '',
      affilie: json['affilie'] as Map<String, dynamic>?,
      souscriptions: (json['souscriptions'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>(),
      collectes: (json['collectes'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>(),
      dependants: (json['dependants'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>(),
      antecedants: (json['antecedants'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>(),
      message: json['message'],
    );
  }
}

// ============================================
// PAIEMENT ÉLECTRONIQUE (FlexPay) — ADHÉSION
// ============================================

class AdhesionElectronicPaymentResponse {
  final String? idCollecteEnAttente;
  final String? orderNumberFlexPay;
  final String? referenceFlexPay;
  final double montantTarif;
  final String? codeDeviseTarif;
  final double montantFlexPay;
  final String? codeDevisePaiement;
  final double tauxApplique;
  final DateTime? holdExpireAt;
  final String? paymentUrl;
  final bool flexPayAccepted;
  final String? message;

  AdhesionElectronicPaymentResponse({
    this.idCollecteEnAttente,
    this.orderNumberFlexPay,
    this.referenceFlexPay,
    this.montantTarif = 0,
    this.codeDeviseTarif,
    this.montantFlexPay = 0,
    this.codeDevisePaiement,
    this.tauxApplique = 0,
    this.holdExpireAt,
    this.paymentUrl,
    this.flexPayAccepted = false,
    this.message,
  });

  factory AdhesionElectronicPaymentResponse.fromJson(Map<String, dynamic> json) {
    return AdhesionElectronicPaymentResponse(
      idCollecteEnAttente: json['idCollecteEnAttente']?.toString(),
      orderNumberFlexPay: json['orderNumberFlexPay']?.toString(),
      referenceFlexPay: json['referenceFlexPay']?.toString(),
      montantTarif: (json['montantTarif'] as num?)?.toDouble() ?? 0,
      codeDeviseTarif: json['codeDeviseTarif']?.toString(),
      montantFlexPay: (json['montantFlexPay'] as num?)?.toDouble() ?? 0,
      codeDevisePaiement: json['codeDevisePaiement']?.toString(),
      tauxApplique: (json['tauxApplique'] as num?)?.toDouble() ?? 0,
      holdExpireAt: json['holdExpireAt'] != null
          ? DateTime.tryParse(json['holdExpireAt'].toString())
          : null,
      paymentUrl: json['paymentUrl']?.toString(),
      flexPayAccepted: json['flexPayAccepted'] == true,
      message: json['message']?.toString(),
    );
  }
}
