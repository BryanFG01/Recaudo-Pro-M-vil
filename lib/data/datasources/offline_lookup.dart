/// Reglas puras del modo sin conexión: cómo se guarda una respuesta y cómo se responde una
/// petición sin red a partir de lo que ya se descargó.
///
/// - `/api/credits/<id>` sin caché propia → se busca el crédito en las listas ya descargadas.
/// - `/api/collections?credit_id=X` o `/api/payment-attempts/credit/X` → se filtra la lista completa
///   del negocio (`/api/collections?business_id=...`).
library;

/// Recursos que se buscan por id cuando no hay caché exacta (las pantallas los piden uno a uno).
const Set<String> indexedResources = {'clients', 'credits'};

/// Parámetros que delimitan el negocio pero no filtran registros.
const Set<String> _scopeParams = {'business_id', 'business_code'};
const Set<String> _pagingParams = {'limit', 'offset'};

/// Rutas `/api/<recurso>/<campo>/<id>` que equivalen a filtrar por `<campo>_id`.
const Set<String> _filterSegments = {'credit', 'client', 'user'};

final RegExp _uuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

/// Clave estable de una URL (sin host, con los parámetros ordenados).
String cacheKeyOf(Uri url) {
  final params = url.queryParameters.keys.toList()..sort();
  if (params.isEmpty) return url.path;
  return '${url.path}?${params.map((k) => '$k=${url.queryParameters[k]}').join('&')}';
}

/// Qué pide una URL del API, en términos de recurso, id y filtros.
class OfflineRequest {
  final String resource;
  final String? entityId;
  final Map<String, String> filters;

  /// Lista completa del negocio (sin filtros ni límite): sirve para responder consultas filtradas.
  final bool isFullList;

  const OfflineRequest({required this.resource, this.entityId, this.filters = const {}, this.isFullList = false});

  bool get isList => entityId == null;
}

/// `null` si la ruta no se puede derivar de otras (ej. `/api/credits/summary/<id>`): solo caché exacta.
OfflineRequest? parseOfflineRequest(Uri url) {
  final segments = url.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.length < 2 || segments.first != 'api') return null;
  final resource = segments[1];
  final rest = segments.sublist(2);
  final query = url.queryParameters;
  final filters = {
    for (final e in query.entries)
      if (!_scopeParams.contains(e.key) && !_pagingParams.contains(e.key)) e.key: e.value,
  };
  final isPaged = query.containsKey('limit');

  if (rest.isEmpty || (rest.length == 2 && rest.first == 'business')) {
    return OfflineRequest(resource: resource, filters: filters, isFullList: filters.isEmpty && !isPaged);
  }
  if (rest.length == 1 && _uuid.hasMatch(rest.first)) {
    return OfflineRequest(resource: resource, entityId: rest.first);
  }
  if (rest.length == 2 && _filterSegments.contains(rest.first)) {
    return OfflineRequest(resource: resource, filters: {...filters, '${rest.first}_id': rest[1]});
  }
  return null;
}

/// True si el registro cumple todos los filtros (`credit_id`, `status`, ...).
bool matchesFilters(Map<String, dynamic> item, Map<String, String> filters) =>
    filters.entries.every((f) => item[f.key]?.toString() == f.value);

/// Registros de [items] que cumplen [filters].
List<Map<String, dynamic>> filterItems(Iterable<Map<String, dynamic>> items, Map<String, String> filters) =>
    items.where((item) => matchesFilters(item, filters)).toList();

/// Agrega al inicio de una lista los registros pendientes de envío que le corresponden y que el
/// servidor todavía no tiene (por id).
List<Map<String, dynamic>> withPendingItems(
  List<Map<String, dynamic>> items,
  Iterable<Map<String, dynamic>> pending,
  Map<String, String> filters,
) {
  final known = items.map((i) => i['id']?.toString()).toSet();
  final extra = pending.where((p) => !known.contains(p['id']?.toString()) && matchesFilters(p, filters));
  return [...extra, ...items];
}
