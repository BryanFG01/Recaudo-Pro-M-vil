import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/cash_session_remote_datasource.dart';
import '../../data/repositories/cash_session_repository_impl.dart';
import '../../domain/entities/cash_session_entity.dart';
import '../../domain/entities/cash_session_flow_entity.dart';
import '../../domain/entities/daily_summary_by_user_entity.dart';
import '../../domain/entities/daily_summary_entity.dart';
import '../../domain/services/cash_rules.dart';
import '../../domain/entities/withdrawal_entity.dart';
import '../../domain/entities/withdrawals_data_entity.dart';
import '../../domain/usecases/cash_session/create_withdrawal_usecase.dart';
import '../../domain/usecases/cash_session/get_cash_session_by_user_id_usecase.dart';
import '../../domain/usecases/cash_session/get_cash_session_flow_usecase.dart';
import '../../domain/usecases/cash_session/get_cash_session_usecase.dart';
import '../../domain/usecases/cash_session/get_withdrawals_by_user_usecase.dart';

final cashSessionRemoteDataSourceProvider =
    Provider<CashSessionRemoteDataSource>((ref) {
  return CashSessionRemoteDataSourceImpl();
});

final cashSessionRepositoryProvider =
    Provider<CashSessionRepositoryImpl>((ref) {
  return CashSessionRepositoryImpl(
      ref.watch(cashSessionRemoteDataSourceProvider));
});

final getCashSessionUseCaseProvider = Provider<GetCashSessionUseCase>((ref) {
  return GetCashSessionUseCase(ref.watch(cashSessionRepositoryProvider));
});

final getCashSessionByUserIdUseCaseProvider =
    Provider<GetCashSessionByUserIdUseCase>((ref) {
  return GetCashSessionByUserIdUseCase(
      ref.watch(cashSessionRepositoryProvider));
});

final getCashSessionFlowUseCaseProvider =
    Provider<GetCashSessionFlowUseCase>((ref) {
  return GetCashSessionFlowUseCase(ref.watch(cashSessionRepositoryProvider));
});

final createWithdrawalUseCaseProvider =
    Provider<CreateWithdrawalUseCase>((ref) {
  return CreateWithdrawalUseCase(ref.watch(cashSessionRepositoryProvider));
});

final getWithdrawalsByUserUseCaseProvider =
    Provider<GetWithdrawalsByUserUseCase>((ref) {
  return GetWithdrawalsByUserUseCase(ref.watch(cashSessionRepositoryProvider));
});

/// Sesión de caja por ID (GET /api/cash-sessions/{id}).
final cashSessionProvider =
    FutureProvider.family<CashSessionEntity?, String>((ref, sessionId) async {
  final useCase = ref.watch(getCashSessionUseCaseProvider);
  return useCase(sessionId);
});

/// Sesión de caja del usuario para pintar saldo inicial (GET /api/cash-sessions/user/{userId}). 404 → null.
final cashSessionByUserProvider =
    FutureProvider.family<CashSessionEntity?, String>((ref, userId) async {
  final useCase = ref.watch(getCashSessionByUserIdUseCaseProvider);
  return useCase(userId);
});

/// Flujo de caja por sesión (GET /api/cash-sessions/flow/:id). Devuelve cash_flow_by_session.
/// El backend no debe borrar recaudo al actualizar saldo inicial; solo actualizar initial_balance.
/// caja_inicial_restante, total_collected, total_recaudo_mostrado, saldo_disponible, efectivo_en_caja.
/// Saldo disponible = saldo inicial + recaudo (initial_balance + total_collected − retiros). Al aprobar retiros se invalida para ver descuentos.
/// Si sessionId está vacío, no llama a la API y devuelve null.
final cashSessionFlowProvider =
    FutureProvider.family<CashSessionFlowEntity?, String>(
        (ref, sessionId) async {
  if (sessionId.isEmpty) return null;
  final useCase = ref.watch(getCashSessionFlowUseCaseProvider);
  return useCase(sessionId);
});

