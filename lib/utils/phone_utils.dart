/// Normalisation des numéros RDC pour l'API (format attendu : `243` + 9 chiffres).
class PhoneUtils {
  static const int expectedLength = 12;
  static const String countryPrefix = '243';

  /// Extrait uniquement les chiffres.
  static String digitsOnly(String input) =>
      input.replaceAll(RegExp(r'\D'), '');

  /// Convertit une saisie (+243, 0…, espaces) en `243XXXXXXXXX` ou `null` si invalide.
  static String? normalizeDrcPhone(String? raw) {
    if (raw == null) return null;
    var digits = digitsOnly(raw.trim());
    if (digits.isEmpty) return null;

    while (digits.startsWith('00')) {
      digits = digits.substring(2);
    }

    if (digits.startsWith(countryPrefix)) {
      return digits.length == expectedLength ? digits : null;
    }

    if (digits.startsWith('0') && digits.length == 10) {
      digits = '$countryPrefix${digits.substring(1)}';
      return digits.length == expectedLength ? digits : null;
    }

    if (digits.length == 9) {
      digits = '$countryPrefix$digits';
      return digits.length == expectedLength ? digits : null;
    }

    return null;
  }

  static bool isValidDrcPhone(String? raw) => normalizeDrcPhone(raw) != null;

  /// Format API adhésion (ex. Swagger) : `+243999938972`.
  static String? toInternationalFormat(String? raw) {
    final normalized = normalizeDrcPhone(raw);
    if (normalized == null) return null;
    return '+$normalized';
  }

  /// Affichage lisible : +243 987 656 782
  static String formatForDisplay(String? normalized) {
    final n = normalizeDrcPhone(normalized);
    if (n == null || n.length != expectedLength) return normalized?.trim() ?? '';
    final local = n.substring(3);
    return '+243 ${local.substring(0, 3)} ${local.substring(3, 6)} ${local.substring(6)}';
  }

  static const String invalidFormatMessage =
      'Le numéro doit être au format 243XXXXXXXXX (12 chiffres, indicatif RDC). '
      'Ex. : +243 987 656 782 ou 0987656782';

  /// Message utilisateur pour les erreurs API liées au téléphone.
  static String mapApiPhoneError(String? message) {
    if (message == null || message.trim().isEmpty) {
      return 'Numéro de téléphone invalide.';
    }
    final lower = message.toLowerCase();
    if (lower.contains('taille') && lower.contains('téléphone')) {
      return invalidFormatMessage;
    }
    if (lower.contains('telephone') && lower.contains('taille')) {
      return invalidFormatMessage;
    }
    return message.trim();
  }
}
