import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/payment_attempt_remote_datasource.dart';
import '../../data/repositories/payment_attempt_repository_impl.dart';
import '../../domain/entities/payment_attempt_entity.dart';

final paymentAttemptRemoteDataSourceProvider =
    Provider<PaymentAttemptRemoteDataSource>((ref) {
  return PaymentAttemptRemoteDataSourceImpl();
});

final paymentAttemptRepositoryProvider =
    Provider<PaymentAttemptRepositoryImpl>((ref) {
  return PaymentAttemptRepositoryImpl(
    ref.watch(paymentAttemptRemoteDataSourceProvider),
  );
});

/// Parámetros para listar intentos de pago (GET /api/payment-attempts).
class PaymentAttemptsParams {
  final String? businessId;
  final String? creditId;
  final String? clientId;
  final String? userId;
  final String? status;

  const PaymentAttemptsParams({
    this.businessId,
    this.creditId,
    this.clientId,
    this.userId,
    this.status,
  });
}

/// Lista de intentos de pago (para pintar en card cuotas atrasadas). Filtros: business_id, credit_id, client_id, user_id, status.
final paymentAttemptsProvider =
    FutureProvider.family<List<PaymentAttemptEntity>, PaymentAttemptsParams>(
        (ref, params) async {
  final repo = ref.watch(paymentAttemptRepositoryProvider);
  return repo.getPaymentAttempts(
    businessId: params.businessId,
    creditId: params.creditId,
    clientId: params.clientId,
    userId: params.userId,
    status: params.status,
  );
});

/// GET /api/payment-attempts/credit/{creditId}. Para pintar accumulated_no_payment_days (días sin pago) en Mi cartera.
final paymentAttemptsByCreditIdProvider =
    FutureProvider.family<List<PaymentAttemptEntity>, String>((ref, creditId) {
  final repo = ref.watch(paymentAttemptRepositoryProvider);
  return repo.getPaymentAttemptsByCreditId(creditId);
});

/// Créditos con acción hoy (abono, pago o no pago). En Mi cartera la card se esconde en "Pendiente"
/// y vuelve a aparecer al filtrar (Pagaron/No pagaron/Todos) o al día siguiente.
final creditsWithActionTodayProvider =
    StateProvider<Set<String>>((ref) => <String>{});
