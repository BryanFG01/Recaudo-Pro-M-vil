import 'package:equatable/equatable.dart';

/// Aviso para el cobrador (GET /api/notifications): le aprobaron o rechazaron un retiro o gasto,
/// o un administrador le abrió o cerró la caja.
class AppNotificationEntity extends Equatable {
  /// Creciente: cursor para pedir solo lo nuevo.
  final int id;
  final String type;
  final String title;
  final String body;
  final DateTime? createdAt;

  const AppNotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.createdAt,
  });

  /// Afecta la caja (saldos, retiros, gastos o apertura/cierre): hay que recargar esos datos.
  bool get affectsCash => type.startsWith('withdrawal_') || type.startsWith('expense_') || type.startsWith('cash_');

  @override
  List<Object?> get props => [id, type, title, body, createdAt];
}

/// Avisos nuevos y el cursor para la siguiente consulta.
class NotificationsPageEntity {
  final List<AppNotificationEntity> items;
  final int lastId;
  const NotificationsPageEntity({required this.items, required this.lastId});
}
