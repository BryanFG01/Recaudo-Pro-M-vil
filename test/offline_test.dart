import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:recaudo_pro/data/datasources/api_client.dart';
import 'package:recaudo_pro/data/datasources/local_file_store.dart';
import 'package:recaudo_pro/data/datasources/offline_lookup.dart';
import 'package:recaudo_pro/data/datasources/offline_store.dart';
import 'package:recaudo_pro/data/datasources/pending_writes_sender.dart';
import 'package:recaudo_pro/domain/entities/sync_status_entity.dart';
import 'package:recaudo_pro/presentation/widgets/offline_banner.dart';

import 'api_client_test.dart' show FakeSession;

const creditA = '11111111-1111-4111-8111-111111111111';
const creditB = '22222222-2222-4222-8222-222222222222';
const clientA = '33333333-3333-4333-8333-333333333333';
const userId = '44444444-4444-4444-8444-444444444444';

Uri api(String pathAndQuery) => Uri.parse('https://api.test$pathAndQuery');

http.Response jsonResponse(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

/// Servidor falso que puede "perder la señal".
class FakeServer {
  bool online = true;
  final List<http.Request> received = [];
  http.Response Function(http.Request request) handler = (_) => jsonResponse([]);

  MockClient get client => MockClient((request) async {
        if (!online) throw const SocketException('sin red');
        received.add(request);
        return handler(request);
      });
}

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: 'BASE_BACK=https://api.test'));

  group('offline_lookup', () {
    test('la clave no depende del orden de los parámetros', () {
      expect(cacheKeyOf(api('/api/collections?credit_id=1&business_id=2')),
          cacheKeyOf(api('/api/collections?business_id=2&credit_id=1')));
    });

    test('reconoce listas completas, registros por id y filtros por ruta', () {
      final full = parseOfflineRequest(api('/api/collections?business_id=B'))!;
      expect(full.isFullList, isTrue);
      expect(parseOfflineRequest(api('/api/collections?business_id=B&limit=10'))!.isFullList, isFalse);
      expect(parseOfflineRequest(api('/api/credits/$creditA'))!.entityId, creditA);
      expect(parseOfflineRequest(api('/api/payment-attempts/credit/$creditA'))!.filters, {'credit_id': creditA});
      expect(parseOfflineRequest(api('/api/credits/summary/$creditA')), isNull);
    });

    test('los pendientes se agregan una sola vez y solo si cumplen el filtro', () {
      final items = [
        {'id': 'x', 'credit_id': creditA},
      ];
      final pending = [
        {'id': 'x', 'credit_id': creditA}, // ya llegó al servidor
        {'id': 'y', 'credit_id': creditA},
        {'id': 'z', 'credit_id': creditB},
      ];
      final merged = withPendingItems(items, pending, {'credit_id': creditA});
      expect(merged.map((i) => i['id']), ['y', 'x']);
    });
  });

  group('ApiClient sin conexión', () {
    late FakeServer server;
    late OfflineStore store;
    late ApiClient client;

    setUp(() {
      server = FakeServer();
      store = OfflineStore(MemoryFileStore());
      client = ApiClient(FakeSession(access: 'A', refresh: 'R'), offline: store, client: server.client);
    });

    test('responde con lo último descargado y lo marca como guardado', () async {
      server.handler = (_) => jsonResponse([
            {'id': 'c1', 'name': 'Ana Ñuñez'},
          ]);
      await client.get(api('/api/clients/business/B?user_id=U'));

      server.online = false;
      final response = await client.get(api('/api/clients/business/B?user_id=U'));
      expect(response.headers[ApiClient.offlineHeader], '1');
      expect((jsonDecode(response.body) as List).single['name'], 'Ana Ñuñez');
      expect(client.isOnline, isFalse);
    });

    test('un crédito que nunca se abrió con red sale de la lista del negocio', () async {
      server.handler = (_) => jsonResponse([
            {'id': creditA, 'client_id': clientA, 'total_amount': 100000},
          ]);
      await client.get(api('/api/credits?business_id=B'));

      server.online = false;
      final response = await client.get(api('/api/credits/$creditA'));
      expect(jsonDecode(response.body)['total_amount'], 100000);
    });

    test('el historial de un crédito se filtra de la lista completa de recaudos', () async {
      server.handler = (_) => jsonResponse([
            {'id': 'r1', 'credit_id': creditA, 'amount': 5000},
            {'id': 'r2', 'credit_id': creditB, 'amount': 7000},
          ]);
      await client.get(api('/api/collections?business_id=B'));

      server.online = false;
      final response = await client.get(api('/api/collections?business_id=B&credit_id=$creditA'));
      expect((jsonDecode(response.body) as List).map((r) => r['id']), ['r1']);
    });

    test('sin datos guardados el error de red llega a la pantalla', () async {
      server.online = false;
      await expectLater(client.get(api('/api/credits/$creditA')), throwsA(isA<NetworkException>()));
      expect(await client.tryGet(api('/api/credits/summary/$creditA')), isNull);
    });

    test('cerrar sesión borra lo descargado pero no los cobros pendientes', () async {
      await client.get(api('/api/credits?business_id=B'));
      await store.enqueue(PendingWrite(
          id: 'p1', path: '/api/collections', body: {'id': 'p1'}, userId: userId, createdAt: DateTime(2026)));

      await client.logout();
      server.online = false;
      await expectLater(client.get(api('/api/credits?business_id=B')), throwsA(isA<NetworkException>()));
      expect(await store.pending(), hasLength(1));
    });
  });

  group('Cola de envío', () {
    late FakeServer server;
    late OfflineStore store;
    late ApiClient client;
    late PendingWritesSender sender;

    Map<String, dynamic> cobro(String id, {String credit = creditA}) =>
        {'id': id, 'credit_id': credit, 'client_id': clientA, 'amount': 5000, 'user_id': userId};

    setUp(() {
      // Las altas responden 201 con lo recibido; las consultas, una lista vacía
      server = FakeServer()
        ..handler = (request) =>
            request.method == 'GET' ? jsonResponse([]) : jsonResponse(jsonDecode(request.body) as Object, 201);
      store = OfflineStore(MemoryFileStore());
      client = ApiClient(FakeSession(access: 'A', refresh: 'R'), offline: store, client: server.client);
      sender = PendingWritesSender(client, store);
    });

    test('con red se envía al momento, sin la hora del teléfono', () async {
      final result = await sender.submit(
          path: '/api/collections', body: cobro('c1'), userId: userId, queuedFields: {'payment_date': '2026-10-12T13:00:00Z'});
      expect(result.isQueued, isFalse);
      expect(jsonDecode(server.received.single.body).containsKey('payment_date'), isFalse);
    });

    test('sin red queda en cola con la hora del cobro y aparece en el historial', () async {
      await client.get(api('/api/collections?business_id=B')); // historial descargado (vacío)
      server.online = false;

      final result = await sender.submit(
          path: '/api/collections', body: cobro('c1'), userId: userId, queuedFields: {'payment_date': '2026-10-12T13:00:00Z'});
      expect(result.isQueued, isTrue);
      expect(result.body['payment_date'], '2026-10-12T13:00:00Z');

      final history = await client.get(api('/api/collections?business_id=B&credit_id=$creditA'));
      expect((jsonDecode(history.body) as List).single['id'], 'c1');
    });

    test('al volver la red se envía todo en orden y la cola queda vacía', () async {
      server.online = false;
      await sender.submit(path: '/api/collections', body: cobro('c1'), userId: userId);
      await sender.submit(
          path: '/api/payment-attempts',
          body: {'id': 'a1', 'credit_id': creditA, 'status': 'PAID', 'collection_id': 'c1'},
          userId: userId);
      expect(await store.pending(), hasLength(2));

      server.online = true;
      final report = await sender.flush(userId);
      expect(report.sent, 2);
      expect(server.received.map((r) => r.url.path), ['/api/collections', '/api/payment-attempts']);
      expect(await store.pending(), isEmpty);
    });

    test('con pendientes, un cobro nuevo espera su turno aunque haya red', () async {
      server.online = false;
      await sender.submit(path: '/api/collections', body: cobro('c1'), userId: userId);
      server.online = true;

      final result = await sender.submit(path: '/api/collections', body: cobro('c2'), userId: userId);
      expect(result.isQueued, isTrue);
      await sender.flush(userId);
      expect(server.received.map((r) => jsonDecode(r.body)['id']), ['c1', 'c2']);
    });

    test('lo que el backend rechaza queda marcado y no frena al resto', () async {
      server.online = false;
      await sender.submit(path: '/api/collections', body: cobro('malo', credit: creditB), userId: userId);
      await sender.submit(path: '/api/collections', body: cobro('bueno'), userId: userId);
      server
        ..online = true
        ..handler = (request) => jsonDecode(request.body)['id'] == 'malo'
            ? jsonResponse({'message': 'Crédito con id $creditB no encontrado'}, 404)
            : jsonResponse(jsonDecode(request.body) as Object, 201);

      final report = await sender.flush(userId);
      expect(report.sent, 1);
      expect(report.rejected, 1);
      final left = await store.pending();
      expect(left.single.error, 'Crédito con id $creditB no encontrado');
    });

    test('si el servidor falla (5xx) se reintenta después, sin marcar error', () async {
      server.online = false;
      await sender.submit(path: '/api/collections', body: cobro('c1'), userId: userId);
      server
        ..online = true
        ..handler = (_) => jsonResponse({'message': 'Bad Gateway'}, 502);

      expect((await sender.flush(userId)).sent, 0);
      expect((await store.pending()).single.isRejected, isFalse);
    });

    test('cancelar un cobro pendiente quita también su "pagó"', () async {
      server.online = false;
      await sender.submit(path: '/api/collections', body: cobro('c1'), userId: userId);
      await sender.submit(
          path: '/api/payment-attempts', body: {'id': 'a1', 'status': 'PAID', 'collection_id': 'c1'}, userId: userId);

      expect(await sender.cancel('c1'), isTrue);
      expect(await store.pending(), isEmpty);
      expect(await sender.cancel('ya-enviado'), isFalse);
    });

    test('solo se envía la cola del usuario con sesión', () async {
      server.online = false;
      await sender.submit(path: '/api/collections', body: cobro('c1'), userId: 'otro-cobrador');
      server.online = true;

      expect((await sender.flush(userId)).sent, 0);
      expect(server.received, isEmpty);
    });

    test('la cola sobrevive a reiniciar la app', () async {
      final files = MemoryFileStore();
      server.online = false;
      final firstRun = OfflineStore(files);
      await PendingWritesSender(ApiClient(FakeSession(), offline: firstRun, client: server.client), firstRun)
          .submit(path: '/api/collections', body: cobro('c1'), userId: userId);

      final secondRun = OfflineStore(files);
      expect((await secondRun.pending(userId: userId)).single.body['amount'], 5000);
    });
  });

  group('Aviso de conexión', () {
    test('mensajes según el estado', () {
      expect(syncBannerMessage(const SyncStatusEntity(isOnline: false)).text,
          'Sin conexión · Mostrando los últimos datos guardados');
      expect(syncBannerMessage(const SyncStatusEntity(isOnline: false, pending: 2)).text, 'Sin conexión · 2 pendientes por enviar');
      expect(syncBannerMessage(const SyncStatusEntity(pending: 1)).text, 'Enviando 1 pendiente…');

      final rejected = syncBannerMessage(SyncStatusEntity(rejected: [
        RejectedWriteEntity(id: 'x', label: 'Cobro', reason: 'r', createdAt: DateTime(2026)),
      ]));
      expect(rejected.tone, SyncBannerTone.rejected);
      expect(rejected.text, '1 registro no se pudo enviar · Toca para revisar');
    });

    test('sin conexión ni pendientes el aviso no estorba cuando hay red', () {
      expect(const SyncStatusEntity().isVisible, isFalse);
      expect(const SyncStatusEntity(isOnline: false).isVisible, isTrue);
    });
  });
}
