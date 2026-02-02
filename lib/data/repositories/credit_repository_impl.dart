import '../../domain/entities/credit_entity.dart';
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
  Future<CreditEntity> createCredit(
    CreditEntity credit, {
    String? businessId,
    String? businessCode,
    String? userNumber,
    String? documentId,
  }) {
    return remoteDataSource.createCredit(
      credit,
      businessId: businessId,
      businessCode: businessCode,
      userNumber: userNumber,
      documentId: documentId,
    );
  }

  @override
  Future<CreditEntity> updateCredit(
      CreditEntity credit, {String? businessId}) {
    return remoteDataSource.updateCredit(credit, businessId: businessId);
  }
}
