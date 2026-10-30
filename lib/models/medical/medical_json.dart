/// Lecture défensive des réponses du module médical (camelCase, objets
/// directs sans enveloppe `data`). Les montants sont lus via `num` : les
/// exemples serveur contiennent des entiers.
abstract final class MedicalJson {
  static int asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? asIntOrNull(dynamic value) {
    if (value == null) return null;
    final parsed = asInt(value);
    return parsed == 0 && value.toString().trim() != '0' ? null : parsed;
  }

  static double asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool asBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  static String? asStringOrNull(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String asString(dynamic value) => asStringOrNull(value) ?? '';

  /// Dates ISO 8601 UTC conservées telles quelles (bornes serveur).
  static DateTime? asDateOrNull(dynamic value) {
    final text = asStringOrNull(value);
    if (text == null) return null;
    return DateTime.tryParse(text);
  }

  static Map<String, dynamic> asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static List<Map<String, dynamic>> asMapList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }
}
