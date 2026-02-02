import '../../entities/withdrawal_entity.dart';
import '../../repositories/cash_session_repository.dart';

class CreateWithdrawalUseCase {
  final CashSessionRepository repository;

  CreateWithdrawalUseCase(this.repository);

  Future<WithdrawalEntity> call({
    required String cashSessionId,
    required String userId,
    required double amount,
    required String reason,
    bool isApproved = false,
  }) {
    return repository.createWithdrawal(
      cashSessionId: cashSessionId,
      userId: userId,
      amount: amount,
      reason: reason,
      isApproved: isApproved,
    );
  }
}
