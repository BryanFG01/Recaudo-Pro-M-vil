import 'dart:io';

import '../../domain/entities/client_entity.dart';
import '../../domain/repositories/client_repository.dart';
import '../datasources/client_remote_datasource.dart';

class ClientRepositoryImpl implements ClientRepository {
  final ClientRemoteDataSource remoteDataSource;

  ClientRepositoryImpl(this.remoteDataSource);

  @override
  Future<String?> uploadDocumentFile(File file, {String? businessId}) {
    return remoteDataSource.uploadDocumentFile(file, businessId: businessId);
  }

  @override
  Future<List<ClientEntity>> getClients(String businessId, String userId) {
    return remoteDataSource.getClientsByBusiness(businessId, userId);
  }

  @override
  Future<ClientEntity?> getClientById(String id) {
    return remoteDataSource.getClientById(id);
  }

  @override
  Future<List<ClientEntity>> searchClients(
      String businessId, String userId, String query) {
    return remoteDataSource.searchClients(businessId, userId, query);
  }

  @override
  Future<ClientEntity> createClient(
    ClientEntity client, {
    String? businessId,
    String? businessCode,
    String? userId,
    String? userNumber,
  }) {
    return remoteDataSource.createClient(
      client,
      businessId: businessId,
      businessCode: businessCode,
      userId: userId,
      userNumber: userNumber,
    );
  }

  @override
  Future<ClientEntity> updateClient(ClientEntity client) {
    return remoteDataSource.updateClient(client);
  }
}
