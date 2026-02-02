import '../../entities/dashboard_stats_entity.dart';
import '../../repositories/collection_repository.dart';

class GetDashboardStatsUseCase {
  final CollectionRepository repository;

  GetDashboardStatsUseCase(this.repository);

  Future<DashboardStatsEntity> call({
    required String businessId,
    DateTime? startDate,
    DateTime? endDate,
    Set<String>? filterClientIds,
  }) {
    return repository.getDashboardStats(
      businessId: businessId,
      startDate: startDate,
      endDate: endDate,
      filterClientIds: filterClientIds,
    );
  }
}

