import '../entities/payment_attempt_entity.dart';

abstract class PaymentAttemptRepository {
  Future<PaymentAttemptEntity> createPaymentAttempt({
    required String creditId,
    required String clientId,
    required String status,
    required String userId,
    required String businessId,
    String? businessCode,
    DateTime? attemptDate,
    String? collectionId,
    int accumulatedNoPaymentDays = 0,
    String? notes,
  });

  Future<List<PaymentAttemptEntity>> getPaymentAttempts({
    String? businessId,
    String? creditId,
    String? clientId,
    String? userId,
    String? status,
  });

  /// GET /api/payment-attempts/credit/{creditId}. Para pintar accumulated_no_payment_days.
  Future<List<PaymentAttemptEntity>> getPaymentAttemptsByCreditId(
      String creditId);
}
