// GET /api/DashboardAgent/terrain | /api/DashboardAgent/performance

import 'dart:convert';

import '../utils/currency_formatter.dart';

dynamic _dashField(Map<String, dynamic> json, String camelKey) {
  if (json.containsKey(camelKey)) return json[camelKey];
  if (camelKey.isEmpty) return null;
  final pascalKey = camelKey[0].toUpperCase() + camelKey.substring(1);
  return json[pascalKey];
}

double _dashDouble(Map<String, dynamic> json, String key) {
  final value = _dashField(json, key);
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _dashInt(Map<String, dynamic> json, String key) {
  final value = _dashField(json, key);
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _dashString(Map<String, dynamic> json, String key) {
  final value = _dashField(json, key);
  return value?.toString() ?? '';
}

DateTime? _dashDate(Map<String, dynamic> json, String key) {
  final raw = _dashField(json, key);
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString());
}

List<Map<String, dynamic>> _dashListMap(dynamic value) {
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

bool _hasDashboardKpis(Map<String, dynamic> map) {
  return map.containsKey('kpis') ||
      map.containsKey('Kpis') ||
      map.containsKey('commissions') ||
      map.containsKey('Commissions');
}

bool dashboardAgentPayloadLooksValid(Map<String, dynamic> map) {
  return _hasDashboardKpis(map);
}

Map<String, dynamic>? unwrapDashboardAgentJson(dynamic decoded) {
  if (decoded is String) {
    try {
      decoded = jsonDecode(decoded);
    } catch (_) {
      return null;
    }
  }

  if (decoded is! Map) return null;

  final map = _toStringKeyMap(decoded);
  if (_hasDashboardKpis(map)) return map;

  for (final key in const [
    'data',
    'Data',
    'result',
    'Result',
    'payload',
    'Payload',
    'value',
    'Value',
    'content',
    'Content',
    'dashboard',
    'Dashboard',
  ]) {
    if (!map.containsKey(key)) continue;
    final nested = unwrapDashboardAgentJson(map[key]);
    if (nested != null && _hasDashboardKpis(nested)) return nested;
  }

  return map;
}

Map<String, dynamic> _dashMap(Map<String, dynamic> json, String key) {
  return _toStringKeyMap(_dashField(json, key));
}

class DashboardAgentKpis {
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

  const DashboardAgentKpis({
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

  factory DashboardAgentKpis.fromJson(Map<String, dynamic> json) {
    return DashboardAgentKpis(
      totalAffilies: _dashInt(json, 'totalAffilies'),
      collectesMois: _dashInt(json, 'collectesMois'),
      totalCommissionsMois: _dashDouble(json, 'totalCommissionsMois'),
      totalCollectesMois: _dashDouble(json, 'totalCollectesMois'),
      devisePrincipaleCode: _dashString(json, 'devisePrincipaleCode'),
      nouvellesAdhesionsMois: _dashInt(json, 'nouvellesAdhesionsMois'),
      collectesEnAttente: _dashInt(json, 'collectesEnAttente'),
      tauxConversion: _dashDouble(json, 'tauxConversion'),
      moyenneCollecte: _dashDouble(json, 'moyenneCollecte'),
      objectifMois: _dashDouble(json, 'objectifMois'),
      progressionObjectif: _dashDouble(json, 'progressionObjectif'),
    );
  }
}

class DashboardAgentPrimeDetail {
  final int idCollecte;
  final int affilieId;
  final String nomAffilie;
  final String nomProduit;
  final String typeProduit;
  final double montantPrime;
  final double? commissionEstimee;
  final DateTime? dateCollecte;
  final String statutPaiement;

  const DashboardAgentPrimeDetail({
    required this.idCollecte,
    required this.affilieId,
    required this.nomAffilie,
    required this.nomProduit,
    required this.typeProduit,
    required this.montantPrime,
    this.commissionEstimee,
    this.dateCollecte,
    required this.statutPaiement,
  });

  factory DashboardAgentPrimeDetail.fromJson(Map<String, dynamic> json) {
    return DashboardAgentPrimeDetail(
      idCollecte: _dashInt(json, 'idCollecte'),
      affilieId: _dashInt(json, 'affilieId'),
      nomAffilie: _dashString(json, 'nomAffilie'),
      nomProduit: _dashString(json, 'nomProduit'),
      typeProduit: _dashString(json, 'typeProduit'),
      montantPrime: _dashDouble(json, 'montantPrime'),
      commissionEstimee: _dashField(json, 'commissionEstimee') == null
          ? null
          : _dashDouble(json, 'commissionEstimee'),
      dateCollecte: _dashDate(json, 'dateCollecte'),
      statutPaiement: _dashString(json, 'statutPaiement'),
    );
  }
}

class DashboardAgentPrimes {
  final double totalPrimesMois;
  final double totalPrimesAssuranceMois;
  final double totalPrimesMutuelleMois;
  final int nombreSouscriptionsMois;
  final List<DashboardAgentPrimeDetail> details;

  const DashboardAgentPrimes({
    required this.totalPrimesMois,
    required this.totalPrimesAssuranceMois,
    required this.totalPrimesMutuelleMois,
    required this.nombreSouscriptionsMois,
    required this.details,
  });

  factory DashboardAgentPrimes.fromJson(Map<String, dynamic> json) {
    return DashboardAgentPrimes(
      totalPrimesMois: _dashDouble(json, 'totalPrimesMois'),
      totalPrimesAssuranceMois: _dashDouble(json, 'totalPrimesAssuranceMois'),
      totalPrimesMutuelleMois: _dashDouble(json, 'totalPrimesMutuelleMois'),
      nombreSouscriptionsMois: _dashInt(json, 'nombreSouscriptionsMois'),
      details: _dashListMap(_dashField(json, 'details'))
          .map(DashboardAgentPrimeDetail.fromJson)
          .toList(),
    );
  }
}

class DashboardAgentMouvementCommission {
  final int idWalletMouvement;
  final double montant;
  final String source;
  final String description;
  final DateTime? dateOperation;
  final String nomAffilie;
  final double montantCollecteLiee;

  const DashboardAgentMouvementCommission({
    required this.idWalletMouvement,
    required this.montant,
    required this.source,
    required this.description,
    required this.dateOperation,
    required this.nomAffilie,
    required this.montantCollecteLiee,
  });

  factory DashboardAgentMouvementCommission.fromJson(Map<String, dynamic> json) {
    return DashboardAgentMouvementCommission(
      idWalletMouvement: _dashInt(json, 'idWalletMouvement'),
      montant: _dashDouble(json, 'montant'),
      source: _dashString(json, 'source'),
      description: _dashString(json, 'description'),
      dateOperation: _dashDate(json, 'dateOperation'),
      nomAffilie: _dashString(json, 'nomAffilie'),
      montantCollecteLiee: _dashDouble(json, 'montantCollecteLiee'),
    );
  }
}

class DashboardAgentCommissions {
  final double soldeWallet;
  final double totalCommissionsMois;
  final double totalCommissionsAnnee;
  final int nombreMouvementsMois;
  final List<DashboardAgentMouvementCommission> mouvementsRecents;

  const DashboardAgentCommissions({
    required this.soldeWallet,
    required this.totalCommissionsMois,
    required this.totalCommissionsAnnee,
    required this.nombreMouvementsMois,
    required this.mouvementsRecents,
  });

  factory DashboardAgentCommissions.fromJson(Map<String, dynamic> json) {
    return DashboardAgentCommissions(
      soldeWallet: _dashDouble(json, 'soldeWallet'),
      totalCommissionsMois: _dashDouble(json, 'totalCommissionsMois'),
      totalCommissionsAnnee: _dashDouble(json, 'totalCommissionsAnnee'),
      nombreMouvementsMois: _dashInt(json, 'nombreMouvementsMois'),
      mouvementsRecents: _dashListMap(_dashField(json, 'mouvementsRecents'))
          .map(DashboardAgentMouvementCommission.fromJson)
          .toList(),
    );
  }
}

class DashboardAgentSuiviAdherent {
  final int idAffilie;
  final int idAdhesion;
  final String codeAdhesion;
  final String nomComplet;
  final String telephone;
  final DateTime? dateAdhesion;
  final String statutDossier;
  final String typeAdhesion;
  final bool cotisationAJour;
  final double totalCollectes;
  final int nombrePrimes;
  final DateTime? derniereActivite;
  final String alerte;

  const DashboardAgentSuiviAdherent({
    required this.idAffilie,
    required this.idAdhesion,
    required this.codeAdhesion,
    required this.nomComplet,
    required this.telephone,
    this.dateAdhesion,
    required this.statutDossier,
    required this.typeAdhesion,
    required this.cotisationAJour,
    required this.totalCollectes,
    required this.nombrePrimes,
    this.derniereActivite,
    required this.alerte,
  });

  factory DashboardAgentSuiviAdherent.fromJson(Map<String, dynamic> json) {
    return DashboardAgentSuiviAdherent(
      idAffilie: _dashInt(json, 'idAffilie'),
      idAdhesion: _dashInt(json, 'idAdhesion'),
      codeAdhesion: _dashString(json, 'codeAdhesion'),
      nomComplet: _dashString(json, 'nomComplet'),
      telephone: _dashString(json, 'telephone'),
      dateAdhesion: _dashDate(json, 'dateAdhesion'),
      statutDossier: _dashString(json, 'statutDossier'),
      typeAdhesion: _dashString(json, 'typeAdhesion'),
      cotisationAJour: _dashField(json, 'cotisationAJour') == true,
      totalCollectes: _dashDouble(json, 'totalCollectes'),
      nombrePrimes: _dashInt(json, 'nombrePrimes'),
      derniereActivite: _dashDate(json, 'derniereActivite'),
      alerte: _dashString(json, 'alerte'),
    );
  }

  bool get hasAlerte => alerte.trim().isNotEmpty;
}

class DashboardAgentObjectifs {
  final int mois;
  final int annee;
  final double objectifCollectes;
  final int objectifAdhesions;
  final double objectifCommissions;
  final double progressionCollectes;
  final int progressionAdhesions;
  final double progressionCommissions;

  const DashboardAgentObjectifs({
    required this.mois,
    required this.annee,
    required this.objectifCollectes,
    required this.objectifAdhesions,
    required this.objectifCommissions,
    required this.progressionCollectes,
    required this.progressionAdhesions,
    required this.progressionCommissions,
  });

  factory DashboardAgentObjectifs.fromJson(Map<String, dynamic> json) {
    return DashboardAgentObjectifs(
      mois: _dashInt(json, 'mois'),
      annee: _dashInt(json, 'annee'),
      objectifCollectes: _dashDouble(json, 'objectifCollectes'),
      objectifAdhesions: _dashInt(json, 'objectifAdhesions'),
      objectifCommissions: _dashDouble(json, 'objectifCommissions'),
      progressionCollectes: _dashDouble(json, 'progressionCollectes'),
      progressionAdhesions: _dashInt(json, 'progressionAdhesions'),
      progressionCommissions: _dashDouble(json, 'progressionCommissions'),
    );
  }
}

class DashboardAgentAffilieRecent {
  final int idAffilie;
  final String nom;
  final String prenom;
  final String telephone;
  final DateTime? dateAdhesion;
  final String typeAdhesion;
  final double derniereCollecte;
  final DateTime? derniereCollecteDate;
  final int nombreCollectes;
  final double totalCollectes;
  final String statutDossier;

  const DashboardAgentAffilieRecent({
    required this.idAffilie,
    required this.nom,
    required this.prenom,
    required this.telephone,
    this.dateAdhesion,
    required this.typeAdhesion,
    required this.derniereCollecte,
    this.derniereCollecteDate,
    required this.nombreCollectes,
    required this.totalCollectes,
    required this.statutDossier,
  });

  factory DashboardAgentAffilieRecent.fromJson(Map<String, dynamic> json) {
    return DashboardAgentAffilieRecent(
      idAffilie: _dashInt(json, 'idAffilie'),
      nom: _dashString(json, 'nom'),
      prenom: _dashString(json, 'prenom'),
      telephone: _dashString(json, 'telephone'),
      dateAdhesion: _dashDate(json, 'dateAdhesion'),
      typeAdhesion: _dashString(json, 'typeAdhesion'),
      derniereCollecte: _dashDouble(json, 'derniereCollecte'),
      derniereCollecteDate: _dashDate(json, 'derniereCollecteDate'),
      nombreCollectes: _dashInt(json, 'nombreCollectes'),
      totalCollectes: _dashDouble(json, 'totalCollectes'),
      statutDossier: _dashString(json, 'statutDossier'),
    );
  }

  String get nomComplet {
    return [prenom, nom].where((p) => p.trim().isNotEmpty).join(' ').trim();
  }
}

class DashboardAgentModel {
  final int agentId;
  final String nomAgent;
  final DashboardAgentKpis kpis;
  final DashboardAgentPrimes primes;
  final DashboardAgentCommissions commissions;
  final List<DashboardAgentSuiviAdherent> suiviAdherents;
  final List<DashboardAgentAffilieRecent> affiliesRecents;
  final List<dynamic> collectesEnAttente;
  final DashboardAgentObjectifs objectifs;
  final DateTime? dateGeneration;
  final String devisePrincipaleCode;

  DashboardAgentModel({
    required this.agentId,
    required this.nomAgent,
    required this.kpis,
    required this.primes,
    required this.commissions,
    required this.suiviAdherents,
    required this.affiliesRecents,
    required this.collectesEnAttente,
    required this.objectifs,
    this.dateGeneration,
    required this.devisePrincipaleCode,
  });

  factory DashboardAgentModel.fromJson(Map<String, dynamic> json) {
    final kpisMap = _dashMap(json, 'kpis');
    final deviseRoot = _dashString(json, 'devisePrincipaleCode');
    final deviseKpis = _dashString(kpisMap, 'devisePrincipaleCode');
    final devise =
        deviseRoot.isNotEmpty ? deviseRoot : deviseKpis;

    return DashboardAgentModel(
      agentId: _dashInt(json, 'agentId'),
      nomAgent: _dashString(json, 'nomAgent'),
      kpis: DashboardAgentKpis.fromJson(kpisMap),
      primes: DashboardAgentPrimes.fromJson(_dashMap(json, 'primes')),
      commissions: DashboardAgentCommissions.fromJson(
        _dashMap(json, 'commissions'),
      ),
      suiviAdherents: _dashListMap(_dashField(json, 'suiviAdherents'))
          .map(DashboardAgentSuiviAdherent.fromJson)
          .toList(),
      affiliesRecents: _dashListMap(_dashField(json, 'affiliesRecents'))
          .map(DashboardAgentAffilieRecent.fromJson)
          .toList(),
      collectesEnAttente:
          _dashField(json, 'collectesEnAttente') is List
              ? List<dynamic>.from(_dashField(json, 'collectesEnAttente') as List)
              : const [],
      objectifs: DashboardAgentObjectifs.fromJson(_dashMap(json, 'objectifs')),
      dateGeneration: _dashDate(json, 'dateGeneration'),
      devisePrincipaleCode: devise.isNotEmpty ? devise : 'USD',
    );
  }

  String formatMontant(double amount, {bool withSign = false}) {
    return CurrencyFormatter.formatMovementAmount(
      amount: amount,
      deviseCode: devisePrincipaleCode,
      withSign: withSign,
    );
  }

  static String formatRatioPercent(double value) {
    if (value > 0 && value <= 1) {
      return '${(value * 100).toStringAsFixed(1)} %';
    }
    return '${value.toStringAsFixed(0)} %';
  }

  int get adherentsEnAlerte =>
      suiviAdherents.where((a) => a.hasAlerte).length;

  int get adherentsCotisationRetard =>
      suiviAdherents.where((a) => !a.cotisationAJour).length;

  String get messageSynthese {
    final k = kpis;
    final parts = <String>[];

    if (k.collectesEnAttente > 0) {
      parts.add(
        '${k.collectesEnAttente} collecte(s) en attente de validation',
      );
    }
    if (adherentsCotisationRetard > 0) {
      parts.add(
        '$adherentsCotisationRetard affilié(s) en retard de cotisation',
      );
    }
    if (k.nouvellesAdhesionsMois > 0) {
      parts.add(
        '${k.nouvellesAdhesionsMois} nouvelle(s) adhésion(s) ce mois',
      );
    }

    if (parts.isEmpty) {
      return 'Ce mois-ci : ${formatMontant(k.totalCollectesMois)} collectés '
          '(${k.collectesMois} opérations) · commissions '
          '${formatMontant(k.totalCommissionsMois)}';
    }

    return parts.join(' · ');
  }
}
