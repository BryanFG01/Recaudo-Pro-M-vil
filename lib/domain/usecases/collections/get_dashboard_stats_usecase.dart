import '../../entities/dashboard_stats_entity.dart';
import '../../repositories/collection_repository.dart';

class GetDashboardStatsUseCase {
  final CollectionRepository repository;

  GetDashboardStatsUseCase(this.repository);

  Future<DashboardStatsEntity> call({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return repository.getDashboardStats(
      startDate: startDate,
      endDate: endDate,
    );
  }
}

