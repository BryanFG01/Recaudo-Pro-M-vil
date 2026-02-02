import '../../domain/entities/cash_session_entity.dart';
import '../../domain/entities/cash_session_flow_entity.dart';
import '../../domain/entities/withdrawal_entity.dart';
import '../../domain/entities/withdrawals_data_entity.dart';
import '../../domain/repositories/cash_session_repository.dart';
import '../datasources/cash_session_remote_datasource.dart';

class CashSessionRepositoryImpl implements CashSessionRepository {
  final CashSessionRemoteDataSource remoteDataSource;

  CashSessionRepositoryImpl(this.remoteDataSource);

  @override
  Future<CashSessionEntity?> getCashSessionById(String id) {
    return remoteDataSource.getCashSessionById(id);
  }

  @override
  Future<CashSessionFlowEntity?> getCashSessionFlow(String sessionId) {
    return remoteDataSource.getCashSessionFlow(sessionId);
  }

  @override
  Future<CashSessionEntity?> getActiveCashSessionByUserId(String userId) {
    return remoteDataSource.getActiveCashSessionByUserId(userId);
  }

  @override
  Future<CashSessionEntity?> getCashSessionByUserId(String userId) {
    return remoteDataSource.getCashSessionByUserId(userId);
  }

  @override
  Future<WithdrawalEntity> createWithdrawal({
    required String cashSessionId,
    required String userId,
    required double amount,
    required String reason,
    bool isApproved = false,
  }) {
    return remoteDataSource.createWithdrawal(
      cashSessionId: cashSessionId,
      userId: userId,
      amount: amount,
      reason: reason,
      isApproved: isApproved,
    );
  }

  @override
  Future<WithdrawalsDataEntity> getWithdrawalsByUser(String userId) {
    return remoteDataSource.getWithdrawalsByUser(userId);
  }
}
