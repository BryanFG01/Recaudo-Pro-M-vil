import '../../core/config/supabase_config.dart';
import '../../domain/entities/client_entity.dart';
import '../models/client_model.dart';

abstract class ClientRemoteDataSource {
  Future<List<ClientEntity>> getClients();
  Future<ClientEntity?> getClientById(String id);
  Future<List<ClientEntity>> searchClients(String query);
  Future<ClientEntity> createClient(ClientEntity client, {String? businessId});
  Future<ClientEntity> updateClient(ClientEntity client);
}

class ClientRemoteDataSourceImpl implements ClientRemoteDataSource {
  @override
  Future<List<ClientEntity>> getClients() async {
    try {
      final response = await SupabaseConfig.client
          .from('clients')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ClientModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener clientes: $e');
    }
  }

  @override
  Future<ClientEntity?> getClientById(String id) async {
    try {
      final response =
          await SupabaseConfig.client
              .from('clients')
              .select()
              .eq('id', id)
              .maybeSingle();

      if (response == null) return null;
      return ClientModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al obtener cliente: $e');
    }
  }

  @override
  Future<List<ClientEntity>> searchClients(String query) async {
    try {
      final response = await SupabaseConfig.client
          .from('clients')
          .select()
          .or('name.ilike.%$query%,document_id.ilike.%$query%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ClientModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar clientes: $e');
    }
  }

  @override
  Future<ClientEntity> createClient(ClientEntity client, {String? businessId}) async {
    try {
      final clientModel = ClientModel(
        id: client.id,
        name: client.name,
        phone: client.phone,
        documentId: client.documentId,
        address: client.address,
        latitude: client.latitude,
        longitude: client.longitude,
        createdAt: client.createdAt,
      );

      final response =
          await SupabaseConfig.client
              .from('clients')
              .insert(clientModel.toJson(businessId: businessId))
              .select()
              .single();

      return ClientModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al crear cliente: $e');
    }
  }

  @override
  Future<ClientEntity> updateClient(ClientEntity client) async {
    try {
      final clientModel = ClientModel(
        id: client.id,
        name: client.name,
        phone: client.phone,
        documentId: client.documentId,
        address: client.address,
        latitude: client.latitude,
        longitude: client.longitude,
        createdAt: client.createdAt,
      );

      final response =
          await SupabaseConfig.client
              .from('clients')
              .update(clientModel.toJson())
              .eq('id', client.id)
              .select()
              .single();

      return ClientModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al actualizar cliente: $e');
    }
  }
}
