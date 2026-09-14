/// Feature flags UI Prosoc (publication store / modules optionnels).
///
/// Exemple pour réactiver la santé en build interne :
/// `flutter run --dart-define=HEALTH_UI_ENABLED=true`
abstract final class AppFeatures {
  /// Affiche les modules liés à la santé / mutuelle soins :
  /// bons d'envoi, jetons médicaux, antécédents, souscriptions prestations,
  /// validation médicale, copy onboarding soins, couverture MAASH UI.
  ///
  /// Désactivé par défaut pour la publication sur compte développeur personnel
  /// (Google Play / App Store). Le code métier reste en place ; seuls les
  /// points d'entrée UI sont masqués.
  static const bool healthUiEnabled = bool.fromEnvironment(
    'HEALTH_UI_ENABLED',
    defaultValue: false,
  );
}
