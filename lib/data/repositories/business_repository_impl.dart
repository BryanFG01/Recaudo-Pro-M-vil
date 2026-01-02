import '../../domain/entities/business_entity.dart';
import '../../domain/repositories/business_repository.dart';
import '../datasources/business_remote_datasource.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  final BusinessRemoteDataSource remoteDataSource;

  BusinessRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<BusinessEntity>> getBusinesses() async {
    return await remoteDataSource.getBusinesses();
  }

  @override
  Future<List<BusinessEntity>> searchBusinesses(String query) async {
    return await remoteDataSource.searchBusinesses(query);
  }

  @override
  Future<BusinessEntity?> getBusinessByCode(String code) async {
    return await remoteDataSource.getBusinessByCode(code);
  }

  @override
  Future<BusinessEntity?> getBusinessById(String id) async {
    return await remoteDataSource.getBusinessById(id);
  }
}

