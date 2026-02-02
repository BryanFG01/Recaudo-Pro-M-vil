import '../entities/collection_entity.dart';
import '../entities/dashboard_stats_entity.dart';

abstract class CollectionRepository {
  Future<List<CollectionEntity>> getCollections({String? businessId});
  Future<List<CollectionEntity>> getRecentCollections({
    String? businessId,
    int limit = 10,
  });
  Future<List<CollectionEntity>> getCollectionsByClientId(
    String clientId, {
    String? businessId,
  });
  Future<List<CollectionEntity>> getCollectionsByCreditId(
    String creditId, {
    String? businessId,
  });
  Future<CollectionEntity> createCollection(
      CollectionEntity collection, {String? businessId});
  Future<DashboardStatsEntity> getDashboardStats({
    required String businessId,
    DateTime? startDate,
    DateTime? endDate,
    Set<String>? filterClientIds,
  });
  Future<List<Map<String, dynamic>>> getWeeklyCollection({
    String? businessId,
  });
}