/// IDs de retiros pendientes del usuario (persiste al salir de la pantalla para notificar "fue aprobado" al volver).
final previousPendingWithdrawalIdsProvider =
    StateProvider.family<Set<String>, String>((ref, userId) => {});

/// Datos del usuario: retiros + opcional saldo inicial/actual (GET /api/withdrawals/user/{userId}).
final FutureProviderFamily<WithdrawalsDataEntity, String>
    withdrawalsByUserProvider =
    FutureProvider.family<WithdrawalsDataEntity, String>((ref, userId) async {
  final useCase = ref.watch(getWithdrawalsByUserUseCaseProvider);
  final result = await useCase(userId);
  return result;
});

/// Resumen diario por usuario para reportes (GET /api/cash-sessions/daily-summary/user/{userId}).
/// Cuerpo: { "items": [...], "totals": { total_recaudo, total_ventas, total_retiros, total_gastos } }.
final dailySummaryByUserProvider =
    FutureProvider.family<DailySummaryByUserEntity, String>(
        (ref, userId) async {
  if (userId.isEmpty) {
    return const DailySummaryByUserEntity(totals: DailySummaryTotalsEntity());
  }
  final repo = ref.watch(cashSessionRepositoryProvider);
  return repo.getDailySummaryByUserId(userId);
});

/// Caja actual del usuario (la más reciente del resumen) con su estado abierta/cerrada.
final currentCashSessionProvider = FutureProvider.family<DailySummaryEntity?, String>((ref, userId) async {
  return currentSessionOf(await ref.watch(dailySummaryByUserProvider(userId).future));
});

/// Motivo para no registrar cobros o ventas (caja cerrada); null si se puede o si no se sabe
/// (sin conexión y sin datos guardados: la API valida igual).
Future<String?> cashMovementBlocker(WidgetRef ref, String userId) async {
  try {
    return movementBlocker(await ref.read(currentCashSessionProvider(userId).future), known: true);
  } catch (_) {
    return movementBlocker(null, known: false);
  }
}

/// Abrir y cerrar caja (requieren conexión). Después recarga todo lo que depende de la caja.
final cashSessionActionsProvider = Provider<CashSessionActions>((ref) => CashSessionActions(ref));

class CashSessionActions {
  final Ref _ref;
  CashSessionActions(this._ref);

  Future<CashSessionEntity> open(String userId) async {
    final session = await _ref.read(cashSessionRepositoryProvider).openCashSession();
    _refresh(userId);
    return session;
  }

  Future<CashSessionEntity> close(String userId, String sessionId) async {
    final session = await _ref.read(cashSessionRepositoryProvider).closeCashSession(sessionId);
    _refresh(userId);
    return session;
  }

  void _refresh(String userId) {
    _ref.invalidate(dailySummaryByUserProvider(userId));
    _ref.invalidate(cashSessionByUserProvider(userId));
    _ref.invalidate(cashSessionFlowProvider);
    _ref.invalidate(withdrawalsByUserProvider(userId));
  }
}

/// Todas las sesiones de caja del usuario (GET /api/cash-sessions/user/{userId}).
/// Devuelve la lista completa para sumar ingresos (initial_balance) de todas.
final allCashSessionsByUserProvider =
    FutureProvider.family<List<CashSessionEntity>, String>((ref, userId) async {
  if (userId.isEmpty) return [];
  final repo = ref.watch(cashSessionRepositoryProvider);
  return repo.getAllCashSessionsByUserId(userId);
});

/// Retiros por sesión y usuario (GET /api/withdrawals?cash_session_id=X&user_id=Y).
/// Clave: ({cashSessionId, userId}) record.
final withdrawalsBySessionProvider = FutureProvider.family<
    List<WithdrawalEntity>,
    ({String cashSessionId, String userId})>((ref, params) async {
  if (params.cashSessionId.isEmpty || params.userId.isEmpty) return [];
  final repo = ref.watch(cashSessionRepositoryProvider);
  return repo.getWithdrawalsBySession(
    cashSessionId: params.cashSessionId,
    userId: params.userId,
  );
});
