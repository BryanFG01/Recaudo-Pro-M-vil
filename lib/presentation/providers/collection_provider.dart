import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/collection_remote_datasource.dart';
import '../../data/repositories/collection_repository_impl.dart';
import '../../domain/entities/collection_entity.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/usecases/collections/create_collection_usecase.dart';
import '../../domain/usecases/collections/get_dashboard_stats_usecase.dart';
import 'auth_provider.dart';
import 'client_provider.dart';
import 'credit_provider.dart';

final collectionRemoteDataSourceProvider =
    Provider<CollectionRemoteDataSource>((ref) {
  return CollectionRemoteDataSourceImpl(ref.watch(creditRemoteDataSourceProvider));
});

final collectionRepositoryProvider = Provider<CollectionRepositoryImpl>((ref) {
  return CollectionRepositoryImpl(
      ref.watch(collectionRemoteDataSourceProvider));
});

final getDashboardStatsUseCaseProvider =
    Provider<GetDashboardStatsUseCase>((ref) {
  return GetDashboardStatsUseCase(ref.watch(collectionRepositoryProvider));
});

final createCollectionUseCaseProvider = Provider<CreateCollectionUseCase>((ref) {
  return CreateCollectionUseCase(ref.watch(collectionRepositoryProvider));
});

/// Estadísticas del dashboard filtradas por "mis" clientes (solo recaudos/créditos de mis clientes).
final dashboardStatsProvider =
    FutureProvider.family<DashboardStatsEntity, int>((ref, period) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    throw StateError('Usuario no autenticado');
  }
  final clients = await ref.watch(clientsProvider.future);
  final filterClientIds = Set<String>.from(clients.map((c) => c.id));

  final useCase = ref.watch(getDashboardStatsUseCaseProvider);
  final now = DateTime.now();
  DateTime startDate;
  DateTime endDate;

  switch (period) {
    case 0:
      startDate = DateTime(now.year, now.month, now.day);
      endDate = startDate.add(const Duration(days: 1));
      break;
    case 1:
      startDate = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      endDate =
          DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
      break;
    case 2:
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 1);
      break;
    default:
      startDate = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      endDate =
          DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  }

  return useCase(
    businessId: currentUser.businessId,
    startDate: startDate,
    endDate: endDate,
    filterClientIds: filterClientIds,
  );
});

/// Recaudos recientes filtrados por "mis" clientes (solo recaudos de clientes del usuario).
final recentCollectionsProvider =
    FutureProvider<List<CollectionEntity>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return [];
  final clients = await ref.watch(clientsProvider.future);
  final myClientIds = Set<String>.from(clients.map((c) => c.id));
  final repository = ref.watch(collectionRepositoryProvider);
  final all = await repository.getRecentCollections(
    businessId: currentUser.businessId,
    limit: 50,
  );
  return all
      .where((c) => myClientIds.contains(c.clientId))
      .take(10)
      .toList();
});
