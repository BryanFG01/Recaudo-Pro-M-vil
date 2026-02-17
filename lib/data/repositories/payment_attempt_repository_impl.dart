import '../../domain/entities/payment_attempt_entity.dart';
import '../../domain/repositories/payment_attempt_repository.dart';
import '../datasources/payment_attempt_remote_datasource.dart';

class PaymentAttemptRepositoryImpl implements PaymentAttemptRepository {
  final PaymentAttemptRemoteDataSource remoteDataSource;

  PaymentAttemptRepositoryImpl(this.remoteDataSource);

  @override
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
  }) {
    return remoteDataSource.createPaymentAttempt(
      creditId: creditId,
      clientId: clientId,
      status: status,
      userId: userId,
      businessId: businessId,
      businessCode: businessCode,
      attemptDate: attemptDate,
      collectionId: collectionId,
      accumulatedNoPaymentDays: accumulatedNoPaymentDays,
      notes: notes,
    );
  }

  @override
  Future<List<PaymentAttemptEntity>> getPaymentAttempts({
    String? businessId,
    String? creditId,
    String? clientId,
    String? userId,
    String? status,
  }) {
    return remoteDataSource.getPaymentAttempts(
      businessId: businessId,
      creditId: creditId,
      clientId: clientId,
      userId: userId,
      status: status,
    );
  }

  @override
  Future<List<PaymentAttemptEntity>> getPaymentAttemptsByCreditId(
      String creditId) {
    return remoteDataSource.getPaymentAttemptsByCreditId(creditId);
  }
}
