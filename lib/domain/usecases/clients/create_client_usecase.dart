import '../../entities/client_entity.dart';
import '../../repositories/client_repository.dart';

class CreateClientUseCase {
  final ClientRepository repository;

  CreateClientUseCase(this.repository);

  Future<ClientEntity> call(ClientEntity client) async {
    return await repository.createClient(client);
  }
}

