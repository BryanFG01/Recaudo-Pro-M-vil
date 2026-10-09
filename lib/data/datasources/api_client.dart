import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import 'session_local_datasource.dart';

/// Error de red con un mensaje listo para mostrar al usuario.
class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);

  @override
  String toString() => message;
}

/// Único cliente HTTP de la app (ningún otro archivo usa `package:http` para el API).
///
/// - Adjunta `Authorization: Bearer <access token>` a cada petición.
/// - Si el backend responde 401, renueva la sesión con el refresh token UNA sola vez aunque
///   fallen varias peticiones a la vez (el backend rota el token y reutilizar uno viejo
///   cerraría la sesión) y reintenta la petición.
/// - Si la sesión ya no se puede renovar, borra los tokens y avisa por [sessionEnded].
/// - Toda petición tiene timeout y los errores de red se traducen a [NetworkException].
class ApiClient {
  static const Duration defaultTimeout = Duration(seconds: 20);

  /// Instancia compartida por los datasources.
  static final ApiClient instance = ApiClient(SessionLocalDataSource());

  final SessionLocalDataSource _session;
  final http.Client _http;
  final Duration _timeout;
  final _sessionEnded = StreamController<void>.broadcast();
  Future<bool>? _pendingRefresh;

  ApiClient(this._session, {http.Client? client, Duration timeout = defaultTimeout})
      : _http = client ?? http.Client(),
        _timeout = timeout;

  /// Emite cuando la sesión terminó (vencida, revocada o cerrada en otro dispositivo).
  Stream<void> get sessionEnded => _sessionEnded.stream;

  Future<http.Response> get(Uri url) => send(() => http.Request('GET', url));

  Future<http.Response> delete(Uri url) => send(() => http.Request('DELETE', url));

  Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body}) =>
      send(() => _withBody('POST', url, headers, body));

  Future<http.Response> patch(Uri url, {Map<String, String>? headers, Object? body}) =>
      send(() => _withBody('PATCH', url, headers, body));

  /// Envía una petición autenticada. [build] crea la petición de nuevo si hay que reintentarla
  /// tras renovar la sesión (un `MultipartRequest` no se puede enviar dos veces).
  Future<http.Response> send(http.BaseRequest Function() build) async {
    final response = await _sendWithToken(build(), await _session.readAccessToken());
    if (response.statusCode != HttpStatus.unauthorized) return response;
    if (await _session.readRefreshToken() == null) return response;

    if (!await _refreshOnce()) {
      await _endSession();
      return response;
    }
    final retried = await _sendWithToken(build(), await _session.readAccessToken());
    if (retried.statusCode == HttpStatus.unauthorized) await _endSession();
    return retried;
  }

  /// Login de la app (sin token): guarda la sesión y devuelve el cuerpo { user, token, ... }.
  Future<Map<String, dynamic>?> login(String number, String password) async {
    final url = Uri.parse(ApiConfig.buildApiUrl('/api/users/number/${Uri.encodeComponent(number)}'));
    final response = await _sendWithToken(_withBody('POST', url, null, jsonEncode({'password': password})), null);
    if (response.statusCode == HttpStatus.tooManyRequests) {
      throw const NetworkException('Demasiados intentos. Espera un minuto e inténtalo de nuevo.');
    }
    if (response.statusCode != HttpStatus.ok) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final tokens = SessionTokens.fromJson(body);
    if (tokens == null) return null;
    await _session.saveTokens(tokens);
    return body;
  }

  /// Cierra la sesión en el backend (revoca el refresh token) y borra los tokens locales.
  Future<void> logout() async {
    final refresh = await _session.readRefreshToken();
    await _session.clearTokens();
    if (refresh == null) return;
    try {
      final url = Uri.parse(ApiConfig.buildApiUrl('/api/auth/logout'));
      await _sendWithToken(_withBody('POST', url, null, jsonEncode({'refresh_token': refresh})), null);
    } on NetworkException {
      // Sin conexión: la sesión local ya se borró; en el backend vence sola.
    }
  }

  Future<bool> _refreshOnce() => _pendingRefresh ??= _refresh().whenComplete(() => _pendingRefresh = null);

  Future<bool> _refresh() async {
    final refresh = await _session.readRefreshToken();
    if (refresh == null) return false;
    final url = Uri.parse(ApiConfig.buildApiUrl('/api/auth/refresh'));
    final response = await _sendWithToken(_withBody('POST', url, null, jsonEncode({'refresh_token': refresh})), null);
    if (response.statusCode != HttpStatus.ok) return false;
    final tokens = SessionTokens.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    if (tokens == null) return false;
    await _session.saveTokens(tokens);
    return true;
  }

  Future<void> _endSession() async {
    await _session.clearTokens();
    _sessionEnded.add(null);
  }

  Future<http.Response> _sendWithToken(http.BaseRequest request, String? accessToken) async {
    if (accessToken != null) request.headers['Authorization'] = 'Bearer $accessToken';
    try {
      final streamed = await _http.send(request).timeout(_timeout);
      return await http.Response.fromStream(streamed).timeout(_timeout);
    } on TimeoutException {
      throw const NetworkException('El servidor tardó demasiado en responder. Inténtalo de nuevo.');
    } on SocketException {
      throw const NetworkException('Sin conexión a internet. Revisa tu red e inténtalo de nuevo.');
    } on http.ClientException {
      throw const NetworkException('No se pudo conectar con el servidor.');
    }
  }

  static http.Request _withBody(String method, Uri url, Map<String, String>? headers, Object? body) {
    final request = http.Request(method, url);
    request.headers['Content-Type'] = 'application/json';
    if (headers != null) request.headers.addAll(headers);
    if (body is String) {
      request.body = body;
    } else if (body != null) {
      request.body = jsonEncode(body);
    }
    return request;
  }
}
