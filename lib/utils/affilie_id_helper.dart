/// Résout l'identifiant affilié depuis les payloads API (noms de champs variables).
int resolveAffilieId(Map<String, dynamic> json) {
  final raw = json['idAffilie'] ?? json['affilieId'] ?? json['id'];
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw.trim()) ?? 0;
  return 0;
}
