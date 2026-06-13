// ============================================
// MODÈLE AFFILIÉ
// ============================================

class AffilieModel {
  final int idAffilie;
  final String codeAdhesion;
  final String nom;
  final String prenom;
  final String postnom;
  final String nomComplet; // Généré automatiquement: nom + " " + postnom + " " + prenom
  final DateTime dateDeNaissancedansJson;
  final String telephone;
  final String provinceResidence;
  final String communeResidence;
  final String quartierResidence;
  final String avenueResidence;
  final String numeroResidence;
  final String communeActivite;
  final String quartierActivite;
  final String avenueActivite;
  final String numeroActivite;
  final String? photoUrl; // URL de la photo de profil
  final DateTime dateCreation;
  final DateTime dateModification;
  final bool statut;

  AffilieModel({
    required this.idAffilie,
    required this.codeAdhesion,
    required this.nom,
    required this.prenom,
    required this.postnom,
    required this.nomComplet,
    required this.dateDeNaissancedansJson,
    required this.telephone,
    required this.provinceResidence,
    required this.communeResidence,
    required this.quartierResidence,
    required this.avenueResidence,
    required this.numeroResidence,
    required this.communeActivite,
    required this.quartierActivite,
    required this.avenueActivite,
    required this.numeroActivite,
    this.photoUrl,
    required this.dateCreation,
    required this.dateModification,
    required this.statut,
  });

  factory AffilieModel.fromJson(Map<String, dynamic> json) {
    return AffilieModel(
      idAffilie: json['idAffilie'] ?? 0,
      codeAdhesion: json['codeAdhesion'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      postnom: json['postnom'] ?? '',
      nomComplet: json['nomComplet'] ?? '', // Généré automatiquement par l'API
      dateDeNaissancedansJson: DateTime.parse(json['dateNaissanc'] ?? json['datenaissance'] ?? DateTime.now().toIso8601String()),
      telephone: json['telephone'] ?? '',
      provinceResidence: json['provinceResidence'] ?? '',
      communeResidence: json['communeResidence'] ?? '',
      quartierResidence: json['quartierResidence'] ?? '',
      avenueResidence: json['avenueResidence'] ?? '',
      numeroResidence: json['numeroResidence'] ?? '',
      communeActivite: json['communeActivite'] ?? '',
      quartierActivite: json['quartierActivite'] ?? '',
      avenueActivite: json['avenueActivite'] ?? '',
      numeroActivite: json['numeroActivite'] ?? '',
      photoUrl: json['photoUrl'], // Nouveau champ optionnel
      dateCreation: DateTime.parse(json['dateCreation'] ?? DateTime.now().toIso8601String()),
      dateModification: DateTime.parse(json['dateModification'] ?? DateTime.now().toIso8601String()),
      statut: json['statut'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codeAdhesion': codeAdhesion,
      'nom': nom,
      'prenom': prenom,
      'postnom': postnom,
      'dateNaissanc': dateDeNaissancedansJson.toIso8601String(),
      'telephone': telephone,
      'provinceResidence': provinceResidence,
      'communeResidence': communeResidence,
      'quartierResidence': quartierResidence,
      'avenueResidence': avenueResidence,
      'numeroResidence': numeroResidence,
      'communeActivite': communeActivite,
      'quartierActivite': quartierActivite,
      'avenueActivite': avenueActivite,
      'numeroActivite': numeroActivite,
      'photoUrl': photoUrl,
      'statut': statut,
    };
  }

  // Alias pour compatibilité avec l'ancien code
  DateTime get dateBirth => dateDeNaissancedansJson;

  /// Génère le nom complet automatiquement
  static String generateNomComplet(String nom, String postnom, String prenom) {
    return '$nom $postnom $prenom'.trim();
  }
}
