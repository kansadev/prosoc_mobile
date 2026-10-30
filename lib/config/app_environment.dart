import 'package:flutter/foundation.dart';

/// Environnements API Prosoc.
///
/// L'environnement est choisi au build via `--dart-define=APP_ENV=...`
/// (voir [AppEnvironmentConfig]) ; sans valeur, l'application pointe en dev.
/// Chaque valeur porte son URL de référence ; les URL vides signifient
/// « non déployé » et sont interdites.
enum AppEnvironment {
  dev('https://dev-prosoc.asdc-rdc.org'),
  uat('https://uat-prosoc.asdc-rdc.org'),
  prod('https://prod-prosoc.asdc-rdc.org');

  const AppEnvironment(this.baseUrl);

  final String baseUrl;

  String get label => name.toUpperCase();

  /// Vrai si l'environnement est exploitable (URL configurée).
  bool get isAvailable => baseUrl.trim().isNotEmpty;

  /// Résout un nom (`dev`, `uat`, `prod`, insensible à la casse).
  static AppEnvironment? tryParse(String value) {
    final normalized = value.trim().toLowerCase();
    for (final env in values) {
      if (env.name == normalized) return env;
    }
    return null;
  }
}

/// Environnement actif de l'application.
///
/// Par défaut l'application pointe en **dev** (`flutter run` simple). Pour un
/// build, l'environnement se choisit avec `--dart-define=APP_ENV` :
/// ```
/// flutter run                                   # dev
/// flutter build apk --dart-define=APP_ENV=uat
/// flutter build appbundle --dart-define=APP_ENV=prod
/// flutter build ipa --dart-define=APP_ENV=prod
/// ```
///
/// La valeur peut aussi être changée à chaud (écran de diagnostic, tests) :
/// ```dart
/// AppEnvironmentConfig.select(AppEnvironment.uat);
/// ```
abstract final class AppEnvironmentConfig {
  /// Valeur brute de `--dart-define=APP_ENV` (vide si non fournie).
  static const String _envFromDefine = String.fromEnvironment('APP_ENV');

  /// Environnement retenu au démarrage : `APP_ENV` s'il est valide, sinon dev.
  static AppEnvironment _current =
      AppEnvironment.tryParse(_envFromDefine) ?? AppEnvironment.dev;

  /// Vrai si `APP_ENV` a été fourni mais ne correspond à aucun environnement.
  static bool get hasInvalidDefine =>
      _envFromDefine.isNotEmpty &&
      AppEnvironment.tryParse(_envFromDefine) == null;

  /// Environnement actuellement sélectionné.
  static AppEnvironment get current => _current;

  /// URL de base de l'environnement actif.
  static String get baseUrl => _current.baseUrl;

  /// Libellé affichable (`DEV`, `UAT`, `PROD`).
  static String get label => _current.label;

  static bool get isDev => _current == AppEnvironment.dev;
  static bool get isUat => _current == AppEnvironment.uat;
  static bool get isProd => _current == AppEnvironment.prod;

  /// Sélectionne l'environnement par un `switch` sur l'enum.
  ///
  /// Retourne l'environnement réellement retenu (utile si `prod` n'est pas
  /// encore déployé : on reste alors sur `uat`).
  static AppEnvironment select(AppEnvironment environment) {
    final resolved = switch (environment) {
      AppEnvironment.dev => AppEnvironment.dev,
      AppEnvironment.uat => AppEnvironment.uat,
      AppEnvironment.prod =>
        environment.isAvailable ? AppEnvironment.prod : AppEnvironment.uat,
    };
    _current = resolved;
    return _current;
  }

  /// Raccourcis de sélection.
  static AppEnvironment useDev() => select(AppEnvironment.dev);
  static AppEnvironment useUat() => select(AppEnvironment.uat);

  /// Pointe sur la production ; retombe sur l'UAT si l'URL n'est pas configurée.
  static AppEnvironment useProd() => select(AppEnvironment.prod);

  /// Liste des environnements sélectionnables (pour un écran de diagnostic).
  static List<AppEnvironment> get available => AppEnvironment.values;

  /// Trace l'environnement actif en mode debug.
  static void logIfDebug() {
    if (kDebugMode) {
      debugPrint(
        '[Prosoc] API $label → $baseUrl '
        '(--dart-define=APP_ENV=dev | uat | prod, défaut : dev)',
      );
    }
    if (hasInvalidDefine) {
      debugPrint(
        '[Prosoc] APP_ENV="$_envFromDefine" inconnu : repli sur DEV. '
        'Valeurs acceptées : dev, uat, prod.',
      );
    }
  }
}
