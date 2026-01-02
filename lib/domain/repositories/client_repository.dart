import '../entities/client_entity.dart';

abstract class ClientRepository {
  Future<List<ClientEntity>> getClients();
  Future<ClientEntity?> getClientById(String id);
  Future<List<ClientEntity>> searchClients(String query);
  Future<ClientEntity> createClient(ClientEntity client, {String? businessId});
  Future<ClientEntity> updateClient(ClientEntity client);
}

