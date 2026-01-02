import '../entities/collection_entity.dart';
import '../entities/dashboard_stats_entity.dart';

abstract class CollectionRepository {
  Future<List<CollectionEntity>> getCollections();
  Future<List<CollectionEntity>> getRecentCollections({int limit = 10});
  Future<List<CollectionEntity>> getCollectionsByClientId(String clientId);
  Future<List<CollectionEntity>> getCollectionsByCreditId(String creditId);
  Future<CollectionEntity> createCollection(CollectionEntity collection, {String? businessId});
  Future<DashboardStatsEntity> getDashboardStats({
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<List<Map<String, dynamic>>> getWeeklyCollection();
}

