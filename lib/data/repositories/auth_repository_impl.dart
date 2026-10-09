import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserEntity?> signInWithNumber(
      String businessId, String number, String password) async {
    final user = await remoteDataSource.signInWithNumber(number.trim(), password);
    if (user == null) return null;
    // El número existe pero en otro negocio: no se deja la sesión abierta
    if (user.businessId != businessId) {
      await remoteDataSource.signOut();
      return null;
    }
    return user;
  }

  @override
  Future<void> signOut() => remoteDataSource.signOut();

  @override
  Future<UserEntity?> getCurrentUser() => remoteDataSource.getCurrentUser();

  @override
  Stream<void> get sessionEnded => remoteDataSource.sessionEnded;

  @override
  Future<String?> getRememberedNumber() => remoteDataSource.getRememberedNumber();

  @override
  Future<void> setRememberedNumber(String? number) => remoteDataSource.setRememberedNumber(number);
}
