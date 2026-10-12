/// Reglas de caja (funciones puras, con tests). La API calcula lo mismo en la vista
/// daily_cash_summary; aquí se usan para validar antes de llamar y para explicar las cifras.
library;

import '../entities/daily_summary_by_user_entity.dart';
import '../entities/daily_summary_entity.dart';

/// Caja actual = caja inicial + recaudo − ventas − retiros aprobados − gastos.
double currentCash({
  required double initialBalance,
  required double collected,
  required double sales,
  required double approvedWithdrawals,
  required double expenses,
}) =>
    initialBalance + collected - sales - approvedWithdrawals - expenses;

/// La caja actual es la primera del resumen (la API las ordena de la más reciente a la más antigua).
DailySummaryEntity? currentSessionOf(DailySummaryByUserEntity summary) =>
    summary.items.isEmpty ? null : summary.items.first;

/// Caja inicial con la que arranca la próxima apertura: la caja final de la caja cerrada.
double nextInitialBalance(DailySummaryEntity? session) =>
    session == null ? 0 : (session.closingBalance ?? session.cajaActual);

/// Motivo por el que no se puede cerrar la caja todavía; null si se puede.
String? closeCashBlocker({required int pendingSync, required double pendingWithdrawals}) {
  if (pendingSync > 0) {
    final what = pendingSync == 1 ? '1 registro sin enviar' : '$pendingSync registros sin enviar';
    return 'Tienes $what por falta de conexión. Espera a que se envíen antes de cerrar la caja.';
  }
  if (pendingWithdrawals > 0) {
    return 'Hay retiros pendientes de aprobación. El administrador debe aprobarlos o rechazarlos antes de cerrar.';
  }
  return null;
}

/// Motivo por el que no se pueden registrar cobros, ventas o gastos; null si la caja está abierta.
/// Si no se sabe el estado (sin datos), no se bloquea: la API valida igual.
String? movementBlocker(DailySummaryEntity? session, {required bool known}) {
  if (!known) return null;
  if (session == null || !session.isOpen) {
    return 'Tu caja está cerrada. Ábrela en Reportes para registrar movimientos.';
  }
  return null;
}
