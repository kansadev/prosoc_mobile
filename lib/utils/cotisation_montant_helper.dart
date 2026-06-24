/// Calcul du montant total d'une cotisation selon le type d'adhésion.
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
}
