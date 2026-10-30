import 'medical_json.dart';

/// Types de référentiels exposés par `/api/CatalogueMedical/referentiels/{type}`.
enum ReferentielMedicalType {
  categoriesHopitaux('categories-hopitaux', 'Catégories d\'hôpitaux'),
  categoriesSoins('categories-soins', 'Catégories de soins'),
  soins('soins', 'Soins');

  const ReferentielMedicalType(this.path, this.label);

  /// Segment d'URL exact attendu par l'API.
  final String path;
  final String label;
}

class ReferentielMedical {
  final int id;
  final String nom;
  final String? description;
  final bool statut;

  const ReferentielMedical({
    required this.id,
    required this.nom,
    this.description,
    required this.statut,
  });

  factory ReferentielMedical.fromJson(Map<String, dynamic> json) {
    return ReferentielMedical(
      id: MedicalJson.asInt(json['id']),
      nom: MedicalJson.asString(json['nom']),
      description: MedicalJson.asStringOrNull(json['description']),
      statut: MedicalJson.asBool(json['statut']),
    );
  }
}

/// Soin effectivement couvert par une version d'offre.
class SoinCouvert {
  final int soinId;
  final String nom;
  final String? description;

  const SoinCouvert({required this.soinId, required this.nom, this.description});

  factory SoinCouvert.fromJson(Map<String, dynamic> json) {
    return SoinCouvert(
      soinId: MedicalJson.asInt(json['soinId']),
      nom: MedicalJson.asString(json['nom']),
      description: MedicalJson.asStringOrNull(json['description']),
    );
  }
}

/// Version publiée (immuable) d'une offre : tarif, soins et taux figés.
class VersionOffreMedicale {
  final int id;
  final double montantMensuel;
  final int deviseId;
  final String? deviseCode;
  final DateTime? datePublicationUtc;
  final List<SoinCouvert> soins;
  final double tauxCommissionAT;
  final double tauxCommissionAA;
  final double tauxCommissionAAMash;
  final double tauxCommissionAAStructure;

  const VersionOffreMedicale({
    required this.id,
    required this.montantMensuel,
    required this.deviseId,
    this.deviseCode,
    this.datePublicationUtc,
    required this.soins,
    this.tauxCommissionAT = 0,
    this.tauxCommissionAA = 0,
    this.tauxCommissionAAMash = 0,
    this.tauxCommissionAAStructure = 0,
  });

  factory VersionOffreMedicale.fromJson(Map<String, dynamic> json) {
    return VersionOffreMedicale(
      id: MedicalJson.asInt(json['id']),
      montantMensuel: MedicalJson.asDouble(json['montantMensuel']),
      deviseId: MedicalJson.asInt(json['deviseId']),
      deviseCode: MedicalJson.asStringOrNull(json['deviseCode']),
      datePublicationUtc: MedicalJson.asDateOrNull(json['datePublicationUtc']),
      soins: MedicalJson.asMapList(json['soins']).map(SoinCouvert.fromJson).toList(),
      tauxCommissionAT: MedicalJson.asDouble(json['tauxCommissionAT']),
      tauxCommissionAA: MedicalJson.asDouble(json['tauxCommissionAA']),
      tauxCommissionAAMash: MedicalJson.asDouble(json['tauxCommissionAAMash']),
      tauxCommissionAAStructure: MedicalJson.asDouble(
        json['tauxCommissionAAStructure'],
      ),
    );
  }
}

class OffreMedicale {
  final int id;
  final String nom;
  final int hopitalPartenaireId;
  final String? hopitalNom;
  final int? categorieHopitalId;
  final String? categorieHopitalNom;
  final int categorieSoinId;
  final String? categorieSoinNom;

  /// `false` : offre retirée du catalogue commercial (historique).
  final bool statut;
  final String? periodicite;

  /// Version courante (tarif actuel) — à ne pas utiliser pour une période
  /// déjà préparée, qui conserve sa propre version.
  final VersionOffreMedicale? version;

  const OffreMedicale({
    required this.id,
    required this.nom,
    required this.hopitalPartenaireId,
    this.hopitalNom,
    this.categorieHopitalId,
    this.categorieHopitalNom,
    required this.categorieSoinId,
    this.categorieSoinNom,
    required this.statut,
    this.periodicite,
    this.version,
  });

  factory OffreMedicale.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    return OffreMedicale(
      id: MedicalJson.asInt(json['id']),
      nom: MedicalJson.asString(json['nom']),
      hopitalPartenaireId: MedicalJson.asInt(json['hopitalPartenaireId']),
      hopitalNom: MedicalJson.asStringOrNull(json['hopitalNom']),
      categorieHopitalId: MedicalJson.asIntOrNull(json['categorieHopitalId']),
      categorieHopitalNom: MedicalJson.asStringOrNull(json['categorieHopitalNom']),
      categorieSoinId: MedicalJson.asInt(json['categorieSoinId']),
      categorieSoinNom: MedicalJson.asStringOrNull(json['categorieSoinNom']),
      statut: MedicalJson.asBool(json['statut']),
      periodicite: MedicalJson.asStringOrNull(json['periodicite']),
      version: version is Map
          ? VersionOffreMedicale.fromJson(MedicalJson.asMap(version))
          : null,
    );
  }
}

/// Corps de publication d'une version (`POST offres` et `POST offres/{id}/versions`).
class VersionOffreMedicaleRequest {
  final double montantMensuel;
  final int deviseId;
  final List<int> soinIds;
  final double tauxCommissionAT;
  final double tauxCommissionAA;
  final double tauxCommissionAAMash;
  final double tauxCommissionAAStructure;

  const VersionOffreMedicaleRequest({
    required this.montantMensuel,
    required this.deviseId,
    required this.soinIds,
    required this.tauxCommissionAT,
    required this.tauxCommissionAA,
    required this.tauxCommissionAAMash,
    required this.tauxCommissionAAStructure,
  });

  Map<String, dynamic> toJson() => {
    'montantMensuel': montantMensuel,
    'deviseId': deviseId,
    'soinIds': soinIds,
    'tauxCommissionAT': tauxCommissionAT,
    'tauxCommissionAA': tauxCommissionAA,
    'tauxCommissionAAMash': tauxCommissionAAMash,
    'tauxCommissionAAStructure': tauxCommissionAAStructure,
  };
}
