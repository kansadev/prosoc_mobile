import '../config/api.dart';
import '../models/devise_model.dart';

/// Devise résolue pour les modules wallet / rechargement.
///
/// L'API renvoie la liste des devises (`/api/Devise`) avec le drapeau
/// `estDevisePrincipale` : c'est cette devise configurée côté métier qui doit
/// servir de référence pour les montants (demande de rechargement, crédit
/// wallet), afin d'éviter l'affichage systématique en CDF alors que le
/// portefeuille est crédité en dollars.
class ResolvedDevise {
  final int deviseId;
  final String deviseCode;
  final String deviseSymbole;

  const ResolvedDevise({
    required this.deviseId,
    required this.deviseCode,
    this.deviseSymbole = '',
  });
}

/// Résout la devise principale configurée, avec repli USD si les devises ne
/// sont pas joignables (devise principale de l'environnement de référence).
abstract final class DevisePrincipaleResolver {
  static const ResolvedDevise usdFallback = ResolvedDevise(
    deviseId: 2,
    deviseCode: 'USD',
    deviseSymbole: r'$',
  );

  static Future<ResolvedDevise> resolve() async {
    try {
      final response = await ApiService.getDevises();
      if (response.success && response.data != null) {
        final devises = response.data!
            .whereType<Map>()
            .map((e) => Devise.fromJson(Map<String, dynamic>.from(e)))
            .where((d) => d.statut && d.idDevise > 0 && d.code.isNotEmpty)
            .toList();

        if (devises.isNotEmpty) {
          final principale = devises
              .where((d) => d.estDevisePrincipale)
              .firstOrNull;
          final devise = principale ?? devises.first;
          return ResolvedDevise(
            deviseId: devise.idDevise,
            deviseCode: devise.code,
            deviseSymbole: devise.symbole ?? '',
          );
        }
      }
    } catch (_) {
      // Repli silencieux sur la devise principale de référence.
    }
    return usdFallback;
  }
}
