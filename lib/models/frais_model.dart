class Frais {
  final int idFrais;
  final String code;
  final String libelle;
  final double montant;
  final double tauxCommission;
  final String periodicite;
  final int deviseId;
  final DateTime dateCreation;
  final DateTime? dateModification;
  final bool statut;
  final int? creeParId;
  final int? modifieParId;
  final DateTime? dateSuppression;
  final bool estSupprime;

  Frais({
    required this.idFrais,
    required this.code,
    required this.libelle,
    required this.montant,
    required this.tauxCommission,
    required this.periodicite,
    required this.deviseId,
    required this.dateCreation,
    this.dateModification,
    required this.statut,
    this.creeParId,
    this.modifieParId,
    this.dateSuppression,
    required this.estSupprime,
  });

  /// Frais proposés lors d'une nouvelle adhésion.
  static const codesAdhesion = {'FRAIS_ADHESION', 'CARTE_MEMBRE'};

  /// Normalise un code pour comparaison : majuscules, accents retirés et
  /// séparateurs (espace, tiret, underscore) supprimés.
  /// « FRAIS ADHÉSION » et « FRAIS_ADHESION » deviennent identiques.
  static String normalizeCode(String value) {
    const accents = <String, String>{
      'À': 'A',
      'Á': 'A',
      'Â': 'A',
      'Ã': 'A',
      'Ä': 'A',
      'Å': 'A',
      'È': 'E',
      'É': 'E',
      'Ê': 'E',
      'Ë': 'E',
      'Ì': 'I',
      'Í': 'I',
      'Î': 'I',
      'Ï': 'I',
      'Ò': 'O',
      'Ó': 'O',
      'Ô': 'O',
      'Õ': 'O',
      'Ö': 'O',
      'Ù': 'U',
      'Ú': 'U',
      'Û': 'U',
      'Ü': 'U',
      'Ç': 'C',
      'Ñ': 'N',
      'Ý': 'Y',
    };
    final buffer = StringBuffer();
    for (final rune in value.toUpperCase().runes) {
      final char = String.fromCharCode(rune);
      final letter = accents[char] ?? char;
      if (RegExp('[A-Z0-9]').hasMatch(letter)) {
        buffer.write(letter);
      }
    }
    return buffer.toString();
  }

  /// Code de ce frais normalisé (insensible casse / accents / séparateurs).
  String get codeNormalise => normalizeCode(code);

  bool get isPourAdhesion {
    final normalized = codeNormalise;
    return codesAdhesion.any((c) => normalizeCode(c) == normalized) ||
        normalized.contains(normalizeCode('ADHESION')) ||
        normalized.contains(normalizeCode('CARTE_MEMBRE'));
  }

  /// Uniquement le frais d'adhésion (exclut carte membre et autres frais).
  /// Reconnu par son code, ou par son libellé quand le code est absent
  /// (référentiels synchronisés pour le mode hors ligne).
  bool get isFraisAdhesion {
    bool correspond(String valeur) {
      final normalized = normalizeCode(valeur);
      return normalized == normalizeCode('FRAIS_ADHESION') ||
          (normalized.contains('FRAIS') && normalized.contains('ADHESION'));
    }

    return correspond(code) || (code.trim().isEmpty && correspond(libelle));
  }

  static dynamic _champ(Map<String, dynamic> json, List<String> cles) {
    for (final cle in cles) {
      final valeur = json[cle] ??
          json[cle.isEmpty ? cle : cle[0].toUpperCase() + cle.substring(1)];
      if (valeur != null) return valeur;
    }
    return null;
  }

  static int _int(dynamic v) =>
      v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

  static int? _intOrNull(dynamic v) => v == null ? null : _int(v);

  static double _double(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

  static bool _bool(dynamic v, {required bool fallback}) {
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    return fallback;
  }

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  /// Tolérant : camelCase / PascalCase, nombres ou textes (API et
  /// référentiels de synchronisation).
  factory Frais.fromJson(Map<String, dynamic> json) {
    return Frais(
      idFrais: _int(_champ(json, ['idFrais', 'id', 'fraisId'])),
      code: (_champ(json, ['code', 'codeFrais']) ?? '').toString(),
      libelle: (_champ(json, ['libelle', 'nom']) ?? '').toString(),
      montant: _double(_champ(json, ['montant'])),
      tauxCommission: _double(_champ(json, ['tauxCommission'])),
      periodicite: (_champ(json, ['periodicite']) ?? '').toString(),
      deviseId: _int(_champ(json, ['deviseId'])),
      dateCreation: _date(_champ(json, ['dateCreation'])) ?? DateTime.now(),
      dateModification: _date(_champ(json, ['dateModification'])),
      statut: _bool(_champ(json, ['statut']), fallback: true),
      creeParId: _intOrNull(_champ(json, ['creeParId'])),
      modifieParId: _intOrNull(_champ(json, ['modifieParId'])),
      dateSuppression: _date(_champ(json, ['dateSuppression'])),
      estSupprime: _bool(_champ(json, ['estSupprime']), fallback: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idFrais': idFrais,
      'code': code,
      'libelle': libelle,
      'montant': montant,
      'tauxCommission': tauxCommission,
      'periodicite': periodicite,
      'deviseId': deviseId,
      'dateCreation': dateCreation.toIso8601String(),
      'dateModification': dateModification?.toIso8601String(),
      'statut': statut,
      'creeParId': creeParId,
      'modifieParId': modifieParId,
      'dateSuppression': dateSuppression?.toIso8601String(),
      'estSupprime': estSupprime,
    };
  }
}
