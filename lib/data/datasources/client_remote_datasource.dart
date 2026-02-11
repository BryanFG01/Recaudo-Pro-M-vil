import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../core/config/api_config.dart';
import '../../domain/entities/client_entity.dart';
import '../models/client_model.dart';

abstract class ClientRemoteDataSource {
  /// Sube el archivo del documento y devuelve la URL pública. Endpoint: POST /api/upload (multipart).
  Future<String?> uploadDocumentFile(File file, {String? businessId});

  Future<List<ClientEntity>> getClientsByBusiness(String businessId, String userId);
  Future<ClientEntity?> getClientById(String id);
  Future<List<ClientEntity>> searchClients(String businessId, String userId, String query);
  Future<ClientEntity> createClient(
    ClientEntity client, {
    String? businessId,
    String? businessCode,
    String? userId,
    String? userNumber,
  });
  Future<ClientEntity> updateClient(ClientEntity client);
}

class ClientRemoteDataSourceImpl implements ClientRemoteDataSource {
  @override
  Future<String?> uploadDocumentFile(File file, {String? businessId}) async {
    if (!file.existsSync()) {
      throw Exception('El archivo de la foto no existe');
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('El archivo de la foto está vacío');
    }
    final uri = Uri.parse(ApiConfig.buildApiUrl('/api/upload/image'));
    final request = http.MultipartRequest('POST', uri);
    String fileName = file.path.split(RegExp(r'[/\\]')).last;
    final lower = fileName.toLowerCase();
    final bool isPng = lower.endsWith('.png');
    if (fileName.isEmpty || (!lower.endsWith('.jpg') && !lower.endsWith('.jpeg') && !isPng)) {
      fileName = 'document_${DateTime.now().millisecondsSinceEpoch}.${isPng ? 'png' : 'jpg'}';
    }
    final contentType = isPng
        ? MediaType('image', 'png')
        : MediaType('image', 'jpeg');
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: fileName,
      contentType: contentType,
    ));
    if (businessId != null && businessId.isNotEmpty) {
      request.fields['business_id'] = businessId;
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200 && response.statusCode != 201) {
      String msg = 'Error ${response.statusCode}';
      try {
        final err = jsonDecode(response.body);
        if (err is Map<String, dynamic>) {
          final m = err['message'] ?? err['error'] ?? err['detail'];
          if (m != null) msg = m is String ? m : m.toString();
        }
      } catch (_) {
        if (response.body.isNotEmpty) {
          final body = response.body.length > 120
              ? '${response.body.substring(0, 120)}...'
              : response.body;
          msg = '$msg: $body';
        }
      }
      if (kDebugMode) {
        debugPrint('Upload image failed: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      }
      throw Exception('Error al subir la foto. $msg');
    }
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;
      // La API devuelve { url }; también soportamos document_file_url y file_url
      final url = _stringFrom(raw, 'url') ??
          _stringFrom(raw, 'document_file_url') ??
          _stringFrom(raw, 'file_url');
      return url?.trim().isEmpty == true ? null : url;
    } catch (e) {
      if (e is Exception) rethrow;
      return null;
    }
  }

  static String? _stringFrom(Map<String, dynamic> map, String key) {
    final v = map[key];
    if (v == null) return null;
    if (v is String) return v.trim().isEmpty ? null : v;
    return v.toString().trim();
  }

  @override
  Future<List<ClientEntity>> getClientsByBusiness(
      String businessId, String userId) async {
    final url = ApiConfig.buildApiUrlWithQuery(
        '/api/clients/business/$businessId', {'user_id': userId});
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Error al obtener clientes: ${response.statusCode}');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => ClientModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<ClientEntity?> getClientById(String id) async {
    final url = ApiConfig.buildApiUrl('/api/clients/$id');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception('Error al obtener cliente: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ClientModel.fromJson(data);
  }

  @override
  Future<List<ClientEntity>> searchClients(
      String businessId, String userId, String query) async {
    final all = await getClientsByBusiness(businessId, userId);
    if (query.isEmpty) return all;
    final q = query.trim().toLowerCase();
    return all.where((c) {
      final name = c.name.toLowerCase();
      final doc = (c.documentId ?? '').toLowerCase();
      return name.contains(q) || doc.contains(q);
    }).toList();
  }

  @override
  Future<ClientEntity> createClient(
    ClientEntity client, {
    String? businessId,
    String? businessCode,
    String? userId,
    String? userNumber,
  }) async {
    if (businessId == null || businessCode == null || userId == null || userNumber == null) {
      throw Exception(
          'Faltan business_id, business_code, user_id o user_number para crear cliente');
    }
    final url = ApiConfig.buildApiUrl('/api/clients');
    // Body según API: name, phone, document_id, document_file_url, address, latitude, longitude,
    // business_id, business_code, user_id, user_number (sin id ni created_at).
    // No enviar null en campos opcionales: algunos backends devuelven 404 si interpretan mal la petición.
    final body = <String, dynamic>{
      'name': client.name,
      'phone': client.phone,
      'document_id': client.documentId ?? '',
      'document_file_url': client.documentFileUrl ?? '',
      'address': client.address ?? '',
      'latitude': client.latitude,
      'longitude': client.longitude,
      'business_id': businessId,
      'business_code': businessCode,
      'user_id': userId,
      'user_number': userNumber,
    };
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      String message = 'Error al crear cliente: ${response.statusCode}';
      try {
        final err = jsonDecode(response.body);
        if (err is Map<String, dynamic>) {
          final msg = err['message'] ?? err['error'] ?? err['detail'];
          if (msg != null) message = msg is String ? msg : msg.toString();
        }
      } catch (_) {
        if (response.body.isNotEmpty) message += '\n${response.body}';
      }
      // 404 al crear suele indicar que el backend no encontró usuario/negocio o sesión inválida al volver a la pantalla.
      if (response.statusCode == 404) {
        message =
            'No se pudo crear el cliente. Si acabas de volver a esta pantalla, intenta de nuevo o cierra sesión y vuelve a entrar. ($message)';
      }
      throw Exception(message);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ClientModel.fromJson(data);
  }

  @override
  Future<ClientEntity> updateClient(ClientEntity client) async {
    final url = ApiConfig.buildApiUrl('/api/clients/${client.id}');
    final model = ClientModel(
      id: client.id,
      name: client.name,
      phone: client.phone,
      documentId: client.documentId,
      documentFileUrl: client.documentFileUrl,
      address: client.address,
      latitude: client.latitude,
      longitude: client.longitude,
      createdAt: client.createdAt,
    );
    final response = await http.patch(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(model.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar cliente: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ClientModel.fromJson(data);
  }
}
