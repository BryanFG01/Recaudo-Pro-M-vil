import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/client_remote_datasource.dart';
import '../../data/repositories/client_repository_impl.dart';
import '../../domain/entities/client_entity.dart';
import '../../domain/usecases/clients/create_client_usecase.dart';
import '../../domain/usecases/clients/search_clients_usecase.dart';
import 'auth_provider.dart';

// Data Sources
final clientRemoteDataSourceProvider = Provider<ClientRemoteDataSource>((ref) {
  return ClientRemoteDataSourceImpl();
});

// Repositories
final clientRepositoryProvider = Provider<ClientRepositoryImpl>((ref) {
  return ClientRepositoryImpl(ref.watch(clientRemoteDataSourceProvider));
});

// Use Cases
final createClientUseCaseProvider = Provider<CreateClientUseCase>((ref) {
  return CreateClientUseCase(ref.watch(clientRepositoryProvider));
});

final searchClientsUseCaseProvider = Provider<SearchClientsUseCase>((ref) {
  return SearchClientsUseCase(ref.watch(clientRepositoryProvider));
});

// State Providers - Filtra clientes por business_id del usuario actual
final clientsProvider = FutureProvider<List<ClientEntity>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return [];
  }

  final repository = ref.watch(clientRepositoryProvider);
  // Los clientes ya están filtrados por business_id por RLS
  return repository.getClients();
});
