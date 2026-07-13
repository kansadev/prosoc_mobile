import 'package:flutter/material.dart';

import '../models/arriere_affilie_model.dart';
import '../views/screens/adhérent/widgets/payer_contributionScreen.dart';
import '../views/screens/adhérent/widgets/payer_frais_screen.dart';
import '../views/screens/adhérent/widgets/payer_souscription_screen.dart';

/// Redirige vers l'écran de paiement adapté au type d'obligation d'un arriéré.
class ArrierePaymentNavigator {
  ArrierePaymentNavigator._();

  static Future<bool?> openPayment({
    required BuildContext context,
    required ArriereAffilieModel arriere,
    required int affilieId,
    String affilieNom = '',
    String affiliePrenom = '',
    String? affilieTelephone,
    int? agentId,
    int nombreDependants = 0,
    bool allowVirtualAccount = false,
  }) {
    if (!arriere.estImpaye) return Future.value(null);

    final montant = arriere.restAPayer > 0
        ? arriere.restAPayer
        : arriere.montantAttendu;

    switch (arriere.typeObligation.toUpperCase()) {
      case 'FRAIS':
        return Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => PayerFraisScreen(
              affilieId: affilieId,
              affilieNom: affilieNom,
              affiliePrenom: affiliePrenom,
              affilieTelephone: affilieTelephone,
              agentId: agentId,
              initialFraisId: arriere.fraisId,
              initialMontant: montant,
              screenTitle: 'Payer un frais',
              allowVirtualAccount: allowVirtualAccount,
            ),
          ),
        );
      case 'COTISATION':
        final tarifId = arriere.cotisationAffilieId ??
            arriere.tarifCotisation?.idCotisationAffilie;
        return Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => PayerContributionScreen(
              affilieId: affilieId,
              affilieNom: affilieNom,
              affiliePrenom: affiliePrenom,
              affilieTelephone: affilieTelephone,
              agentId: agentId,
              nombreDependants: nombreDependants,
              initialTarifId: tarifId,
              initialArrieresAffilieId: arriere.idArrieresAffilie,
              initialMontant: montant,
              screenTitle: 'Payer une cotisation',
              allowVirtualAccount: allowVirtualAccount,
            ),
          ),
        );
      case 'SOUSCRIPTION':
        return Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => PayerSouscriptionScreen(
              affilieId: affilieId,
              affilieNom: affilieNom,
              affiliePrenom: affiliePrenom,
              affilieTelephone: affilieTelephone,
              agentId: agentId,
              initialSouscriptionPrestationId: arriere.souscriptionPrestationId,
              initialMontant: montant,
              screenTitle: 'Payer une souscription',
              allowVirtualAccount: allowVirtualAccount,
            ),
          ),
        );
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Paiement non disponible pour le type « ${arriere.typeObligationLabel} ».',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return Future.value(null);
    }
  }
}
