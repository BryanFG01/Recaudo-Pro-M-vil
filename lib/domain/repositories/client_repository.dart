import 'dart:io';

import '../entities/client_entity.dart';

abstract class ClientRepository {
  /// Sube el archivo del documento y devuelve la URL. Retorna null si falla.
  Future<String?> uploadDocumentFile(File file, {String? businessId});

  Future<List<ClientEntity>> getClients(String businessId, String userId);
  Future<ClientEntity?> getClientById(String id);
  Future<List<ClientEntity>> searchClients(
      String businessId, String userId, String query);
  Future<ClientEntity> createClient(
    ClientEntity client, {
    String? businessId,
    String? businessCode,
    String? userId,
    String? userNumber,
  });
  Future<ClientEntity> updateClient(ClientEntity client);
}

