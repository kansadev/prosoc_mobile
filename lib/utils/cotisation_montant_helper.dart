import '../models/penalite_affilie_model.dart';

/// Calcul du montant total d'une cotisation selon le type d'adhésion et pénalités.
class CotisationMontantHelper {
  CotisationMontantHelper._();

  /// Nombre de personnes couvertes par la cotisation.
  ///
  /// - Solo : 1
  /// - Couple : 2 (affilié + conjoint)
  /// - F3 / F6 / autres : 1 affilié + dépendants enregistrés
  static int multiplicateurPersonnes({
    required String typeAdhesionLibelle,
    required int nombreDependants,
  }) {
    final libelle = typeAdhesionLibelle.trim().toLowerCase();
    if (libelle.contains('solo')) return 1;
    if (libelle.contains('couple')) return 2;
    return 1 + nombreDependants;
  }

  static double? montantTotal({
    required double? tarifUnitaire,
    required String typeAdhesionLibelle,
    required int nombreDependants,
  }) {
    if (tarifUnitaire == null || tarifUnitaire <= 0) return null;
    return tarifUnitaire *
        multiplicateurPersonnes(
          typeAdhesionLibelle: typeAdhesionLibelle,
          nombreDependants: nombreDependants,
        );
  }

  /// Somme des pénalités encore dues.
  static double montantPenalitesDues(
    Iterable<PenaliteAffilieModel> penalites,
  ) {
    return penalites
        .where((penalite) => penalite.estPayable)
        .fold<double>(0, (sum, penalite) => sum + penalite.montant);
  }

  /// Pénalités dues pour un arriéré donné.
  static List<PenaliteAffilieModel> penalitesPourArriere(
    Iterable<PenaliteAffilieModel> penalites,
    int arrieresAffilieId,
  ) {
    if (arrieresAffilieId <= 0) return const [];
    return penalites
        .where(
          (penalite) =>
              penalite.arrieresAffilieId == arrieresAffilieId &&
              penalite.estPayable,
        )
        .toList();
  }

  /// Montant cotisation + pénalités dues.
  static double? montantTotalAvecPenalites({
    required double? montantCotisation,
    Iterable<PenaliteAffilieModel> penalites = const [],
  }) {
    final penalitesDues = montantPenalitesDues(penalites);
    if (montantCotisation == null || montantCotisation <= 0) {
      return penalitesDues > 0 ? penalitesDues : null;
    }
    return montantCotisation + penalitesDues;
  }

  /// Reste à payer d'un arriéré incluant les pénalités liées.
  static double resteArriereAvecPenalites({
    required double restAPayer,
    required double montantAttendu,
    required Iterable<PenaliteAffilieModel> penalites,
    required int arrieresAffilieId,
  }) {
    final base = restAPayer > 0 ? restAPayer : montantAttendu;
    return montantTotalAvecPenalites(
          montantCotisation: base,
          penalites: penalitesPourArriere(penalites, arrieresAffilieId),
        ) ??
        base;
  }

  static String libelleCalcul({
    required double tarifUnitaire,
    required String typeAdhesionLibelle,
    required int nombreDependants,
    String? deviseCode,
  }) {
    final mult = multiplicateurPersonnes(
      typeAdhesionLibelle: typeAdhesionLibelle,
      nombreDependants: nombreDependants,
    );
    final devise = (deviseCode ?? '').trim();
    final suffix = devise.isNotEmpty ? ' $devise' : '';
    final total = tarifUnitaire * mult;

    if (mult <= 1) {
      return 'Tarif unitaire$suffix';
    }

    return '$tarifUnitaire$suffix × $mult personne${mult > 1 ? 's' : ''} = $total$suffix';
  }

  /// Détail des pénalités incluses dans le montant.
  static String? libellePenalites({
    required Iterable<PenaliteAffilieModel> penalites,
    String? deviseCode,
  }) {
    final dues = penalites.where((penalite) => penalite.estPayable).toList();
    if (dues.isEmpty) return null;

    final total = montantPenalitesDues(dues);
    final devise = (deviseCode ?? '').trim();
    final suffix = devise.isNotEmpty ? ' $devise' : '';

    if (dues.length == 1) {
      final penalite = dues.first;
      return 'Pénalité : ${penalite.libelle} (+$total$suffix)';
    }

    return '${dues.length} pénalités dues (+$total$suffix)';
  }

  /// Libellé complet cotisation + pénalités.
  static String? libelleCalculComplet({
    required double? tarifUnitaire,
    required String typeAdhesionLibelle,
    required int nombreDependants,
    Iterable<PenaliteAffilieModel> penalites = const [],
    String? deviseCode,
  }) {
    final parts = <String>[];

    if (tarifUnitaire != null && tarifUnitaire > 0) {
      parts.add(
        libelleCalcul(
          tarifUnitaire: tarifUnitaire,
          typeAdhesionLibelle: typeAdhesionLibelle,
          nombreDependants: nombreDependants,
          deviseCode: deviseCode,
        ),
      );
    }

    final penalitesLabel = libellePenalites(
      penalites: penalites,
      deviseCode: deviseCode,
    );
    if (penalitesLabel != null) {
      parts.add(penalitesLabel);
    }

    if (parts.isEmpty) return null;
    return parts.join('\n');
  }
}
