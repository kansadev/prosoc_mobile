/// Extraction robuste des listes paginées renvoyées par l'API Prosoc.
class PaginatedResponseHelper {
  PaginatedResponseHelper._();

  static List<dynamic> extractRows(dynamic payload) {
    if (payload is List) return payload;
    if (payload is! Map) return const [];

    final map = payload is Map<String, dynamic>
        ? payload
        : Map<String, dynamic>.from(payload);

    final direct = map['data'] ?? map['Data'] ?? map['items'] ?? map['Items'];
    if (direct is List) return direct;

    final pagination = map['pagination'] ?? map['Pagination'];
    if (pagination is Map) {
      final nested = pagination['data'] ??
          pagination['Data'] ??
          pagination['items'] ??
          pagination['Items'];
      if (nested is List) return nested;
    }

    return const [];
  }

  static int extractTotalItems(dynamic payload, {int fallback = 0}) {
    if (payload is! Map) return fallback;

    final map = payload is Map<String, dynamic>
        ? payload
        : Map<String, dynamic>.from(payload);

    final top = map['totalItems'] ?? map['TotalItems'];
    final fromTop = _asInt(top);
    if (fromTop != null) return fromTop;

    final pagination = map['pagination'] ?? map['Pagination'];
    if (pagination is Map) {
      final nested = pagination['totalItems'] ?? pagination['TotalItems'];
      final fromPagination = _asInt(nested);
      if (fromPagination != null) return fromPagination;
    }

    final rows = extractRows(map);
    return rows.isNotEmpty ? rows.length : fallback;
  }

  static int extractTotalPages(dynamic payload, {int fallback = 1}) {
    if (payload is! Map) return fallback;

    final map = payload is Map<String, dynamic>
        ? payload
        : Map<String, dynamic>.from(payload);

    final top = map['totalPages'] ?? map['TotalPages'];
    final fromTop = _asInt(top);
    if (fromTop != null && fromTop > 0) return fromTop;

    final pagination = map['pagination'] ?? map['Pagination'];
    if (pagination is Map) {
      final nested =
          pagination['totalPages'] ?? pagination['TotalPages'];
      final fromPagination = _asInt(nested);
      if (fromPagination != null && fromPagination > 0) {
        return fromPagination;
      }
    }

    return fallback;
  }

  static bool extractHasNext(dynamic payload) {
    if (payload is! Map) return false;

    final map = payload is Map<String, dynamic>
        ? payload
        : Map<String, dynamic>.from(payload);

    final top = map['hasNext'] ??
        map['HasNext'] ??
        map['hasNextPage'] ??
        map['HasNextPage'];
    if (top == true) return true;
    if (top == false) return false;

    final pagination = map['pagination'] ?? map['Pagination'];
    if (pagination is Map) {
      final nested = pagination['hasNext'] ??
          pagination['HasNext'] ??
          pagination['hasNextPage'] ??
          pagination['HasNextPage'];
      if (nested == true) return true;
      if (nested == false) return false;
    }

    return false;
  }

  static int extractCurrentPage(dynamic payload, {int fallback = 1}) {
    if (payload is! Map) return fallback;

    final map = payload is Map<String, dynamic>
        ? payload
        : Map<String, dynamic>.from(payload);

    final top = map['currentPage'] ??
        map['CurrentPage'] ??
        map['pageNumber'] ??
        map['PageNumber'] ??
        map['page'] ??
        map['Page'];
    final fromTop = _asInt(top);
    if (fromTop != null && fromTop > 0) return fromTop;

    final pagination = map['pagination'] ?? map['Pagination'];
    if (pagination is Map) {
      final nested = pagination['currentPage'] ??
          pagination['CurrentPage'] ??
          pagination['pageNumber'] ??
          pagination['PageNumber'];
      final fromPagination = _asInt(nested);
      if (fromPagination != null && fromPagination > 0) {
        return fromPagination;
      }
    }

    return fallback;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
