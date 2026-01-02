import '../../domain/entities/credit_entity.dart';
import '../../domain/repositories/credit_repository.dart';
import '../datasources/credit_remote_datasource.dart';

class CreditRepositoryImpl implements CreditRepository {
  final CreditRemoteDataSource remoteDataSource;

  CreditRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<CreditEntity>> getCredits() {
    return remoteDataSource.getCredits();
  }

  @override
  Future<List<CreditEntity>> getCreditsByClientId(String clientId) {
    return remoteDataSource.getCreditsByClientId(clientId);
  }

  @override
  Future<CreditEntity?> getCreditById(String id) {
    return remoteDataSource.getCreditById(id);
  }

  @override
  Future<CreditEntity> createCredit(CreditEntity credit, {String? businessId}) {
    return remoteDataSource.createCredit(credit, businessId: businessId);
  }

  @override
  Future<CreditEntity> updateCredit(CreditEntity credit, {String? businessId}) {
    return remoteDataSource.updateCredit(credit, businessId: businessId);
  }
}

