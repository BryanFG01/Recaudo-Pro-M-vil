import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/credit_remote_datasource.dart';
import '../../data/repositories/credit_repository_impl.dart';
import '../../domain/entities/credit_entity.dart';
import '../../domain/usecases/credits/create_credit_usecase.dart';
import '../../domain/usecases/credits/get_credits_usecase.dart';

// Data Sources
final creditRemoteDataSourceProvider = Provider<CreditRemoteDataSource>((ref) {
  return CreditRemoteDataSourceImpl();
});

// Repositories
final creditRepositoryProvider = Provider<CreditRepositoryImpl>((ref) {
  return CreditRepositoryImpl(ref.watch(creditRemoteDataSourceProvider));
});

// Use Cases
final getCreditsUseCaseProvider = Provider<GetCreditsUseCase>((ref) {
  return GetCreditsUseCase(ref.watch(creditRepositoryProvider));
});

final createCreditUseCaseProvider = Provider<CreateCreditUseCase>((ref) {
  return CreateCreditUseCase(ref.watch(creditRepositoryProvider));
});

// State Providers
final creditsProvider = FutureProvider<List<CreditEntity>>((ref) async {
  final useCase = ref.watch(getCreditsUseCaseProvider);
  return useCase();
});
