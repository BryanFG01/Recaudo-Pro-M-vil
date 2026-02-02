import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/cash_session_remote_datasource.dart';
import '../../data/repositories/cash_session_repository_impl.dart';
import '../../domain/entities/cash_session_entity.dart';
import '../../domain/entities/withdrawals_data_entity.dart';
import '../../domain/usecases/cash_session/create_withdrawal_usecase.dart';
import '../../domain/usecases/cash_session/get_active_cash_session_usecase.dart';
import '../../domain/entities/cash_session_flow_entity.dart';
import '../../domain/usecases/cash_session/get_cash_session_by_user_id_usecase.dart';
import '../../domain/usecases/cash_session/get_cash_session_flow_usecase.dart';
import '../../domain/usecases/cash_session/get_cash_session_usecase.dart';
import '../../domain/usecases/cash_session/get_withdrawals_by_user_usecase.dart';

final cashSessionRemoteDataSourceProvider =
    Provider<CashSessionRemoteDataSource>((ref) {
  return CashSessionRemoteDataSourceImpl();
});

final cashSessionRepositoryProvider = Provider<CashSessionRepositoryImpl>((ref) {
  return CashSessionRepositoryImpl(ref.watch(cashSessionRemoteDataSourceProvider));
});

final getCashSessionUseCaseProvider = Provider<GetCashSessionUseCase>((ref) {
  return GetCashSessionUseCase(ref.watch(cashSessionRepositoryProvider));
});

final getActiveCashSessionUseCaseProvider =
    Provider<GetActiveCashSessionUseCase>((ref) {
  return GetActiveCashSessionUseCase(ref.watch(cashSessionRepositoryProvider));
});

final getCashSessionByUserIdUseCaseProvider =
    Provider<GetCashSessionByUserIdUseCase>((ref) {
  return GetCashSessionByUserIdUseCase(ref.watch(cashSessionRepositoryProvider));
});

final getCashSessionFlowUseCaseProvider =
    Provider<GetCashSessionFlowUseCase>((ref) {
  return GetCashSessionFlowUseCase(ref.watch(cashSessionRepositoryProvider));
});

final createWithdrawalUseCaseProvider = Provider<CreateWithdrawalUseCase>((ref) {
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

/// Sesión activa del usuario (GET /api/cash-sessions/active?user_id=...). 404 → null.
final activeCashSessionProvider =
    FutureProvider.family<CashSessionEntity?, String>((ref, userId) async {
  final useCase = ref.watch(getActiveCashSessionUseCaseProvider);
  return useCase(userId);
});

/// Sesión de caja del usuario para pintar saldo inicial (GET /api/cash-sessions/user/{userId}). 404 → null.
final cashSessionByUserProvider =
    FutureProvider.family<CashSessionEntity?, String>((ref, userId) async {
  final useCase = ref.watch(getCashSessionByUserIdUseCaseProvider);
  return useCase(userId);
});

/// Flujo de caja por sesión (GET /api/cash-sessions/flow/:id). Devuelve cash_flow_by_session:
/// caja_inicial_restante, total_collected, total_recaudo_mostrado, saldo_disponible, efectivo_en_caja.
/// Saldo disponible = saldo inicial + recaudo (initial_balance + total_collected − retiros). Al aprobar retiros se invalida para ver descuentos.
/// Si sessionId está vacío, no llama a la API y devuelve null.
final cashSessionFlowProvider =
    FutureProvider.family<CashSessionFlowEntity?, String>((ref, sessionId) async {
  if (sessionId.isEmpty) return null;
  final useCase = ref.watch(getCashSessionFlowUseCaseProvider);
  return useCase(sessionId);
});

/// IDs de retiros pendientes del usuario (persiste al salir de la pantalla para notificar "fue aprobado" al volver).
final previousPendingWithdrawalIdsProvider =
    StateProvider.family<Set<String>, String>((ref, userId) => {});

/// Datos del usuario: retiros + opcional saldo inicial/actual (GET /api/withdrawals/user/{userId}).
final FutureProviderFamily<WithdrawalsDataEntity, String> withdrawalsByUserProvider =
    FutureProvider.family<WithdrawalsDataEntity, String>((ref, userId) async {
  final useCase = ref.watch(getWithdrawalsByUserUseCaseProvider);
  final result = await useCase(userId);
  return result;
});
