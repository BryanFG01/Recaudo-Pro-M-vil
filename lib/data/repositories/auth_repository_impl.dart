import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserEntity?> signInWithEmail(String businessId, String email, String password) {
    return remoteDataSource.signInWithEmail(businessId, email, password);
  }

  @override
  Future<UserEntity?> signInWithGoogle() {
    return remoteDataSource.signInWithGoogle();
  }

  @override
  Future<UserEntity?> signInWithApple() {
    return remoteDataSource.signInWithApple();
  }

  @override
  Future<void> signOut() {
    return remoteDataSource.signOut();
  }

  @override
  Future<UserEntity?> getCurrentUser() {
    return remoteDataSource.getCurrentUser();
  }

  @override
  Future<void> resetPassword(String email) {
    return remoteDataSource.resetPassword(email);
  }
}

