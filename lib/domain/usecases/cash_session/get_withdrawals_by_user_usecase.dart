import '../../entities/withdrawals_data_entity.dart';
import '../../repositories/cash_session_repository.dart';

class GetWithdrawalsByUserUseCase {
  final CashSessionRepository repository;

  GetWithdrawalsByUserUseCase(this.repository);

  Future<WithdrawalsDataEntity> call(String userId) {
    return repository.getWithdrawalsByUser(userId);
  }
}
