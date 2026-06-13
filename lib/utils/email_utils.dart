/// Validation e-mail (alignée sur les règles ASP.NET / API).
class EmailUtils {
  EmailUtils._();

  static final RegExp _pattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static bool isValid(String? raw) {
    if (raw == null) return false;
    final trimmed = raw.trim();
    return trimmed.isNotEmpty && _pattern.hasMatch(trimmed);
  }

  /// Vide = OK (champ optionnel) ; sinon format valide requis.
  static bool isEmptyOrValid(String? raw) {
    if (raw == null || raw.trim().isEmpty) return true;
    return isValid(raw);
  }

  static String get invalidFormatMessage =>
      'Adresse e-mail invalide. Exemple : nom@domaine.com';
}
