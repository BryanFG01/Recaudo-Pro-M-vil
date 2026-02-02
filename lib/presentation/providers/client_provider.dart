import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/client_remote_datasource.dart';
import '../../data/repositories/client_repository_impl.dart';
import '../../domain/entities/client_entity.dart';
import '../../domain/usecases/clients/create_client_usecase.dart';
import '../../domain/usecases/clients/search_clients_usecase.dart';
import 'auth_provider.dart';

final clientRemoteDataSourceProvider = Provider<ClientRemoteDataSource>((ref) {
  return ClientRemoteDataSourceImpl();
});

final clientRepositoryProvider = Provider<ClientRepositoryImpl>((ref) {
  return ClientRepositoryImpl(ref.watch(clientRemoteDataSourceProvider));
});

final createClientUseCaseProvider = Provider<CreateClientUseCase>((ref) {
  return CreateClientUseCase(ref.watch(clientRepositoryProvider));
});

final searchClientsUseCaseProvider = Provider<SearchClientsUseCase>((ref) {
  return SearchClientsUseCase(ref.watch(clientRepositoryProvider));
});

final clientsProvider = FutureProvider<List<ClientEntity>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return [];

  final repository = ref.watch(clientRepositoryProvider);
  return repository.getClients(currentUser.businessId, currentUser.id);
});
