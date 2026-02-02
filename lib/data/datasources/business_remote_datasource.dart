import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../domain/entities/business_entity.dart';
import '../models/business_model.dart';

abstract class BusinessRemoteDataSource {
  Future<List<BusinessEntity>> getBusinesses();
  Future<List<BusinessEntity>> searchBusinesses(String query);
  Future<BusinessEntity?> getBusinessByCode(String code);
  Future<BusinessEntity?> getBusinessById(String id);
}

class BusinessRemoteDataSourceImpl implements BusinessRemoteDataSource {
  @override
  Future<List<BusinessEntity>> getBusinesses() async {
    final url = ApiConfig.buildApiUrl('/api/businesses');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Error al obtener negocios: ${response.statusCode}');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => BusinessModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<BusinessEntity>> searchBusinesses(String query) async {
    final url = ApiConfig.buildApiUrlWithQuery(
        '/api/businesses', {'search': query});
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Error al buscar negocios: ${response.statusCode}');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => BusinessModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<BusinessEntity?> getBusinessByCode(String code) async {
    final url = ApiConfig.buildApiUrlWithQuery(
        '/api/businesses', {'code': code});
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return null;
    final body = response.body;
    if (body.isEmpty) return null;
    final decoded = jsonDecode(body);
    if (decoded is List) {
      if (decoded.isEmpty) return null;
      return BusinessModel.fromJson(
          Map<String, dynamic>.from(decoded.first as Map));
    }
    return BusinessModel.fromJson(Map<String, dynamic>.from(decoded as Map));
  }

  @override
  Future<BusinessEntity?> getBusinessById(String id) async {
    final url = ApiConfig.buildApiUrl('/api/businesses/$id');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return BusinessModel.fromJson(data);
  }
}
