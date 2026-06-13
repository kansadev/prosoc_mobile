import '../models/dashboard_affilie_model.dart';

/// Lecture tolérante des payloads API (camelCase / PascalCase).
class ContributionsScreenHelper {
  ContributionsScreenHelper._();

  static Map<String, dynamic> asMap(dynamic item) {
    if (item is Map<String, dynamic>) return item;
    if (item is Map) return Map<String, dynamic>.from(item);
    return const {};
  }

  static List<Map<String, dynamic>> asMapList(dynamic raw) {
    if (raw is List) {
      return raw.map(asMap).where((m) => m.isNotEmpty).toList();
    }
    if (raw is Map) {
      final map = asMap(raw);
      for (final key in ['data', 'Data', 'items', 'Items', 'result', 'Result']) {
        final nested = map[key];
        if (nested is List) {
          return nested.map(asMap).where((m) => m.isNotEmpty).toList();
        }
      }
    }
    return const [];
  }

  static String str(Map<String, dynamic> m, List<String> keys) {
    for (final key in keys) {
      final v = m[key];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  static double dbl(Map<String, dynamic> m, List<String> keys) {
    for (final key in keys) {
      final v = m[key];
      if (v is num) return v.toDouble();
      if (v is String) {
        final parsed = double.tryParse(v.trim());
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }

  static int integer(Map<String, dynamic> m, List<String> keys) {
    for (final key in keys) {
      final v = m[key];
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) {
        final parsed = int.tryParse(v.trim());
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }

  static bool boolean(Map<String, dynamic> m, List<String> keys) {
    for (final key in keys) {
      final v = m[key];
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final lower = v.toLowerCase();
        if (lower == 'true' || lower == '1') return true;
        if (lower == 'false' || lower == '0') return false;
      }
    }
    return false;
  }

  static bool isTarifActif(Map<String, dynamic> tarif) {
    if (tarif.containsKey('statut')) {
      final statut = tarif['statut'] ?? tarif['Statut'];
      if (statut is bool) return statut;
      if (statut is num) return statut != 0;
      if (statut is String) {
        final lower = statut.toLowerCase();
        return lower != 'false' && lower != '0' && lower != 'inactif';
      }
    }
    return true;
  }

  static int? tarifId(Map<String, dynamic> tarif) {
    final id = integer(tarif, [
      'id',
      'Id',
      'tarifCotisationId',
      'TarifCotisationId',
    ]);
    return id > 0 ? id : null;
  }

  static String tarifLibelle(Map<String, dynamic> tarif) {
    return str(tarif, [
      'typeAdhesionLibelle',
      'TypeAdhesionLibelle',
      'libelle',
      'Libelle',
      'nom',
      'Nom',
    ]);
  }

  static String tarifPeriodicite(Map<String, dynamic> tarif) {
    return str(tarif, ['periodicite', 'Periodicite']);
  }

  static double tarifMontant(Map<String, dynamic> tarif) {
    return dbl(tarif, ['montant', 'Montant', 'montantTotal', 'MontantTotal']);
  }

  /// Arriérés — champs API variables.
  static String arrierePeriode(Map<String, dynamic> a) {
    return str(a, [
      'periode',
      'Periode',
      'moisAnnee',
      'MoisAnnee',
      'libelle',
      'Libelle',
    ]);
  }

  static double arriereMontantAttendu(Map<String, dynamic> a) {
    return dbl(a, ['montantAttendu', 'MontantAttendu', 'montant', 'Montant']);
  }

  static double arriereMontantPaye(Map<String, dynamic> a) {
    return dbl(a, [
      'montantPaye',
      'MontantPaye',
      'montantRecu',
      'MontantRecu',
      'montantCollecte',
      'MontantCollecte',
    ]);
  }

  static double arriereReste(Map<String, dynamic> a) {
    final direct = dbl(a, ['restAPayer', 'RestAPayer', 'resteAPayer', 'ResteAPayer']);
    if (direct > 0) return direct;
    final attendu = arriereMontantAttendu(a);
    final paye = arriereMontantPaye(a);
    if (attendu > paye) return attendu - paye;
    return 0;
  }

  static int arriereJoursRetard(Map<String, dynamic> a) {
    return integer(a, ['joursRetard', 'JoursRetard', 'nombreJoursRetard']);
  }

  static bool arriereEstPaye(Map<String, dynamic> a) {
    if (boolean(a, ['estCompletementPaye', 'EstCompletementPaye'])) {
      return true;
    }
    final statut = str(a, ['statutPaiement', 'StatutPaiement', 'statut', 'Statut']);
    if (statut.toUpperCase() == 'OK' || statut.toUpperCase() == 'PAYE') {
      return true;
    }
    return arriereReste(a) <= 0 && arriereMontantAttendu(a) > 0;
  }

  static double arriereTauxPaiement(Map<String, dynamic> a) {
    final raw = dbl(a, ['tauxPaiement', 'TauxPaiement']);
    if (raw > 1) return raw;
    if (raw > 0) return raw * 100;
    final attendu = arriereMontantAttendu(a);
    if (attendu <= 0) return 0;
    return (arriereMontantPaye(a) / attendu) * 100;
  }

  /// Collecte paginée — historique paiements.
  static String collecteType(Map<String, dynamic> c) {
    return str(c, ['typeCollecte', 'TypeCollecte']);
  }

  static double collecteMontant(Map<String, dynamic> c) {
    return dbl(c, [
      'montant',
      'Montant',
      'montantCollecte',
      'MontantCollecte',
      'montantRecu',
      'MontantRecu',
    ]);
  }

  static String collecteStatut(Map<String, dynamic> c) {
    return str(c, ['statutPaiement', 'StatutPaiement', 'statut', 'Statut']);
  }

  static String? collecteDateRaw(Map<String, dynamic> c) {
    for (final key in [
      'dateCollecte',
      'DateCollecte',
      'dateCotisation',
      'DateCotisation',
      'datePaiement',
      'DatePaiement',
    ]) {
      final v = c[key];
      if (v == null) continue;
      return v.toString();
    }
    return null;
  }

  static bool collecteEstSucces(String statut) {
    final s = statut.toUpperCase();
    return s == 'OK' || s == 'PAYE' || s == 'VALIDE' || s == 'SUCCESS';
  }

  static String collecteTitre(Map<String, dynamic> c) {
    final type = collecteType(c).toUpperCase();
    if (type == 'FRAIS') {
      final lib = str(c, ['fraisLibelle', 'FraisLibelle']);
      return lib.isNotEmpty ? lib : 'Frais';
    }
    if (type == 'COTISATION') {
      final lib = str(c, [
        'cotisationLibelle',
        'CotisationLibelle',
        'typeAdhesionLibelle',
        'TypeAdhesionLibelle',
        'typeCotisation',
        'TypeCotisation',
      ]);
      return lib.isNotEmpty ? lib : 'Cotisation';
    }
    final prestation = str(c, ['prestationLibelle', 'PrestationLibelle']);
    return prestation.isNotEmpty ? prestation : 'Paiement';
  }

  static List<DashboardAffilieCotisation> cotisationsEnRetard(
    List<DashboardAffilieCotisation> source,
  ) {
    return source.where((c) => c.estEnRetard).toList();
  }
}
