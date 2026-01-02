import '../../entities/client_entity.dart';
import '../../repositories/client_repository.dart';

class SearchClientsUseCase {
  final ClientRepository repository;

  SearchClientsUseCase(this.repository);

  Future<List<ClientEntity>> call(String query) {
    return repository.searchClients(query);
  }
}

