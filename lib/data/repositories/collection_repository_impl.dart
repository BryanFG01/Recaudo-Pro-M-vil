import '../../domain/entities/collection_entity.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/repositories/collection_repository.dart';
import '../datasources/collection_remote_datasource.dart';

class CollectionRepositoryImpl implements CollectionRepository {
  final CollectionRemoteDataSource remoteDataSource;

  CollectionRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<CollectionEntity>> getCollections({String? businessId}) {
    return remoteDataSource.getCollections(businessId: businessId);
  }

  @override
  Future<List<CollectionEntity>> getRecentCollections({
    String? businessId,
    int limit = 10,
  }) {
    return remoteDataSource.getRecentCollections(
        businessId: businessId, limit: limit);
  }

  @override
  Future<List<CollectionEntity>> getCollectionsByClientId(
    String clientId, {
    String? businessId,
  }) {
    return remoteDataSource.getCollectionsByClientId(clientId,
        businessId: businessId);
  }

  @override
  Future<List<CollectionEntity>> getCollectionsByCreditId(
    String creditId, {
    String? businessId,
  }) {
    return remoteDataSource.getCollectionsByCreditId(creditId,
        businessId: businessId);
  }

  @override
  Future<CollectionEntity> createCollection(
      CollectionEntity collection, {String? businessId}) {
    return remoteDataSource.createCollection(collection,
        businessId: businessId);
  }

  @override
  Future<DashboardStatsEntity> getDashboardStats({
    required String businessId,
    DateTime? startDate,
    DateTime? endDate,
    Set<String>? filterClientIds,
    String? filterUserId,
  }) {
    return remoteDataSource.getDashboardStats(
      businessId: businessId,
      startDate: startDate,
      endDate: endDate,
      filterClientIds: filterClientIds,
      filterUserId: filterUserId,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getWeeklyCollection({
    String? businessId,
  }) {
    return remoteDataSource.getWeeklyCollection(businessId: businessId);
  }
}
