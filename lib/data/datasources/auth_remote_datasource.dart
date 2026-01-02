import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserEntity?> signInWithEmail(String businessId, String email, String password);
  Future<UserEntity?> signInWithGoogle();
  Future<UserEntity?> signInWithApple();
  Future<void> signOut();
  Future<UserEntity?> getCurrentUser();
  Future<void> resetPassword(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  @override
  Future<UserEntity?> signInWithEmail(String businessId, String email, String password) async {
    try {
      // Usar función RPC para autenticar (verifica business_id, email y password)
      final result = await SupabaseConfig.client.rpc(
        'authenticate_user',
        params: {
          'p_business_id': businessId,
          'p_email': email.trim(),
          'p_password': password,
        },
      );

      // Retornar el usuario autenticado
      final userList = result;
      if (userList.isEmpty) {
        // Usuario no existe, no pertenece al negocio, o contraseña incorrecta
        return null;
      }
      
      final userData = userList.first;
      return UserModel.fromJson(Map<String, dynamic>.from(userData));
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  @override
  Future<UserEntity?> signInWithGoogle() async {
    try {
      await SupabaseConfig.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.recaudopro://login-callback',
      );
      return getCurrentUser();
    } catch (e) {
      throw Exception('Error al iniciar sesión con Google: $e');
    }
  }

  @override
  Future<UserEntity?> signInWithApple() async {
    try {
      await SupabaseConfig.client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'com.recaudopro://login-callback',
      );
      return getCurrentUser();
    } catch (e) {
      throw Exception('Error al iniciar sesión con Apple: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await SupabaseConfig.client.auth.signOut();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return null;

    try {
      final userData =
          await SupabaseConfig.client
              .from('users')
              .select()
              .eq('id', user.id)
              .maybeSingle();

      if (userData == null) return null;

      return UserModel.fromJson(Map<String, dynamic>.from(userData));
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    await SupabaseConfig.client.auth.resetPasswordForEmail(email);
  }
}
