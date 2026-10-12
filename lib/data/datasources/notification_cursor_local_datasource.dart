import 'package:shared_preferences/shared_preferences.dart';

/// Último aviso visto por usuario (para no repetir avisos al reabrir la app).
class NotificationCursorLocalDataSource {
  static String _key(String userId) => 'notifications_cursor_$userId';

  Future<int?> read(String userId) async => (await SharedPreferences.getInstance()).getInt(_key(userId));

  Future<void> save(String userId, int lastId) async =>
      (await SharedPreferences.getInstance()).setInt(_key(userId), lastId);
}
