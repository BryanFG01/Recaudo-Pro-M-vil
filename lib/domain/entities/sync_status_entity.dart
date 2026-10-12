import 'package:equatable/equatable.dart';

/// Cobro o "no pagó" registrado sin conexión que el backend rechazó al reenviarlo.
class RejectedWriteEntity extends Equatable {
  final String id;

  /// "Cobro" o "No pagó".
  final String label;
  final double? amount;
  final String reason;
  final DateTime createdAt;

  const RejectedWriteEntity({
    required this.id,
    required this.label,
    required this.reason,
    required this.createdAt,
    this.amount,
  });

  @override
  List<Object?> get props => [id, label, amount, reason, createdAt];
}

/// Estado de la conexión y de la cola de envío del cobrador.
class SyncStatusEntity extends Equatable {
  final bool isOnline;
  final bool isSyncing;

  /// Registros esperando conexión.
  final int pending;
  final List<RejectedWriteEntity> rejected;

  const SyncStatusEntity({
    this.isOnline = true,
    this.isSyncing = false,
    this.pending = 0,
    this.rejected = const [],
  });

  bool get isVisible => !isOnline || pending > 0 || rejected.isNotEmpty;

  SyncStatusEntity copyWith({bool? isOnline, bool? isSyncing, int? pending, List<RejectedWriteEntity>? rejected}) =>
      SyncStatusEntity(
        isOnline: isOnline ?? this.isOnline,
        isSyncing: isSyncing ?? this.isSyncing,
        pending: pending ?? this.pending,
        rejected: rejected ?? this.rejected,
      );

  @override
  List<Object?> get props => [isOnline, isSyncing, pending, rejected];
}
