import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/credit_remote_datasource.dart';
import '../../data/repositories/credit_repository_impl.dart';
import '../../domain/entities/credit_entity.dart';
import '../../domain/usecases/credits/create_credit_usecase.dart';
import '../../domain/usecases/credits/get_credits_usecase.dart';
import 'auth_provider.dart';
import 'client_provider.dart';

final creditRemoteDataSourceProvider = Provider<CreditRemoteDataSource>((ref) {
  return CreditRemoteDataSourceImpl();
});

final creditRepositoryProvider = Provider<CreditRepositoryImpl>((ref) {
  return CreditRepositoryImpl(ref.watch(creditRemoteDataSourceProvider));
});

final getCreditsUseCaseProvider = Provider<GetCreditsUseCase>((ref) {
  return GetCreditsUseCase(ref.watch(creditRepositoryProvider));
});

final createCreditUseCaseProvider = Provider<CreateCreditUseCase>((ref) {
  return CreateCreditUseCase(ref.watch(creditRepositoryProvider));
});

/// Créditos del negocio filtrados por "mis" clientes (GET /api/clients con user_id).
/// Solo se muestran créditos cuyo clientId está en la lista de clientes del usuario.
final creditsProvider = FutureProvider<List<CreditEntity>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return [];

  final clients = await ref.watch(clientsProvider.future);
  final myClientIds = Set<String>.from(clients.map((c) => c.id));

  final useCase = ref.watch(getCreditsUseCaseProvider);
  final allCredits = await useCase(currentUser.businessId);
  return allCredits
      .where((credit) => myClientIds.contains(credit.clientId))
      .toList();
});
