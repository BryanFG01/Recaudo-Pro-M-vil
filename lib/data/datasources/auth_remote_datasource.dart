import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/api_config.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

const String _currentUserKey = 'recaudopro_current_user';

abstract class AuthRemoteDataSource {
  Future<List<UserEntity>> getUsersByBusiness(String businessId);
  Future<UserEntity?> signInWithNumber(String number, String password);
  Future<UserEntity?> signInWithEmail(String businessId, String email, String password);
  Future<UserEntity?> signInWithGoogle();
  Future<UserEntity?> signInWithApple();
  Future<void> signOut();
  Future<UserEntity?> getCurrentUser();
  Future<void> resetPassword(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  @override
  Future<List<UserEntity>> getUsersByBusiness(String businessId) async {
    final url = ApiConfig.buildApiUrl('/api/users/business/$businessId');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Error al obtener usuarios: ${response.statusCode}');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<UserEntity?> signInWithNumber(String number, String password) async {
    final encoded = Uri.encodeComponent(number.trim());
    final url = ApiConfig.buildApiUrl('/api/users/number/$encoded');
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': password}),
    );
    if (response.statusCode != 200) {
      return null;
    }
    final raw = jsonDecode(response.body) as Map<String, dynamic>;
    // Soportar respuesta con usuario anidado en "data" o "user"
    final data = raw['data'] is Map<String, dynamic>
        ? raw['data'] as Map<String, dynamic>
        : raw['user'] is Map<String, dynamic>
            ? raw['user'] as Map<String, dynamic>
            : raw;
    final user = UserModel.fromJson(data);
    // Solo guardar sesión si el usuario está activo (is_active: true)
    if (user.isActive) {
      await _saveCurrentUser(user);
    }
    return user;
  }

  @override
  Future<UserEntity?> signInWithEmail(
      String businessId, String email, String password) async {
    final users = await getUsersByBusiness(businessId);
    final byEmail = users.cast<UserModel>().where((u) {
      final e = u.email.trim().toLowerCase();
      return e == email.trim().toLowerCase();
    }).toList();
    if (byEmail.isEmpty) return null;
    final firstUser = byEmail.first;
    final number = firstUser.number ?? firstUser.employeeCode;
    if (number == null || number.isEmpty) {
      throw Exception('Usuario sin número; no se puede iniciar sesión por API.');
    }
    return signInWithNumber(number, password);
  }

  @override
  Future<UserEntity?> signInWithGoogle() async {
    return null;
  }

  @override
  Future<UserEntity?> signInWithApple() async {
    return null;
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_currentUserKey);
    if (jsonStr == null) return null;
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    throw UnimplementedError('resetPassword no disponible con API del back');
  }

  Future<void> _saveCurrentUser(UserEntity user) async {
    final prefs = await SharedPreferences.getInstance();
    final json = (user as UserModel).toJson();
    await prefs.setString(_currentUserKey, jsonEncode(json));
  }
}
