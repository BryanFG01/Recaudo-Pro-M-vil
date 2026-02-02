import '../../entities/user_entity.dart';
import '../../repositories/auth_repository.dart';

class SignInWithNumberUseCase {
  final AuthRepository repository;

  SignInWithNumberUseCase(this.repository);

  Future<UserEntity?> call(
      String businessId, String number, String password) {
    return repository.signInWithNumber(businessId, number, password);
  }
}
