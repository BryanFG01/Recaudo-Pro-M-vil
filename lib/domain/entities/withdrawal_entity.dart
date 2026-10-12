import 'package:equatable/equatable.dart';

/// applied: ya resta de la caja · pending: retiro esperando aprobación · rejected: no resta.
enum WithdrawalStatus { applied, pending, rejected }

class WithdrawalEntity extends Equatable {
  final String id;
  final String cashSessionId;
  final String userId;
  final double amount;
  final String reason;
  final bool isApproved;
  final DateTime? createdAt;
  final DateTime? approvedAt;

  /// 'withdrawal' (retiro) o 'expense' (gasto).
  final String kind;
  final bool isRejected;

  const WithdrawalEntity({
    required this.id,
    required this.cashSessionId,
    required this.userId,
    required this.amount,
    required this.reason,
    required this.isApproved,
    this.createdAt,
    this.approvedAt,
    this.kind = 'withdrawal',
    this.isRejected = false,
  });

  /// Gasto: por tipo, o por el prefijo "[GASTO]" de los registros anteriores al tipo.
  bool get isExpense => kind == 'expense' || reason.startsWith('[GASTO]');

  /// Motivo sin el prefijo "[GASTO] " de los registros anteriores.
  String get displayReason => reason.replaceFirst('[GASTO] ', '');

  /// Si ya resta de la caja: el gasto al registrarse, el retiro al aprobarse; rechazado nunca.
  WithdrawalStatus get status {
    if (isRejected) return WithdrawalStatus.rejected;
    if (isApproved || isExpense) return WithdrawalStatus.applied;
    return WithdrawalStatus.pending;
  }

  @override
  List<Object?> get props =>
      [id, cashSessionId, userId, amount, reason, isApproved, createdAt, approvedAt, kind, isRejected];
}
