import '../config/api.dart';

/// Résolution des URLs de photo (absolues ou relatives à l'API).
class PhotoUrlHelper {
  PhotoUrlHelper._();

  static String? resolve(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    if (trimmed.startsWith('/')) {
      return '${ApiConfig.baseUrl}$trimmed';
    }

    return null;
  }

  /// En-têtes pour les images servies par des endpoints API authentifiés.
  static Map<String, String>? networkHeaders(String resolvedUrl) {
    final token = ApiService.token;
    if (token == null || token.isEmpty) return null;

    final uri = Uri.tryParse(resolvedUrl);
    if (uri != null && uri.path.startsWith('/api/')) {
      return {'Authorization': 'Bearer $token'};
    }
    return null;
  }
}
