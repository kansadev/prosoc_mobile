/// Validation des montants de collecte (paiement total ou fragmenté).
class CollecteMontantHelper {
  CollecteMontantHelper._();

  /// Retourne un message d'erreur ou `null` si le montant est valide.
  static String? validatePartialPayment({
    required double montantRecu,
    double? montantAttendu,
  }) {
    if (montantRecu <= 0) {
      return 'Veuillez entrer un montant valide';
    }
    if (montantAttendu != null &&
        montantAttendu > 0 &&
        montantRecu > montantAttendu + 0.009) {
      return 'Le montant ne peut pas dépasser '
          '${montantAttendu.toStringAsFixed(2)}';
    }
    return null;
  }

  static String montantFieldHint({double? montantAttendu}) {
    if (montantAttendu == null || montantAttendu <= 0) {
      return 'Montant à payer';
    }
    return 'Montant (max. ${montantAttendu.toStringAsFixed(2)})';
  }

  /// [partielAutorise] : cotisation uniquement. Frais et souscriptions restent
  /// soumis au montant exact du tarif.
  static String? montantAttenduLibelle({
    double? montantAttendu,
    bool partielAutorise = false,
  }) {
    if (montantAttendu == null || montantAttendu <= 0) return null;
    final montant = montantAttendu.toStringAsFixed(2);
    return partielAutorise
        ? 'Maximum payable : $montant. Un versement partiel est possible.'
        : 'Montant attendu : $montant';
  }
}
