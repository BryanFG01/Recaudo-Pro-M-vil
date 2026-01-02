import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/collection_remote_datasource.dart';
import '../../data/repositories/collection_repository_impl.dart';
import '../../domain/entities/collection_entity.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/usecases/collections/create_collection_usecase.dart';
import '../../domain/usecases/collections/get_dashboard_stats_usecase.dart';

// Data Sources
final collectionRemoteDataSourceProvider =
    Provider<CollectionRemoteDataSource>((ref) {
  return CollectionRemoteDataSourceImpl();
});

// Repositories
final collectionRepositoryProvider = Provider<CollectionRepositoryImpl>((ref) {
  return CollectionRepositoryImpl(
      ref.watch(collectionRemoteDataSourceProvider));
});

// Use Cases
final getDashboardStatsUseCaseProvider =
    Provider<GetDashboardStatsUseCase>((ref) {
  return GetDashboardStatsUseCase(ref.watch(collectionRepositoryProvider));
});

final createCollectionUseCaseProvider =
    Provider<CreateCollectionUseCase>((ref) {
  return CreateCollectionUseCase(ref.watch(collectionRepositoryProvider));
});

// State Providers
final dashboardStatsProvider =
    FutureProvider.family<DashboardStatsEntity, int>((ref, period) async {
  final useCase = ref.watch(getDashboardStatsUseCaseProvider);
  final now = DateTime.now();
  DateTime startDate;
  DateTime endDate;

  switch (period) {
    case 0: // Hoy
      startDate = DateTime(now.year, now.month, now.day);
      endDate = startDate.add(const Duration(days: 1));
      break;
    case 1: // Semana
      startDate = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      endDate =
          DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
      break;
    case 2: // Mes
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 1);
      break;
    default:
      startDate = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      endDate =
          DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  }

  return useCase(startDate: startDate, endDate: endDate);
});

final recentCollectionsProvider =
    FutureProvider<List<CollectionEntity>>((ref) async {
  final repository = ref.watch(collectionRepositoryProvider);
  return repository.getRecentCollections(limit: 10);
});
