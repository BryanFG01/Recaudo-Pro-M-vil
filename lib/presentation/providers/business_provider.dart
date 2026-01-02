import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/business_remote_datasource.dart';
import '../../data/repositories/business_repository_impl.dart';
import '../../domain/entities/business_entity.dart';
import '../../domain/usecases/business/get_businesses_usecase.dart';

// Data Sources
final businessRemoteDataSourceProvider =
    Provider<BusinessRemoteDataSource>((ref) {
  return BusinessRemoteDataSourceImpl();
});

// Repositories
final businessRepositoryProvider = Provider<BusinessRepositoryImpl>((ref) {
  return BusinessRepositoryImpl(ref.watch(businessRemoteDataSourceProvider));
});

// Use Cases
final getBusinessesUseCaseProvider = Provider<GetBusinessesUseCase>((ref) {
  return GetBusinessesUseCase(ref.watch(businessRepositoryProvider));
});

// State Providers
final businessesProvider =
    FutureProvider<List<BusinessEntity>>((ref) async {
  final useCase = ref.watch(getBusinessesUseCaseProvider);
  return useCase();
});

// Selected Business Provider
final selectedBusinessProvider =
    StateNotifierProvider<SelectedBusinessNotifier, BusinessEntity?>((ref) {
  return SelectedBusinessNotifier();
});

class SelectedBusinessNotifier extends StateNotifier<BusinessEntity?> {
  SelectedBusinessNotifier() : super(null);

  void setBusiness(BusinessEntity business) {
    state = business;
  }

  void clearBusiness() {
    state = null;
  }
}

