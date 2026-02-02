import '../../entities/cash_session_entity.dart';
import '../../repositories/cash_session_repository.dart';

class GetCashSessionByUserIdUseCase {
  final CashSessionRepository repository;

  GetCashSessionByUserIdUseCase(this.repository);

  Future<CashSessionEntity?> call(String userId) {
    return repository.getCashSessionByUserId(userId);
  }
}
