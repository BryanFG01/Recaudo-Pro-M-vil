import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:RecaudoPro/data/datasources/api_client.dart';
import 'package:RecaudoPro/data/datasources/session_local_datasource.dart';

/// Sesión en memoria (en lugar del almacenamiento cifrado del dispositivo).
class FakeSession extends SessionLocalDataSource {
  String? access;
  String? refresh;

  FakeSession({this.access, this.refresh});

  @override
  Future<String?> readAccessToken() async => access;

  @override
  Future<String?> readRefreshToken() async => refresh;

  @override
  Future<void> saveTokens(SessionTokens tokens) async {
    access = tokens.accessToken;
    refresh = tokens.refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    access = null;
    refresh = null;
  }
}

http.Response json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

final dataUrl = Uri.parse('https://api.test/api/clients');

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: 'BASE_BACK=https://api.test'));

  test('adjunta el access token como Bearer', () async {
    String? authorization;
    final api = ApiClient(FakeSession(access: 'A1', refresh: 'R1'), client: MockClient((req) async {
      authorization = req.headers['Authorization'];
      return json([]);
    }));

    await api.get(dataUrl);
    expect(authorization, 'Bearer A1');
  });

  test('ante un 401 renueva la sesión, guarda los tokens nuevos y reintenta', () async {
    final session = FakeSession(access: 'viejo', refresh: 'R1');
    final api = ApiClient(session, client: MockClient((req) async {
      if (req.url.path == '/api/auth/refresh') {
        expect(jsonDecode(req.body), {'refresh_token': 'R1'});
        return json({'token': 'nuevo', 'refresh_token': 'R2', 'expires_in': 900});
      }
      return req.headers['Authorization'] == 'Bearer nuevo' ? json(['ok']) : json({'message': 'Unauthorized'}, 401);
    }));

    final response = await api.get(dataUrl);
    expect(response.statusCode, 200);
    expect(session.access, 'nuevo');
    expect(session.refresh, 'R2');
  });

  test('varias peticiones con 401 a la vez comparten UNA sola renovación', () async {
    var refreshCalls = 0;
    final api = ApiClient(FakeSession(access: 'viejo', refresh: 'R1'), client: MockClient((req) async {
      if (req.url.path == '/api/auth/refresh') {
        refreshCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return json({'token': 'nuevo', 'refresh_token': 'R2', 'expires_in': 900});
      }
      return req.headers['Authorization'] == 'Bearer nuevo' ? json([]) : json({}, 401);
    }));

    final responses = await Future.wait(List.generate(5, (_) => api.get(dataUrl)));
    expect(responses.map((r) => r.statusCode), everyElement(200));
    expect(refreshCalls, 1);
  });

  test('si la renovación falla, borra la sesión y avisa que terminó', () async {
    final session = FakeSession(access: 'viejo', refresh: 'revocado');
    final api = ApiClient(session, client: MockClient((req) async => json({'message': 'Sesión inválida'}, 401)));
    final ended = expectLater(api.sessionEnded, emits(null));

    final response = await api.get(dataUrl);
    expect(response.statusCode, 401);
    expect(session.access, isNull);
    expect(session.refresh, isNull);
    await ended;
  });

  test('sin sesión no intenta renovar (ej. pantallas públicas)', () async {
    var refreshCalls = 0;
    final api = ApiClient(FakeSession(), client: MockClient((req) async {
      if (req.url.path == '/api/auth/refresh') refreshCalls++;
      return json({}, 401);
    }));

    await api.get(dataUrl);
    expect(refreshCalls, 0);
  });

  test('login guarda los tokens; logout los borra y revoca la sesión en el backend', () async {
    final session = FakeSession();
    Map<String, dynamic>? logoutBody;
    final api = ApiClient(session, client: MockClient((req) async {
      if (req.url.path == '/api/auth/logout') {
        logoutBody = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response('', 204);
      }
      return json({'user': {'id': 'u1'}, 'token': 'A1', 'refresh_token': 'R1', 'expires_in': 900});
    }));

    final body = await api.login('COB001', 'clave');
    expect(body?['user'], {'id': 'u1'});
    expect(session.refresh, 'R1');

    await api.logout();
    expect(session.access, isNull);
    expect(logoutBody, {'refresh_token': 'R1'});
  });

  test('login con credenciales inválidas devuelve null y no guarda sesión', () async {
    final session = FakeSession();
    final api = ApiClient(session, client: MockClient((req) async => json({'message': 'Credenciales inválidas'}, 401)));

    expect(await api.login('COB001', 'mala'), isNull);
    expect(session.refresh, isNull);
  });

  test('un servidor que no responde da un error de red legible', () async {
    final api = ApiClient(
      FakeSession(),
      timeout: const Duration(milliseconds: 50),
      client: MockClient((req) => Completer<http.Response>().future),
    );

    await expectLater(api.get(dataUrl), throwsA(isA<NetworkException>()));
  });
}
