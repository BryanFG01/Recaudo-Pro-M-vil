import '../../entities/cash_session_flow_entity.dart';
import '../../repositories/cash_session_repository.dart';

class GetCashSessionFlowUseCase {
  final CashSessionRepository repository;

  GetCashSessionFlowUseCase(this.repository);

  Future<CashSessionFlowEntity?> call(String sessionId) {
    return repository.getCashSessionFlow(sessionId);
  }
}
