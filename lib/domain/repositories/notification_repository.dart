import '../entities/app_notification_entity.dart';

abstract class NotificationRepository {
  /// Avisos nuevos del usuario desde el último consultado (el cursor queda guardado en el teléfono).
  /// La primera vez solo guarda el cursor: no repite avisos viejos. Sin conexión devuelve [].
  Future<List<AppNotificationEntity>> fetchNew(String userId);
}
