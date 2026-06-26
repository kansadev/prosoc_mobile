// GET /api/DashboardAgent/graphs

import 'dart:convert';

dynamic _graphField(Map<String, dynamic> json, String camelKey) {
  if (json.containsKey(camelKey)) return json[camelKey];
  if (camelKey.isEmpty) return null;
  final pascalKey = camelKey[0].toUpperCase() + camelKey.substring(1);
  return json[pascalKey];
}

double _graphDouble(Map<String, dynamic> json, String key) {
  final value = _graphField(json, key);
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _graphInt(Map<String, dynamic> json, String key) {
  final value = _graphField(json, key);
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _graphString(Map<String, dynamic> json, String key) {
  final value = _graphField(json, key);
  return value?.toString() ?? '';
}

DateTime? _graphDate(Map<String, dynamic> json, String key) {
  final raw = _graphField(json, key);
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString());
}

List<Map<String, dynamic>> _graphListMap(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

Map<String, dynamic> _toStringKeyMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

bool dashboardAgentGraphsPayloadLooksValid(Map<String, dynamic> map) {
  return map.containsKey('collectesMensuelles') ||
      map.containsKey('CollectesMensuelles') ||
      map.containsKey('adhesionsMensuelles') ||
      map.containsKey('AdhesionsMensuelles');
}

Map<String, dynamic>? unwrapDashboardAgentGraphsJson(dynamic decoded) {
  if (decoded is String) {
    try {
      decoded = jsonDecode(decoded);
    } catch (_) {
      return null;
    }
  }

  if (decoded is! Map) return null;

  final map = _toStringKeyMap(decoded);
  if (dashboardAgentGraphsPayloadLooksValid(map)) return map;

  for (final key in const [
    'data',
    'Data',
    'result',
    'Result',
    'payload',
    'Payload',
    'graphs',
    'Graphs',
  ]) {
    if (!map.containsKey(key)) continue;
    final nested = unwrapDashboardAgentGraphsJson(map[key]);
    if (nested != null && dashboardAgentGraphsPayloadLooksValid(nested)) {
      return nested;
    }
  }

  return map;
}

class DashboardAgentCollecteMensuelle {
  final String mois;
  final double montant;
  final int nombreCollectes;
  final double moyenne;

  const DashboardAgentCollecteMensuelle({
    required this.mois,
    required this.montant,
    required this.nombreCollectes,
    required this.moyenne,
  });

  factory DashboardAgentCollecteMensuelle.fromJson(Map<String, dynamic> json) {
    return DashboardAgentCollecteMensuelle(
      mois: _graphString(json, 'mois'),
      montant: _graphDouble(json, 'montant'),
      nombreCollectes: _graphInt(json, 'nombreCollectes'),
      moyenne: _graphDouble(json, 'moyenne'),
    );
  }
}

class DashboardAgentAdhesionMensuelle {
  final String mois;
  final int nombreAdhesions;
  final double valeurTotale;

  const DashboardAgentAdhesionMensuelle({
    required this.mois,
    required this.nombreAdhesions,
    required this.valeurTotale,
  });

  factory DashboardAgentAdhesionMensuelle.fromJson(Map<String, dynamic> json) {
    return DashboardAgentAdhesionMensuelle(
      mois: _graphString(json, 'mois'),
      nombreAdhesions: _graphInt(json, 'nombreAdhesions'),
      valeurTotale: _graphDouble(json, 'valeurTotale'),
    );
  }
}

class DashboardAgentCommissionMensuelle {
  final String mois;
  final double montant;
  final double objectif;
  final double progression;

  const DashboardAgentCommissionMensuelle({
    required this.mois,
    required this.montant,
    required this.objectif,
    required this.progression,
  });

  factory DashboardAgentCommissionMensuelle.fromJson(Map<String, dynamic> json) {
    return DashboardAgentCommissionMensuelle(
      mois: _graphString(json, 'mois'),
      montant: _graphDouble(json, 'montant'),
      objectif: _graphDouble(json, 'objectif'),
      progression: _graphDouble(json, 'progression'),
    );
  }
}

class DashboardAgentRepartitionPrestation {
  final String nomPrestation;
  final int nombreSouscriptions;
  final double montantTotal;
  final double pourcentage;

  const DashboardAgentRepartitionPrestation({
    required this.nomPrestation,
    required this.nombreSouscriptions,
    required this.montantTotal,
    required this.pourcentage,
  });

  factory DashboardAgentRepartitionPrestation.fromJson(
    Map<String, dynamic> json,
  ) {
    return DashboardAgentRepartitionPrestation(
      nomPrestation: _graphString(json, 'nomPrestation'),
      nombreSouscriptions: _graphInt(json, 'nombreSouscriptions'),
      montantTotal: _graphDouble(json, 'montantTotal'),
      pourcentage: _graphDouble(json, 'pourcentage'),
    );
  }
}

class DashboardAgentActiviteQuotidienne {
  final DateTime? date;
  final int nombreVisites;
  final int nombreAdhesions;
  final int nombreCollectes;
  final double montantCollectes;

  const DashboardAgentActiviteQuotidienne({
    this.date,
    required this.nombreVisites,
    required this.nombreAdhesions,
    required this.nombreCollectes,
    required this.montantCollectes,
  });

  factory DashboardAgentActiviteQuotidienne.fromJson(Map<String, dynamic> json) {
    return DashboardAgentActiviteQuotidienne(
      date: _graphDate(json, 'date'),
      nombreVisites: _graphInt(json, 'nombreVisites'),
      nombreAdhesions: _graphInt(json, 'nombreAdhesions'),
      nombreCollectes: _graphInt(json, 'nombreCollectes'),
      montantCollectes: _graphDouble(json, 'montantCollectes'),
    );
  }
}

class DashboardAgentGraphsModel {
  final List<DashboardAgentCollecteMensuelle> collectesMensuelles;
  final List<DashboardAgentAdhesionMensuelle> adhesionsMensuelles;
  final List<DashboardAgentCommissionMensuelle> commissionsMensuelles;
  final List<DashboardAgentRepartitionPrestation> repartitionPrestations;
  final List<DashboardAgentActiviteQuotidienne> activiteQuotidienne;

  const DashboardAgentGraphsModel({
    required this.collectesMensuelles,
    required this.adhesionsMensuelles,
    required this.commissionsMensuelles,
    required this.repartitionPrestations,
    required this.activiteQuotidienne,
  });

  factory DashboardAgentGraphsModel.fromJson(Map<String, dynamic> json) {
    return DashboardAgentGraphsModel(
      collectesMensuelles: _graphListMap(_graphField(json, 'collectesMensuelles'))
          .map(DashboardAgentCollecteMensuelle.fromJson)
          .toList(),
      adhesionsMensuelles:
          _graphListMap(_graphField(json, 'adhesionsMensuelles'))
              .map(DashboardAgentAdhesionMensuelle.fromJson)
              .toList(),
      commissionsMensuelles:
          _graphListMap(_graphField(json, 'commissionsMensuelles'))
              .map(DashboardAgentCommissionMensuelle.fromJson)
              .toList(),
      repartitionPrestations:
          _graphListMap(_graphField(json, 'repartitionPrestations'))
              .map(DashboardAgentRepartitionPrestation.fromJson)
              .toList(),
      activiteQuotidienne:
          _graphListMap(_graphField(json, 'activiteQuotidienne'))
              .map(DashboardAgentActiviteQuotidienne.fromJson)
              .toList(),
    );
  }

  bool get hasData =>
      collectesMensuelles.isNotEmpty ||
      adhesionsMensuelles.isNotEmpty ||
      commissionsMensuelles.isNotEmpty ||
      repartitionPrestations.isNotEmpty ||
      activiteQuotidienne.isNotEmpty;
}
