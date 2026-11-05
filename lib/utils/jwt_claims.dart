import 'dart:convert';

/// Lecture (sans vérification de signature) des claims d'un JWT.
/// Sert uniquement à adapter l'interface : le serveur reste juge des droits.
abstract final class JwtClaims {
  /// Payload décodé, ou `{}` si le jeton est absent ou mal formé.
  static Map<String, dynamic> payload(String? token) {
    if (token == null) return const {};
    final parts = token.split('.');
    if (parts.length < 2) return const {};
    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  /// Valeurs d'un claim pouvant être unique (chaîne) ou multiple (tableau),
  /// comme les claims `permission` émis par l'API.
  static List<String> values(String? token, String claim) {
    final raw = payload(token)[claim];
    final list = raw is List ? raw : (raw == null ? const [] : [raw]);
    return list
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
