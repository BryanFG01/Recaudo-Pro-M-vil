import '../../entities/client_entity.dart';
import '../../repositories/client_repository.dart';

class SearchClientsUseCase {
  final ClientRepository repository;

  SearchClientsUseCase(this.repository);

  Future<List<ClientEntity>> call(
      String businessId, String userId, String query) {
    return repository.searchClients(businessId, userId, query);
  }
}

