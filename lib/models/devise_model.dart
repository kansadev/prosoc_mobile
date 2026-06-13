int _deviseModelInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

double _deviseModelDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

bool _deviseModelBool(dynamic value) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return false;
}

class Devise {
  final int idDevise;
  final String code;
  final String nom;
  final String? symbole;
  final double tauxChange;
  final bool statut;
  final bool estDevisePrincipale;

  Devise({
    required this.idDevise,
    required this.code,
    required this.nom,
    this.symbole,
    required this.tauxChange,
    required this.statut,
    this.estDevisePrincipale = false,
  });

  factory Devise.fromJson(Map<String, dynamic> json) {
    return Devise(
      idDevise: _deviseModelInt(json['idDevise'] ?? json['id']),
      code: (json['code'] ?? json['codeDevise'] ?? '').toString(),
      nom: (json['nom'] ?? json['nomDevise'] ?? '').toString(),
      symbole: json['symbole']?.toString(),
      tauxChange: _deviseModelDouble(json['tauxChange']),
      statut: _deviseModelBool(json['statut'] ?? json['statutDevise'] ?? true),
      estDevisePrincipale: _deviseModelBool(
        json['estDevisePrincipale'] ?? json['EstDevisePrincipale'] ?? false,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idDevise': idDevise,
      'code': code,
      'nom': nom,
      if (symbole != null) 'symbole': symbole,
      'tauxChange': tauxChange,
      'statut': statut,
      'estDevisePrincipale': estDevisePrincipale,
    };
  }

  @override
  String toString() {
    return 'Devise(idDevise: $idDevise, code: $code, nom: $nom)';
  }

  /// Devise principale en premier, puis CDF / USD, puis le reste.
  static int compareByPriority(Devise a, Devise b) {
    if (a.estDevisePrincipale != b.estDevisePrincipale) {
      return a.estDevisePrincipale ? -1 : 1;
    }

    int priority(Devise d) {
      if (d.idDevise == 1) return 0;
      if (d.idDevise == 2) return 1;
      return 2;
    }

    final p = priority(a).compareTo(priority(b));
    if (p != 0) return p;
    return a.idDevise.compareTo(b.idDevise);
  }

  static List<Map<String, dynamic>> sortRowsByPriority(List<dynamic> rows) {
    final maps = rows
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    maps.sort(
      (a, b) => compareByPriority(
        Devise.fromJson(a),
        Devise.fromJson(b),
      ),
    );
    return maps;
  }
}
