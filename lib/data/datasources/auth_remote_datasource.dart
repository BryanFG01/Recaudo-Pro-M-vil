import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';
import 'api_client.dart';
import 'session_local_datasource.dart';

const String _currentUserKey = 'recaudopro_current_user';

abstract class AuthRemoteDataSource {
  Future<UserEntity?> signInWithNumber(String number, String password);
  Future<void> signOut();
  Future<UserEntity?> getCurrentUser();
  Stream<void> get sessionEnded;
  Future<String?> getRememberedNumber();
  Future<void> setRememberedNumber(String? number);
}

/// Login por número (POST /api/users/number/{number}). Los tokens los guarda [ApiClient] en
/// almacenamiento cifrado; aquí solo se cachea el perfil del usuario (no es secreto).
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _api;
  final SessionLocalDataSource _session;

  AuthRemoteDataSourceImpl([ApiClient? api, SessionLocalDataSource? session])
      : _api = api ?? ApiClient.instance,
        _session = session ?? SessionLocalDataSource();

  @override
  Stream<void> get sessionEnded => _api.sessionEnded;

  @override
  Future<UserEntity?> signInWithNumber(String number, String password) async {
    final body = await _api.login(number.trim(), password);
    final userJson = body?['user'];
    if (userJson is! Map<String, dynamic>) return null;
    final user = UserModel.fromJson(userJson);
    await _saveCurrentUser(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    await _api.logout();
    await _clearCurrentUser();
  }

  /// Solo devuelve el usuario guardado si todavía hay sesión (refresh token).
  @override
  Future<UserEntity?> getCurrentUser() async {
    if (!await _session.hasSession()) {
      await _clearCurrentUser();
      return null;
    }
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_currentUserKey);
    if (jsonStr == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } on FormatException {
      await _clearCurrentUser();
      return null;
    }
  }

  @override
  Future<String?> getRememberedNumber() => _session.readRememberedNumber();

  @override
  Future<void> setRememberedNumber(String? number) => _session.saveRememberedNumber(number);

  Future<void> _saveCurrentUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
  }

  Future<void> _clearCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }
}
