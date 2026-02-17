import '../entities/cash_session_entity.dart';
import '../entities/daily_summary_by_user_entity.dart';
import '../entities/cash_session_flow_entity.dart';
import '../entities/daily_summary_entity.dart';
import '../entities/withdrawal_entity.dart';
import '../entities/withdrawals_data_entity.dart';

abstract class CashSessionRepository {
  Future<CashSessionEntity?> getCashSessionById(String id);
  Future<CashSessionFlowEntity?> getCashSessionFlow(String sessionId);
  Future<CashSessionEntity?> getActiveCashSessionByUserId(String userId);
  Future<CashSessionEntity?> getCashSessionByUserId(String userId);
  Future<WithdrawalEntity> createWithdrawal({
    required String cashSessionId,
    required String userId,
    required double amount,
    required String reason,
    bool isApproved = false,
  });
  Future<WithdrawalsDataEntity> getWithdrawalsByUser(String userId);
  Future<DailySummaryEntity?> getDailySummary(String sessionId);
  Future<DailySummaryByUserEntity> getDailySummaryByUserId(String userId);
  Future<List<WithdrawalEntity>> getWithdrawalsBySession({
    required String cashSessionId,
    required String userId,
  });
  Future<List<CashSessionEntity>> getAllCashSessionsByUserId(String userId);
}
