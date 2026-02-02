import '../../entities/cash_session_entity.dart';
import '../../repositories/cash_session_repository.dart';

class GetActiveCashSessionUseCase {
  final CashSessionRepository repository;

  GetActiveCashSessionUseCase(this.repository);

  Future<CashSessionEntity?> call(String userId) {
    return repository.getActiveCashSessionByUserId(userId);
  }
}
