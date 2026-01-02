import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> signInWithEmail(String businessId, String email, String password);
  Future<UserEntity?> signInWithGoogle();
  Future<UserEntity?> signInWithApple();
  Future<void> signOut();
  Future<UserEntity?> getCurrentUser();
  Future<void> resetPassword(String email);
}

