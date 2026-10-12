import 'dart:async';
import 'dart:convert';

import 'local_file_store.dart';
import 'offline_lookup.dart';

/// Alta hecha sin conexión, pendiente de enviar al backend (cobro o "no pagó").
class PendingWrite {
  /// Id del registro: el mismo que va en [body], así el backend no lo duplica si se reenvía.
  final String id;
  final String path;
  final Map<String, dynamic> body;
  final String userId;
  final DateTime createdAt;

  /// Motivo si el backend lo rechazó (ej. el crédito ya no existe). Estos no se reintentan.
  final String? error;

  const PendingWrite({
    required this.id,
    required this.path,
    required this.body,
    required this.userId,
    required this.createdAt,
    this.error,
  });

  String get resource => path.split('/').where((s) => s.isNotEmpty).elementAt(1);
  bool get isRejected => error != null;

  PendingWrite rejected(String message) =>
      PendingWrite(id: id, path: path, body: body, userId: userId, createdAt: createdAt, error: message);

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'body': body,
        'user_id': userId,
        'created_at': createdAt.toIso8601String(),
        if (error != null) 'error': error,
      };

  factory PendingWrite.fromJson(Map<String, dynamic> json) => PendingWrite(
        id: json['id'] as String,
        path: json['path'] as String,
        body: Map<String, dynamic>.from(json['body'] as Map),
        userId: json['user_id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        error: json['error'] as String?,
      );
}

/// Datos para trabajar sin conexión:
/// - **Caché de lecturas:** la última respuesta de cada consulta, más listas completas e índices por
///   id para responder consultas que nunca se hicieron con red (ver `offline_lookup.dart`).
/// - **Cola de envío:** altas hechas sin red, en orden. Sobrevive al cierre de sesión: son cobros
///   reales que no se pueden perder.
class OfflineStore {
  OfflineStore(this._files);

  static final OfflineStore instance = OfflineStore(AppSupportFileStore());

  static const String _outboxFile = 'outbox.json';

  final LocalFileStore _files;
  final _changes = StreamController<void>.broadcast();
  List<PendingWrite>? _outbox;
  Future<void> _writes = Future.value();

  /// Emite cada vez que cambia la cola de envío.
  Stream<void> get changes => _changes.stream;

  // ─── Caché de lecturas ───────────────────────────────────────────────────

  Future<void> remember(Uri url, String body) => _serial(() async {
        final key = cacheKeyOf(url);
        await _files.write(_cacheName(key), jsonEncode({'key': key, 'body': body}));

        final request = parseOfflineRequest(url);
        if (request == null) return;
        final decoded = _tryDecode(body);
        if (request.isList && decoded is List) {
          if (request.isFullList) await _files.write(_listName(request.resource), body);
          if (indexedResources.contains(request.resource)) await _index(request.resource, _maps(decoded));
        } else if (decoded is Map && indexedResources.contains(request.resource)) {
          await _index(request.resource, [Map<String, dynamic>.from(decoded)]);
        }
      });

  /// Respuesta guardada para [url], o derivada de las listas guardadas; null si no hay datos.
  Future<String?> recall(Uri url) async {
    final key = cacheKeyOf(url);
    final cached = _tryDecode(await _files.read(_cacheName(key)));
    if (cached is Map && cached['key'] == key) return cached['body'] as String;

    final request = parseOfflineRequest(url);
    if (request == null) return null;
    if (!request.isList) {
      final item = (await _readIndex(request.resource))[request.entityId];
      return item == null ? null : jsonEncode(item);
    }
    final full = _tryDecode(await _files.read(_listName(request.resource)));
    return full is List ? jsonEncode(filterItems(_maps(full), request.filters)) : null;
  }

  /// Agrega a una lista los registros que siguen en la cola (ej. el cobro hecho sin red aparece
  /// en el historial del crédito y en el recaudo del día).
  Future<String> withPending(Uri url, String body) async {
    final request = parseOfflineRequest(url);
    if (request == null || !request.isList) return body;
    final pending = (await _loadOutbox())
        .where((w) => w.resource == request.resource && !w.isRejected)
        .map((w) => w.body)
        .toList();
    if (pending.isEmpty) return body;
    final decoded = _tryDecode(body);
    if (decoded is! List) return body;
    return jsonEncode(withPendingItems(_maps(decoded), pending, request.filters));
  }

  /// Borra lo descargado (al cerrar sesión). La cola de envío se conserva.
  Future<void> clearCache() => _serial(() => _files.deleteAll(keep: {_outboxFile}));

  // ─── Cola de envío ───────────────────────────────────────────────────────

  Future<List<PendingWrite>> pending({String? userId}) async =>
      (await _loadOutbox()).where((w) => userId == null || w.userId == userId).toList();

  Future<void> enqueue(PendingWrite write) => _updateOutbox((list) => [...list.where((w) => w.id != write.id), write]);

  Future<void> remove(String id) => _updateOutbox((list) => list.where((w) => w.id != id).toList());

  Future<void> reject(String id, String message) =>
      _updateOutbox((list) => [for (final w in list) w.id == id ? w.rejected(message) : w]);

  /// Quita un registro de la cola y los que dependen de él (el "pagó" ligado a un cobro).
  /// Devuelve false si no estaba en la cola.
  Future<bool> discard(String id) async {
    var found = false;
    await _updateOutbox((list) {
      found = list.any((w) => w.id == id);
      return list.where((w) => w.id != id && !w.body.values.contains(id)).toList();
    });
    return found;
  }

  // ─── Internos ────────────────────────────────────────────────────────────

  Future<List<PendingWrite>> _loadOutbox() async {
    if (_outbox != null) return _outbox!;
    final decoded = _tryDecode(await _files.read(_outboxFile));
    return _outbox = decoded is List ? _maps(decoded).map(PendingWrite.fromJson).toList() : <PendingWrite>[];
  }

  Future<void> _updateOutbox(List<PendingWrite> Function(List<PendingWrite>) change) async {
    await _serial(() async {
      final updated = change(await _loadOutbox());
      _outbox = updated;
      await _files.write(_outboxFile, jsonEncode(updated.map((w) => w.toJson()).toList()));
    });
    _changes.add(null);
  }

  Future<Map<String, Map<String, dynamic>>> _readIndex(String resource) async {
    final decoded = _tryDecode(await _files.read(_indexName(resource)));
    if (decoded is! Map) return {};
    return {for (final e in decoded.entries) e.key as String: Map<String, dynamic>.from(e.value as Map)};
  }

  Future<void> _index(String resource, List<Map<String, dynamic>> items) async {
    final index = await _readIndex(resource);
    for (final item in items) {
      final id = item['id']?.toString();
      if (id != null) index[id] = item;
    }
    await _files.write(_indexName(resource), jsonEncode(index));
  }

  /// Las escrituras van una tras otra (leer-modificar-escribir sin carreras).
  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _writes.then((_) => action());
    _writes = result.then((_) {}, onError: (_) {});
    return result;
  }

  static List<Map<String, dynamic>> _maps(List<dynamic> list) =>
      list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

  static Object? _tryDecode(String? text) {
    if (text == null) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  static String _cacheName(String key) => 'c_${_hash(key)}.json';
  static String _listName(String resource) => 'l_$resource.json';
  static String _indexName(String resource) => 'i_$resource.json';

  /// FNV-1a de 32 bits; el archivo guarda la clave completa, así una colisión no devuelve otro dato.
  static String _hash(String key) {
    var hash = 0x811c9dc5;
    for (final unit in utf8.encode(key)) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
