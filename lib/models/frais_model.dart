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
  bool get isFraisAdhesion {
    final normalized = codeNormalise;
    return normalized == normalizeCode('FRAIS_ADHESION') ||
        (normalized.contains('FRAIS') && normalized.contains('ADHESION'));
  }

  factory Frais.fromJson(Map<String, dynamic> json) {
    return Frais(
      idFrais: json['idFrais'] ?? json['id'] ?? json['fraisId'] ?? 0,
      code: json['code'] as String? ?? '',
      libelle: json['libelle'] ?? '',
      montant: (json['montant'] ?? 0).toDouble(),
      tauxCommission: (json['tauxCommission'] ?? 0).toDouble(),
      periodicite: json['periodicite'] as String? ?? '',
      deviseId: json['deviseId'] ?? 0,
      dateCreation: DateTime.parse(
        json['dateCreation'] ?? DateTime.now().toIso8601String(),
      ),
      dateModification: json['dateModification'] != null
          ? DateTime.parse(json['dateModification'])
          : null,
      statut: json['statut'] ?? true,
      creeParId: json['creeParId'],
      modifieParId: json['modifieParId'],
      dateSuppression: json['dateSuppression'] != null
          ? DateTime.parse(json['dateSuppression'])
          : null,
      estSupprime: json['estSupprime'] ?? false,
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
