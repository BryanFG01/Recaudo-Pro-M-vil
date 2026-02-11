import '../../domain/entities/credit_entity.dart';
import '../../domain/entities/credit_summary_entity.dart';
import '../../domain/repositories/credit_repository.dart';
import '../datasources/credit_remote_datasource.dart';

class CreditRepositoryImpl implements CreditRepository {
  final CreditRemoteDataSource remoteDataSource;

  CreditRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<CreditEntity>> getCredits(String businessId) {
    return remoteDataSource.getCreditsByBusiness(businessId);
  }

  @override
  Future<List<CreditEntity>> getCreditsByClientId(
      String businessId, String clientId) async {
    final all = await remoteDataSource.getCreditsByBusiness(businessId);
    return all.where((c) => c.clientId == clientId).toList();
  }

  @override
  Future<CreditEntity?> getCreditById(String id) {
    return remoteDataSource.getCreditById(id);
  }

  @override
  Future<CreditSummaryEntity?> getCreditSummaryById(String creditId) {
    return remoteDataSource.getCreditSummaryById(creditId);
  }

  @override
  Future<List<CreditSummaryEntity>> getCreditsSummaryByUser(
      String businessId, String userId) {
    return remoteDataSource.getCreditsSummaryByUser(businessId, userId);
  }

  @override
  Future<CreditEntity> createCredit(
    CreditEntity credit, {
    String? businessId,
    String? businessCode,
    String? userNumber,
    String? documentId,
    String? cashSessionId,
  }) {
    return remoteDataSource.createCredit(
      credit,
      businessId: businessId,
      businessCode: businessCode,
      userNumber: userNumber,
      documentId: documentId,
      cashSessionId: cashSessionId,
    );
  }

  @override
  Future<CreditEntity> updateCredit(
      CreditEntity credit, {String? businessId}) {
    return remoteDataSource.updateCredit(credit, businessId: businessId);
  }
}
