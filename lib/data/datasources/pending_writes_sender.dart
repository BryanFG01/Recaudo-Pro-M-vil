import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import 'api_client.dart';
import 'offline_store.dart';

/// Resultado de un alta: enviada (con la respuesta del backend) o guardada en la cola.
class WriteResult {
  final http.Response? response;

  /// Lo que se envió (o se enviará desde la cola).
  final Map<String, dynamic> body;

  const WriteResult.sent(http.Response this.response, this.body);
  const WriteResult.queued(this.body) : response = null;

  bool get isQueued => response == null;
}

/// Resultado de vaciar la cola.
class FlushReport {
  final int sent;
  final int rejected;
  const FlushReport({this.sent = 0, this.rejected = 0});
}

/// Envía las altas del cobrador (cobros e intentos de pago) y, sin conexión, las guarda en la cola
/// para reenviarlas en el mismo orden. El body lleva el `id` del registro, así reenviar nunca duplica.
class PendingWritesSender {
  PendingWritesSender(this._api, this._store);

  static final PendingWritesSender instance = PendingWritesSender(ApiClient.instance, OfflineStore.instance);

  /// Errores del servidor o del proxy: se reintenta más tarde.
  static const Set<int> _retryLater = {HttpStatus.tooManyRequests, 500, 502, 503, 504};

  final ApiClient _api;
  final OfflineStore _store;
  Future<FlushReport>? _flushing;

  /// Envía el alta o, si no hay conexión, la guarda en la cola. Si ya hay pendientes del usuario,
  /// va a la cola detrás de ellos (un "pagó" no puede llegar antes que su cobro).
  /// [queuedFields] solo se agregan si el alta queda en cola (ej. la hora real del cobro).
  Future<WriteResult> submit({
    required String path,
    required Map<String, dynamic> body,
    required String userId,
    Map<String, dynamic> queuedFields = const {},
  }) async {
    if ((await _store.pending(userId: userId)).any((w) => !w.isRejected)) {
      final queued = await _enqueue(path, {...body, ...queuedFields}, userId);
      unawaited(flush(userId));
      return queued;
    }
    try {
      final response = await _api.post(Uri.parse(ApiConfig.buildApiUrl(path)), body: jsonEncode(body));
      if (!_retryLater.contains(response.statusCode)) return WriteResult.sent(response, body);
    } on NetworkException {
      // sin conexión: a la cola
    }
    return _enqueue(path, {...body, ...queuedFields}, userId);
  }

  Future<WriteResult> _enqueue(String path, Map<String, dynamic> body, String userId) async {
    await _store.enqueue(
        PendingWrite(id: body['id'] as String, path: path, body: body, userId: userId, createdAt: DateTime.now()));
    return WriteResult.queued(body);
  }

  /// Cancela un alta que sigue en la cola (y lo que depende de ella). False si ya se había enviado.
  Future<bool> cancel(String id) => _store.discard(id);

  /// Reenvía la cola del usuario en orden. Se detiene al primer error de red (sigue sin conexión);
  /// lo que el backend rechaza (4xx) queda marcado con el motivo y no se reintenta.
  Future<FlushReport> flush(String userId) => _flushing ??= _flush(userId).whenComplete(() => _flushing = null);

  Future<FlushReport> _flush(String userId) async {
    var sent = 0;
    var rejected = 0;
    for (final write in await _store.pending(userId: userId)) {
      if (write.isRejected) continue;
      final http.Response response;
      try {
        response = await _post(write);
      } on NetworkException {
        break;
      }
      final status = response.statusCode;
      if (status == HttpStatus.ok || status == HttpStatus.created) {
        await _store.remove(write.id);
        sent++;
      } else if (status == HttpStatus.unauthorized || _retryLater.contains(status)) {
        break; // sesión terminada o servidor con problemas: se reintenta después
      } else {
        await _store.reject(write.id, errorMessage(response));
        rejected++;
      }
    }
    return FlushReport(sent: sent, rejected: rejected);
  }

  Future<http.Response> _post(PendingWrite write) =>
      _api.post(Uri.parse(ApiConfig.buildApiUrl(write.path)), body: jsonEncode(write.body));

  /// Mensaje del backend (`message`), o el código si no viene.
  static String errorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        final message = body['message'];
        if (message is List && message.isNotEmpty) return message.join('. ');
        if (message != null) return message.toString();
      }
    } on FormatException {
      // cuerpo no JSON
    }
    return 'Error ${response.statusCode}';
  }
}
