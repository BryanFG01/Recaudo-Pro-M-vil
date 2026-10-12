import 'package:flutter_test/flutter_test.dart';
import 'package:recaudo_pro/core/utils/currency_format.dart';
import 'package:recaudo_pro/data/models/withdrawal_model.dart';
import 'package:recaudo_pro/domain/entities/daily_summary_by_user_entity.dart';
import 'package:recaudo_pro/domain/entities/daily_summary_entity.dart';
import 'package:recaudo_pro/domain/entities/withdrawal_entity.dart';
import 'package:recaudo_pro/domain/services/cash_rules.dart';

WithdrawalEntity movement({String kind = 'withdrawal', bool approved = false, bool rejected = false, String reason = 'x'}) =>
    WithdrawalEntity(
      id: '1', cashSessionId: 's', userId: 'u', amount: 1000, reason: reason,
      isApproved: approved, kind: kind, isRejected: rejected,
    );

void main() {
  test('caja actual = inicial + recaudo − ventas − retiros aprobados − gastos (igual que la API)', () {
    // Mismo escenario que la prueba de integración de la API
    expect(
      currentCash(initialBalance: 200000, collected: 30000, sales: 100000, approvedWithdrawals: 5000, expenses: 8000),
      117000,
    );
  });

  test('la caja actual es la más reciente del resumen', () {
    const summary = DailySummaryByUserEntity(totals: DailySummaryTotalsEntity(), items: [
      DailySummaryEntity(cashSessionId: 'hoy', status: 'open'),
      DailySummaryEntity(cashSessionId: 'ayer', status: 'closed'),
    ]);
    expect(currentSessionOf(summary)?.cashSessionId, 'hoy');
    expect(currentSessionOf(const DailySummaryByUserEntity(totals: DailySummaryTotalsEntity())), isNull);
  });

  test('al cerrar, la caja final es la caja inicial de la próxima apertura', () {
    const closed = DailySummaryEntity(cashSessionId: 's', status: 'closed', cajaActual: 2023889, closingBalance: 2023889);
    expect(nextInitialBalance(closed), 2023889);
    expect(nextInitialBalance(null), 0);
  });

  test('no se cierra con cobros sin enviar ni con retiros por aprobar', () {
    expect(closeCashBlocker(pendingSync: 2, pendingWithdrawals: 0), contains('2 registros sin enviar'));
    expect(closeCashBlocker(pendingSync: 0, pendingWithdrawals: 5000), contains('retiros pendientes'));
    expect(closeCashBlocker(pendingSync: 0, pendingWithdrawals: 0), isNull);
  });

  test('con la caja cerrada (o sin caja) no se registran movimientos; sin datos no se bloquea', () {
    expect(movementBlocker(const DailySummaryEntity(cashSessionId: 's', status: 'closed'), known: true), contains('cerrada'));
    expect(movementBlocker(null, known: true), contains('cerrada'));
    expect(movementBlocker(const DailySummaryEntity(cashSessionId: 's'), known: true), isNull);
    expect(movementBlocker(null, known: false), isNull);
  });

  test('dinero redondeado al peso (misma cifra que el Admin y los avisos)', () {
    expect(AppCurrency.format(3223888.88), '\$ 3.223.889');
    expect(AppCurrency.format(2000000), '\$ 2.000.000');
    expect(AppCurrency.formatter.format(44445), '\$ 44.445');
  });

  test('las horas de la API (UTC) se muestran en la hora del teléfono', () {
    final w = WithdrawalModel.fromJson(const {'id': '1', 'amount': 1000, 'created_at': '2026-10-12T21:28:00Z'});
    expect(w.createdAt!.isUtc, isFalse);
    expect(w.createdAt!.toUtc(), DateTime.utc(2026, 10, 12, 21, 28));
  });

  test('estado de gastos y retiros: el gasto resta al registrarse, el retiro al aprobarse', () {
    expect(movement(kind: 'expense').status, WithdrawalStatus.applied);
    expect(movement().status, WithdrawalStatus.pending);
    expect(movement(approved: true).status, WithdrawalStatus.applied);
    expect(movement(kind: 'expense', rejected: true).status, WithdrawalStatus.rejected);
    // Gastos guardados antes del tipo, con el prefijo [GASTO]
    expect(movement(reason: '[GASTO] Gasolina').isExpense, isTrue);
    expect(movement(reason: '[GASTO] Gasolina').displayReason, 'Gasolina');
  });
}
