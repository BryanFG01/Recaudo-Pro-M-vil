import '../../entities/daily_summary_entity.dart';
import '../../repositories/cash_session_repository.dart';

class GetDailySummaryUseCase {
  final CashSessionRepository repository;

  GetDailySummaryUseCase(this.repository);

  Future<DailySummaryEntity?> call(String sessionId) {
    return repository.getDailySummary(sessionId);
  }
}
