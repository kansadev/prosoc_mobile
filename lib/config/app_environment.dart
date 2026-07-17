import 'package:flutter/foundation.dart';

/// Environnements API Prosoc.
enum AppEnvironment {
  dev('https://uat-prosoc.asdc-rdc.org'),
  uat('https://uat-prosoc.asdc-rdc.org');

  const AppEnvironment(this.baseUrl);

  final String baseUrl;

  String get label => name.toUpperCase();
}

/// Résolution de l'environnement actif (compile-time via `--dart-define`).
abstract final class AppEnvironmentConfig {
  static const _dartDefineKey = 'APP_ENV';

  static AppEnvironment get current {
    const raw = String.fromEnvironment(_dartDefineKey, defaultValue: 'dev');
    return AppEnvironment.values.firstWhere(
      (env) => env.name == raw.trim().toLowerCase(),
      orElse: () => AppEnvironment.dev,
    );
  }

  static String get baseUrl => current.baseUrl;

  static String get label => current.label;

  static bool get isDev => current == AppEnvironment.dev;

  static bool get isUat => current == AppEnvironment.uat;

  static void logIfDebug() {
    if (kDebugMode) {
      debugPrint(
        '[Prosoc] API $label → $baseUrl '
        '(changer: --dart-define=$_dartDefineKey=dev|uat)',
      );
    }
  }
}
