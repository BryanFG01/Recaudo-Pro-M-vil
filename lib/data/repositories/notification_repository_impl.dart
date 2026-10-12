import '../../domain/entities/app_notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_cursor_local_datasource.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._remote, this._cursor);

  final NotificationRemoteDataSource _remote;
  final NotificationCursorLocalDataSource _cursor;

  @override
  Future<List<AppNotificationEntity>> fetchNew(String userId) async {
    final after = await _cursor.read(userId);
    final page = await _remote.fetch(after: after);
    if (page == null) return const []; // sin conexión: se reintenta después
    await _cursor.save(userId, page.lastId);
    // Primera vez en este teléfono: solo se toma el cursor, sin mostrar avisos viejos
    return after == null ? const [] : page.items;
  }
}
