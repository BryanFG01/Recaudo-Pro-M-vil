import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:recaudo_pro/data/datasources/api_client.dart';
import 'package:recaudo_pro/data/datasources/notification_cursor_local_datasource.dart';
import 'package:recaudo_pro/data/datasources/notification_remote_datasource.dart';
import 'package:recaudo_pro/data/repositories/notification_repository_impl.dart';
import 'package:recaudo_pro/domain/entities/app_notification_entity.dart';
import 'package:recaudo_pro/presentation/widgets/notification_toast.dart';

import 'api_client_test.dart' show FakeSession;

class MemoryCursor extends NotificationCursorLocalDataSource {
  final Map<String, int> values = {};
  @override
  Future<int?> read(String userId) async => values[userId];
  @override
  Future<void> save(String userId, int lastId) async => values[userId] = lastId;
}

AppNotificationEntity notice(int id, String type, String title, String body) =>
    AppNotificationEntity(id: id, type: type, title: title, body: body);

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: 'BASE_BACK=https://api.test'));

  test('la primera vez solo guarda el cursor; después trae solo lo nuevo', () async {
    final requested = <String>[];
    final api = ApiClient(FakeSession(access: 'A'), client: MockClient((req) async {
      requested.add(req.url.query);
      final after = req.url.queryParameters['after'];
      final items = after == null
          ? [
              {'id': 5, 'type': 'withdrawal_approved', 'title': 'viejo', 'body': 'x'},
            ]
          : [
              {'id': 6, 'type': 'withdrawal_rejected', 'title': 'Retiro rechazado', 'body': 'Tu retiro de \$ 20.000 fue rechazado'},
            ];
      return http.Response(jsonEncode({'items': items, 'last_id': after == null ? 5 : 6}), 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    }));
    final cursor = MemoryCursor();
    final repo = NotificationRepositoryImpl(NotificationRemoteDataSource(api), cursor);

    expect(await repo.fetchNew('u1'), isEmpty); // no repite avisos viejos al instalar
    expect(cursor.values['u1'], 5);
    final fresh = await repo.fetchNew('u1');
    expect(fresh.single.title, 'Retiro rechazado');
    expect(fresh.single.affectsCash, isTrue);
    expect(requested, ['', 'after=5']);
  });

  test('sin conexión no pierde el cursor ni falla', () async {
    final api = ApiClient(FakeSession(access: 'A'), client: MockClient((_) async => throw http.ClientException('sin red')));
    final cursor = MemoryCursor()..values['u1'] = 9;
    expect(await NotificationRepositoryImpl(NotificationRemoteDataSource(api), cursor).fetchNew('u1'), isEmpty);
    expect(cursor.values['u1'], 9);
  });

  test('texto del aviso: el más reciente y cuántos más llegaron', () {
    final one = [notice(1, 'withdrawal_approved', 'Retiro aprobado', 'Tu retiro de \$ 20.000 fue aprobado')];
    expect(notificationToastText(one), 'Retiro aprobado: Tu retiro de \$ 20.000 fue aprobado');
    final three = [...one, notice(2, 'cash_closed', 'Tu caja fue cerrada', 'x'), notice(3, 'expense_rejected', 'Gasto rechazado', 'y')];
    expect(notificationToastText(three), 'Gasto rechazado: y\n+2 avisos más');
  });
}
