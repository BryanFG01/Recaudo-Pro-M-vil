import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/credit_remote_datasource.dart';
import '../../data/repositories/credit_repository_impl.dart';
import '../../domain/entities/credit_entity.dart';
import '../../domain/usecases/credits/create_credit_usecase.dart';
import '../../domain/usecases/credits/get_credits_usecase.dart';
import 'auth_provider.dart';
import 'client_provider.dart';

final creditRemoteDataSourceProvider = Provider<CreditRemoteDataSource>((ref) {
  return CreditRemoteDataSourceImpl();
});

final creditRepositoryProvider = Provider<CreditRepositoryImpl>((ref) {
  return CreditRepositoryImpl(ref.watch(creditRemoteDataSourceProvider));
});

final getCreditsUseCaseProvider = Provider<GetCreditsUseCase>((ref) {
  return GetCreditsUseCase(ref.watch(creditRepositoryProvider));
});

final createCreditUseCaseProvider = Provider<CreateCreditUseCase>((ref) {
  return CreateCreditUseCase(ref.watch(creditRepositoryProvider));
});

/// Créditos del negocio filtrados por "mis" clientes (GET /api/clients con user_id).
/// Solo se muestran créditos cuyo clientId está en la lista de clientes del usuario.
final creditsProvider = FutureProvider<List<CreditEntity>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return [];

  final clients = await ref.watch(clientsProvider.future);
  final myClientIds = Set<String>.from(clients.map((c) => c.id));

  final useCase = ref.watch(getCreditsUseCaseProvider);
  final allCredits = await useCase(currentUser.businessId);
  return allCredits
      .where((credit) => myClientIds.contains(credit.clientId))
      .toList();
});

/// Total recaudo real = suma de total_paid de GET /api/credits/summary?business_id=&user_id=
/// Parámetro: (businessId, userId).
final totalRecaudoRealProvider =
    FutureProvider.family<double, ({String businessId, String userId})>(
        (ref, params) async {
  final list = await ref
      .read(creditRepositoryProvider)
      .getCreditsSummaryByUser(params.businessId, params.userId);
  return list.fold<double>(0, (sum, e) => sum + e.totalPaid);
});

/// Total ventas (lo que se presta) = suma de total_amount de GET /api/credits/summary?business_id=&user_id=.
/// La API de credits/summary ya trae el total por crédito; sumamos todos los del usuario.
final totalVentasHoyProvider =
    FutureProvider.family<double, ({String businessId, String userId})>(
        (ref, params) async {
  final list = await ref
      .read(creditRepositoryProvider)
      .getCreditsSummaryByUser(params.businessId, params.userId);
  return list.fold<double>(0, (sum, e) => sum + e.totalAmount);
});

/// Ventas de una sesión de caja = suma de total_amount de créditos con cash_session_id == sessionId.
/// Fallback cuando el flow devuelve total_credits 0 (p. ej. tras actualizar caja inicial).
final totalVentasPorSesionProvider =
    FutureProvider.family<double, ({String businessId, String userId, String sessionId})>(
        (ref, params) async {
  if (params.sessionId.isEmpty) return 0.0;
  final useCase = ref.watch(getCreditsUseCaseProvider);
  final allCredits = await useCase(params.businessId);
  final clients = await ref.watch(clientsProvider.future);
  final myClientIds = Set<String>.from(clients.map((c) => c.id));
  return allCredits
      .where((c) =>
          myClientIds.contains(c.clientId) &&
          c.cashSessionId == params.sessionId)
      .fold<double>(0, (sum, c) => sum + c.totalAmount);
});
