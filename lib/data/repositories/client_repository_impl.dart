import '../../domain/entities/client_entity.dart';
import '../../domain/repositories/client_repository.dart';
import '../datasources/client_remote_datasource.dart';

class ClientRepositoryImpl implements ClientRepository {
  final ClientRemoteDataSource remoteDataSource;

  ClientRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<ClientEntity>> getClients() {
    return remoteDataSource.getClients();
  }

  @override
  Future<ClientEntity?> getClientById(String id) {
    return remoteDataSource.getClientById(id);
  }

  @override
  Future<List<ClientEntity>> searchClients(String query) {
    return remoteDataSource.searchClients(query);
  }

  @override
  Future<ClientEntity> createClient(ClientEntity client, {String? businessId}) {
    return remoteDataSource.createClient(client, businessId: businessId);
  }

  @override
  Future<ClientEntity> updateClient(ClientEntity client) {
    return remoteDataSource.updateClient(client);
  }
}

