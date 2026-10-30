/// Affilié listé par `GET /api/Agent/{agentId}/affilies`.
///
/// Volontairement minimal : seuls les champs nécessaires à la liste et à la
/// réaffectation sont conservés.
class AgentAffilieRow {
  final int idAffilie;
  final String nomComplet;
  final String matricule;
  final String? telephone;
  final String? statutDossier;
  final DateTime? dateAdhesion;

  const AgentAffilieRow({
    required this.idAffilie,
    required this.nomComplet,
    required this.matricule,
    this.telephone,
    this.statutDossier,
    this.dateAdhesion,
  });

  factory AgentAffilieRow.fromJson(Map<String, dynamic> json) {
    final nom = (json['nom'] ?? json['Nom'] ?? '').toString().trim();
    final prenom = (json['prenom'] ?? json['Prenom'] ?? '').toString().trim();
    final nomComplet = (json['nomComplet'] ?? json['NomComplet'] ?? '')
        .toString()
        .trim();
    final fullName = [prenom, nom].where((e) => e.isNotEmpty).join(' ');

    return AgentAffilieRow(
      idAffilie: _toInt(
        json['idAffilie'] ??
            json['IdAffilie'] ??
            json['affilieId'] ??
            json['AffilieId'] ??
            json['id'] ??
            json['Id'],
      ),
      nomComplet: fullName.isNotEmpty
          ? fullName
          : (nomComplet.isNotEmpty ? nomComplet : 'Affilié'),
      matricule:
          (json['matricule'] ??
                  json['Matricule'] ??
                  json['codeAdhesion'] ??
                  json['CodeAdhesion'] ??
                  '')
              .toString()
              .trim(),
      telephone: _firstNonEmpty([
        json['phone'],
        json['Phone'],
        json['telephone'],
        json['Telephone'],
      ]),
      statutDossier: _firstNonEmpty([
        json['statutDossier'],
        json['StatutDossier'],
      ]),
      dateAdhesion: _toDate(json['dateAdhesion'] ?? json['DateAdhesion']),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

/// Première valeur non vide d'une liste de champs possibles.
String? _firstNonEmpty(List<dynamic> values) {
  for (final value in values) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return null;
}

DateTime? _toDate(dynamic value) {
  if (value is DateTime) return value;
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
