class Dependant {
  final int idDependant;
  final String nom;
  final String? adresse;
  final String lienParente;
  final int affilieId;
  final DateTime? dateNaissance;
  final String? telephone;
  final DateTime? dateCreation;
  final DateTime? dateModification;
  final bool statut;
  final bool possedeCertificatScolarite;

  Dependant({
    required this.idDependant,
    required this.nom,
    this.adresse,
    required this.lienParente,
    required this.affilieId,
    this.dateNaissance,
    this.telephone,
    this.dateCreation,
    this.dateModification,
    required this.statut,
    required this.possedeCertificatScolarite,
  });

  factory Dependant.fromJson(Map<String, dynamic> json) {
    return Dependant(
      idDependant: _asInt(json['idDependant'] ?? json['id']),
      nom: _nomFromJson(json),
      adresse: _stringOrNull(json['adresse']),
      lienParente: (json['lienParente'] ?? '').toString(),
      affilieId: _asInt(json['affilieId']),
      dateNaissance: _parseDate(json['dateNaissance']),
      telephone: _stringOrNull(json['telephone']),
      dateCreation: _parseDate(json['dateCreation']),
      dateModification: _parseDate(json['dateModification']),
      statut: _asBool(json['statut'] ?? json['statutDependant'], defaultValue: true),
      possedeCertificatScolarite: _asBool(
        json['possedeCertificatScolarite'],
        defaultValue: false,
      ),
    );
  }

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  static bool _asBool(dynamic value, {required bool defaultValue}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return defaultValue;
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String _nomFromJson(Map<String, dynamic> json) {
    final nom = _stringOrNull(json['nom']);
    if (nom != null) return nom;

    final parts = <String>[
      if (_stringOrNull(json['prenomDependant']) != null)
        _stringOrNull(json['prenomDependant'])!,
      if (_stringOrNull(json['nomDependant']) != null)
        _stringOrNull(json['nomDependant'])!,
      if (_stringOrNull(json['postnomDependant']) != null)
        _stringOrNull(json['postnomDependant'])!,
    ];
    return parts.join(' ').trim();
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  /// Libellé affiché (ex. ENFANT → Enfant).
  String get lienParenteLabel {
    final lower = lienParente.toLowerCase();
    if (lower.isEmpty) return lienParente;
    if (lower == 'fille') return 'Fille';
    if (lower == 'enfant') return 'Enfant';
    if (lower.contains('conjoint')) return 'Conjoint(e)';
    if (lower == 'frere' || lower == 'frère') return 'Frère';
    if (lower == 'soeur' || lower == 'sœur') return 'Sœur';
    if (lower == 'oncle') return 'Oncle';
    if (lower == 'tante') return 'Tante';
    if (lower.contains('cousin')) return 'Cousin(e)';
    return lienParente[0].toUpperCase() + lienParente.substring(1).toLowerCase();
  }

  /// Libellé formulaire à partir de la valeur API.
  static String? lienParenteToFormValue(String apiValue) {
    final u = apiValue.trim().toUpperCase();
    switch (u) {
      case 'CONJOINT':
        return 'Conjoint(e)';
      case 'ENFANT':
      case 'FILLE':
        return 'Enfant';
      case 'FRERE':
      case 'FRÈRE':
        return 'Frère';
      case 'SOEUR':
      case 'SŒUR':
        return 'Sœur';
      case 'ONCLE':
        return 'Oncle';
      case 'TANTE':
        return 'Tante';
      case 'COUSIN':
        return 'Cousin(e)';
    }
    return null;
  }

  /// Valeur attendue par l'API à la création.
  static String lienParenteForApi(String formValue) {
    switch (formValue) {
      case 'Conjoint(e)':
        return 'CONJOINT';
      case 'Enfant':
        return 'ENFANT';
      case 'Frère':
        return 'FRERE';
      case 'Sœur':
        return 'SOEUR';
      case 'Oncle':
        return 'ONCLE';
      case 'Tante':
        return 'TANTE';
      case 'Cousin(e)':
        return 'COUSIN';
      default:
        return formValue.toUpperCase();
    }
  }
}
