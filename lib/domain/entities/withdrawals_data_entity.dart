import 'package:equatable/equatable.dart';

import 'withdrawal_entity.dart';

/// Datos devueltos por GET /api/withdrawals/user/{userId}.
/// Lista de retiros + opcionalmente saldo inicial, saldo actual y sesión activa (solo pintar la data).
class WithdrawalsDataEntity extends Equatable {
  final List<WithdrawalEntity> withdrawals;
  final double? initialBalance;
  final double? currentBalance;
  /// Si el backend lo envía, permite habilitar el formulario de nuevo retiro.
  final String? cashSessionId;

  const WithdrawalsDataEntity({
    required this.withdrawals,
    this.initialBalance,
    this.currentBalance,
    this.cashSessionId,
  });

  @override
  List<Object?> get props => [withdrawals, initialBalance, currentBalance, cashSessionId];
}
