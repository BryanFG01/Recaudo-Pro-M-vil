import '../../entities/cash_session_entity.dart';
import '../../repositories/cash_session_repository.dart';

class GetCashSessionUseCase {
  final CashSessionRepository repository;

  GetCashSessionUseCase(this.repository);

  Future<CashSessionEntity?> call(String sessionId) {
    return repository.getCashSessionById(sessionId);
  }
}
