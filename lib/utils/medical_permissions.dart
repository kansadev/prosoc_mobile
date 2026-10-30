import '../services/auth_service.dart';

/// Droits du circuit « Prestations médicales », lus dans les permissions de la
/// session. Le serveur reste juge (périmètre affilié / hôpital) : ces getters
/// servent uniquement à masquer les actions non autorisées.
///
/// La visibilité dépend **uniquement des permissions**, jamais du build.
abstract final class MedicalPermissions {
  static const readSouscription = 'READ_SOUSCRIPTION_PRESTATION';
  static const createCollecte = 'CREATE_COLLECTE';
  static const createDemande = 'CREATE_DEMANDE_BON_ENVOI';
  static const readDemande = 'READ_DEMANDE_BON_ENVOI';
  static const confirmDemande = 'CONFIRM_DEMANDE_BON_ENVOI';
  static const scanBon = 'SCAN_BON_ENVOI';
  static const useJeton = 'USE_JETON_MEDICAL';
  static const createProduitMutuel = 'CREATE_PRODUIT_MUTUEL';
  static const createProduitAssureur = 'CREATE_PRODUIT_ASSUREUR';
  static const updateProduitMutuel = 'UPDATE_PRODUIT_MUTUEL';
  static const updateProduitAssureur = 'UPDATE_PRODUIT_ASSUREUR';

  static bool _has(String permission) =>
      AuthService.currentUser?.hasPermission(permission) ?? false;

  static bool get estMembre =>
      AuthService.currentUser?.isAdherentOrAffilie ?? false;

  static bool get peutConsulterSouscriptions =>
      (_has(readSouscription) || _has(createCollecte));

  /// Membre (son dossier) ou personnel `CREATE_COLLECTE`.
  static bool get peutSouscrire =>
      (_has(createCollecte) || (estMembre && _has(readSouscription)));

  /// Encaissement synchrone : jamais un membre.
  static bool get peutEncaisserGuichet =>
      !estMembre && _has(createCollecte);

  static bool get peutPayerElectronique =>
      (_has(createCollecte) || (estMembre && _has(readSouscription)));

  static bool get peutDemanderPriseEnCharge => _has(createDemande);

  static bool get peutConsulterPrisesEnCharge =>
      (_has(readDemande) || _has(createDemande));

  static bool get peutConfirmerPriseEnCharge =>
      !estMembre && _has(confirmDemande);

  static bool get peutScanner => !estMembre && _has(scanBon);

  static bool get peutConsommer => !estMembre && _has(useJeton);

  static bool get peutCreerProduit =>
      (_has(createProduitMutuel) || _has(createProduitAssureur));

  static bool get peutModifierProduit =>
      (_has(updateProduitMutuel) || _has(updateProduitAssureur));

  static bool get peutAdministrerCatalogue =>
      peutCreerProduit || peutModifierProduit;
}
