// GET /api/DashboardAgent/kpis

import 'dart:convert';

import '../utils/currency_formatter.dart';
import 'dashboard_agent_model.dart';

dynamic _kpiField(Map<String, dynamic> json, String camelKey) {
  if (json.containsKey(camelKey)) return json[camelKey];
  if (camelKey.isEmpty) return null;
  final pascalKey = camelKey[0].toUpperCase() + camelKey.substring(1);
  return json[pascalKey];
}

double _kpiDouble(Map<String, dynamic> json, String key) {
  final value = _kpiField(json, key);
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _kpiInt(Map<String, dynamic> json, String key) {
  final value = _kpiField(json, key);
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _kpiString(Map<String, dynamic> json, String key) {
  final value = _kpiField(json, key);
  return value?.toString() ?? '';
}

Map<String, dynamic> _toStringKeyMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

bool kpiAgentPayloadLooksValid(Map<String, dynamic> map) {
  return map.containsKey('totalAffilies') ||
      map.containsKey('TotalAffilies') ||
      map.containsKey('collectesMois') ||
      map.containsKey('CollectesMois');
}

Map<String, dynamic>? unwrapKpiAgentJson(dynamic decoded) {
  if (decoded is String) {
    try {
      decoded = jsonDecode(decoded);
    } catch (_) {
      return null;
    }
  }

  if (decoded is! Map) return null;

  final map = _toStringKeyMap(decoded);
  if (kpiAgentPayloadLooksValid(map)) return map;

  for (final key in const [
    'data',
    'Data',
    'result',
    'Result',
    'payload',
    'Payload',
    'kpis',
    'Kpis',
  ]) {
    if (!map.containsKey(key)) continue;
    final nested = unwrapKpiAgentJson(map[key]);
    if (nested != null && kpiAgentPayloadLooksValid(nested)) return nested;
  }

  return map;
}

class KpiAgentModel {
  final int totalAffilies;
  final int collectesMois;
  final double totalCommissionsMois;
  final double totalCollectesMois;
  final String devisePrincipaleCode;
  final int nouvellesAdhesionsMois;
  final int collectesEnAttente;
  final double tauxConversion;
  final double moyenneCollecte;
  final double objectifMois;
  final double progressionObjectif;

  KpiAgentModel({
    required this.totalAffilies,
    required this.collectesMois,
    required this.totalCommissionsMois,
    required this.totalCollectesMois,
    required this.devisePrincipaleCode,
    required this.nouvellesAdhesionsMois,
    required this.collectesEnAttente,
    required this.tauxConversion,
    required this.moyenneCollecte,
    required this.objectifMois,
    required this.progressionObjectif,
  });

  factory KpiAgentModel.fromJson(Map<String, dynamic> json) {
    final devise = _kpiString(json, 'devisePrincipaleCode');
    return KpiAgentModel(
      totalAffilies: _kpiInt(json, 'totalAffilies'),
      collectesMois: _kpiInt(json, 'collectesMois'),
      totalCommissionsMois: _kpiDouble(json, 'totalCommissionsMois'),
      totalCollectesMois: _kpiDouble(json, 'totalCollectesMois'),
      devisePrincipaleCode: devise.isNotEmpty ? devise : 'USD',
      nouvellesAdhesionsMois: _kpiInt(json, 'nouvellesAdhesionsMois'),
      collectesEnAttente: _kpiInt(json, 'collectesEnAttente'),
      tauxConversion: _kpiDouble(json, 'tauxConversion'),
      moyenneCollecte: _kpiDouble(json, 'moyenneCollecte'),
      objectifMois: _kpiDouble(json, 'objectifMois'),
      progressionObjectif: _kpiDouble(json, 'progressionObjectif'),
    );
  }

  factory KpiAgentModel.fromDashboardKpis(DashboardAgentKpis kpis) {
    return KpiAgentModel(
      totalAffilies: kpis.totalAffilies,
      collectesMois: kpis.collectesMois,
      totalCommissionsMois: kpis.totalCommissionsMois,
      totalCollectesMois: kpis.totalCollectesMois,
      devisePrincipaleCode: kpis.devisePrincipaleCode.isNotEmpty
          ? kpis.devisePrincipaleCode
          : 'USD',
      nouvellesAdhesionsMois: kpis.nouvellesAdhesionsMois,
      collectesEnAttente: kpis.collectesEnAttente,
      tauxConversion: kpis.tauxConversion,
      moyenneCollecte: kpis.moyenneCollecte,
      objectifMois: kpis.objectifMois,
      progressionObjectif: kpis.progressionObjectif,
    );
  }

  String formatMontant(double amount) {
    return CurrencyFormatter.formatMovementAmount(
      amount: amount,
      deviseCode: devisePrincipaleCode,
    );
  }

  double get progressionBarValue {
    if (progressionObjectif <= 0) return 0;
    if (progressionObjectif > 1) {
      return (progressionObjectif / 100).clamp(0, 1);
    }
    return progressionObjectif.clamp(0, 1);
  }

  String get progressionLabel {
    return DashboardAgentModel.formatRatioPercent(progressionObjectif);
  }

  String get formattedTotalCollectes => formatMontant(totalCollectesMois);
  String get formattedCommissions => formatMontant(totalCommissionsMois);
  String get formattedMoyenneCollecte => formatMontant(moyenneCollecte);
  String get formattedObjectif => formatMontant(objectifMois);

  String get formattedTauxConversion {
    return DashboardAgentModel.formatRatioPercent(tauxConversion);
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAffilies': totalAffilies,
      'collectesMois': collectesMois,
      'totalCommissionsMois': totalCommissionsMois,
      'totalCollectesMois': totalCollectesMois,
      'devisePrincipaleCode': devisePrincipaleCode,
      'nouvellesAdhesionsMois': nouvellesAdhesionsMois,
      'collectesEnAttente': collectesEnAttente,
      'tauxConversion': tauxConversion,
      'moyenneCollecte': moyenneCollecte,
      'objectifMois': objectifMois,
      'progressionObjectif': progressionObjectif,
    };
  }
}
