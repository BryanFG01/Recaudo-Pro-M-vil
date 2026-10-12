import '../entities/sync_status_entity.dart';

/// Trabajo sin conexión: estado de la red, cola de cobros pendientes y datos descargados.
abstract class SyncRepository {
  bool get isOnline;

  /// Emite al perder (false) o recuperar (true) la conexión con el servidor.
  Stream<bool> get connectivity;

  /// Emite cuando cambia la cola de envío.
  Stream<void> get queueChanges;

  /// Cuántos registros del usuario esperan conexión y cuáles rechazó el backend.
  Future<({int pending, List<RejectedWriteEntity> rejected})> queueOf(String userId);

  /// Envía la cola del usuario. Devuelve cuántos registros llegaron al backend.
  Future<int> sync(String userId);

  /// Descarta un registro rechazado (el cobrador ya lo revisó).
  Future<void> discard(String id);

  /// Descarga lo necesario para trabajar la ruta sin conexión (clientes, créditos, recaudos e
  /// intentos de pago del negocio). Si no hay red no hace nada.
  Future<void> prepareOffline({required String businessId, required String userId});
}
