import '../../domain/entities/collection_entity.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/repositories/collection_repository.dart';
import '../datasources/collection_remote_datasource.dart';

class CollectionRepositoryImpl implements CollectionRepository {
  final CollectionRemoteDataSource remoteDataSource;

  CollectionRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<CollectionEntity>> getCollections() {
    return remoteDataSource.getCollections();
  }

  @override
  Future<List<CollectionEntity>> getRecentCollections({int limit = 10}) {
    return remoteDataSource.getRecentCollections(limit: limit);
  }

  @override
  Future<List<CollectionEntity>> getCollectionsByClientId(String clientId) {
    return remoteDataSource.getCollectionsByClientId(clientId);
  }

  @override
  Future<List<CollectionEntity>> getCollectionsByCreditId(String creditId) {
    return remoteDataSource.getCollectionsByCreditId(creditId);
  }

  @override
  Future<CollectionEntity> createCollection(CollectionEntity collection, {String? businessId}) {
    return remoteDataSource.createCollection(collection, businessId: businessId);
  }

  @override
  Future<DashboardStatsEntity> getDashboardStats({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return remoteDataSource.getDashboardStats(
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getWeeklyCollection() {
    return remoteDataSource.getWeeklyCollection();
  }
}

