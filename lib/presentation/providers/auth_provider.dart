import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/auth/get_current_user_usecase.dart';
import '../../domain/usecases/auth/sign_in_with_email_usecase.dart';

// Data Sources
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl();
});

// Repositories
final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

// Use Cases
final signInWithEmailUseCaseProvider = Provider<SignInWithEmailUseCase>((ref) {
  return SignInWithEmailUseCase(ref.watch(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.watch(authRepositoryProvider));
});

// State Providers
final currentUserProvider = StateNotifierProvider<AuthNotifier, UserEntity?>((ref) {
  return AuthNotifier(ref.watch(getCurrentUserUseCaseProvider));
});

class AuthNotifier extends StateNotifier<UserEntity?> {
  final GetCurrentUserUseCase getCurrentUserUseCase;

  AuthNotifier(this.getCurrentUserUseCase) : super(null) {
    loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    state = await getCurrentUserUseCase();
  }

  void setUser(UserEntity? user) {
    state = user;
  }

  void clearUser() {
    state = null;
  }
}

