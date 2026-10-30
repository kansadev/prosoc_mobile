/// Zone sociale et son chef d'équipe.
///
/// `GET /api/ZoneSociale` renvoie `chefEquipeAgentId` et `chefEquipeNom` :
/// la lecture des chefs d'équipe passe donc par les zones, faute d'endpoint
/// dédié de listage des chefs d'équipe.
class ZoneSocialeModel {
  final int id;
  final String nom;
  final int communeId;
  final String? communeNom;
  final bool statut;
  final int? chefEquipeAgentId;
  final String? chefEquipeNom;

  const ZoneSocialeModel({
    required this.id,
    required this.nom,
    required this.communeId,
    this.communeNom,
    this.statut = true,
    this.chefEquipeAgentId,
    this.chefEquipeNom,
  });

  factory ZoneSocialeModel.fromJson(Map<String, dynamic> json) {
    return ZoneSocialeModel(
      id: _zoneInt(json['id'] ?? json['Id']),
      nom: (json['nom'] ?? json['Nom'] ?? '').toString().trim(),
      communeId: _zoneInt(json['communeId'] ?? json['CommuneId']),
      communeNom: _zoneOptionalString(json['communeNom'] ?? json['CommuneNom']),
      statut: (json['statut'] ?? json['Statut']) == true,
      chefEquipeAgentId: _zoneNullableInt(
        json['chefEquipeAgentId'] ?? json['ChefEquipeAgentId'],
      ),
      chefEquipeNom: _zoneOptionalString(
        json['chefEquipeNom'] ?? json['ChefEquipeNom'],
      ),
    );
  }

  bool get hasChefEquipe =>
      chefEquipeAgentId != null && chefEquipeAgentId! > 0;

  String get chefEquipeLabel {
    final nom = chefEquipeNom?.trim() ?? '';
    if (nom.isNotEmpty) return nom;
    if (hasChefEquipe) return 'Agent #${chefEquipeAgentId}';
    return 'Non attribué';
  }
}

int _zoneInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _zoneNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

String? _zoneOptionalString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}
