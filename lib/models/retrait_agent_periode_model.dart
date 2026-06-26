// GET /api/RetraitAgent/periode-courante

dynamic _periodeField(Map<String, dynamic> json, String camelKey) {
  if (json.containsKey(camelKey)) return json[camelKey];
  if (camelKey.isEmpty) return null;
  final pascalKey = camelKey[0].toUpperCase() + camelKey.substring(1);
  return json[pascalKey];
}

double _periodeDouble(Map<String, dynamic> json, String key) {
  final value = _periodeField(json, key);
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _periodeInt(Map<String, dynamic> json, String key) {
  final value = _periodeField(json, key);
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _periodeString(Map<String, dynamic> json, String key) {
  final value = _periodeField(json, key);
  return value?.toString() ?? '';
}

bool _periodeBool(Map<String, dynamic> json, String key) {
  final value = _periodeField(json, key);
  return value == true;
}

Map<String, dynamic>? unwrapRetraitPeriodeJson(dynamic decoded) {
  if (decoded is! Map) return null;
  final map = decoded is Map<String, dynamic>
      ? decoded
      : Map<String, dynamic>.from(decoded);
  if (map.containsKey('estPeriodeAutorisee') ||
      map.containsKey('EstPeriodeAutorisee')) {
    return map;
  }
  for (final key in const ['data', 'Data', 'result', 'Result']) {
    final nested = map[key];
    if (nested is Map) {
      return unwrapRetraitPeriodeJson(nested);
    }
  }
  return map;
}

class RetraitAgentPeriodeCourante {
  final DateTime? date;
  final bool estPeriodeAutorisee;
  final String message;
  final int jourDuMois;
  final String periodeInfo;
  final int fenetre1Debut;
  final int fenetre1Fin;
  final int fenetre2Debut;
  final int fenetre2Fin;
  final String fenetreActive;
  final String typeRetraitAutorise;
  final double montantMinimumPartiel;
  final bool montantDemandeRequis;

  const RetraitAgentPeriodeCourante({
    this.date,
    required this.estPeriodeAutorisee,
    required this.message,
    required this.jourDuMois,
    required this.periodeInfo,
    required this.fenetre1Debut,
    required this.fenetre1Fin,
    required this.fenetre2Debut,
    required this.fenetre2Fin,
    required this.fenetreActive,
    required this.typeRetraitAutorise,
    required this.montantMinimumPartiel,
    required this.montantDemandeRequis,
  });

  factory RetraitAgentPeriodeCourante.fromJson(Map<String, dynamic> json) {
    final rawDate = _periodeField(json, 'date');
    return RetraitAgentPeriodeCourante(
      date: rawDate == null ? null : DateTime.tryParse(rawDate.toString()),
      estPeriodeAutorisee: _periodeBool(json, 'estPeriodeAutorisee'),
      message: _periodeString(json, 'message'),
      jourDuMois: _periodeInt(json, 'jourDuMois'),
      periodeInfo: _periodeString(json, 'periodeInfo'),
      fenetre1Debut: _periodeInt(json, 'fenetre1Debut'),
      fenetre1Fin: _periodeInt(json, 'fenetre1Fin'),
      fenetre2Debut: _periodeInt(json, 'fenetre2Debut'),
      fenetre2Fin: _periodeInt(json, 'fenetre2Fin'),
      fenetreActive: _periodeString(json, 'fenetreActive'),
      typeRetraitAutorise: _periodeString(json, 'typeRetraitAutorise'),
      montantMinimumPartiel: _periodeDouble(json, 'montantMinimumPartiel'),
      montantDemandeRequis: _periodeBool(json, 'montantDemandeRequis'),
    );
  }

  bool get isRetraitTotal =>
      typeRetraitAutorise.trim().toUpperCase() == 'TOTAL';

  bool get isRetraitPartiel =>
      typeRetraitAutorise.trim().toUpperCase() == 'PARTIEL';

  String get statusLabel => estPeriodeAutorisee
      ? 'Période de retrait ouverte'
      : 'Période de retrait fermée';

  String get fenetresDescription =>
      'Fenêtre 1 : $fenetre1Debut–$fenetre1Fin · '
      'Fenêtre 2 : $fenetre2Debut–$fenetre2Fin';

  String get activeWindowLabel {
    final active = fenetreActive.trim();
    if (active.isEmpty) return periodeInfo;
    if (periodeInfo.isNotEmpty) return '$active ($periodeInfo)';
    return active;
  }

  String get typeRetraitLabel {
    if (isRetraitTotal) {
      return 'Retrait total du solde disponible requis';
    }
    if (isRetraitPartiel && montantMinimumPartiel > 0) {
      return 'Retrait partiel autorisé (min. $montantMinimumPartiel)';
    }
    return 'Retrait autorisé';
  }
}
