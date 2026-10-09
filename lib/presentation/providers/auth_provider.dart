import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth/get_current_user_usecase.dart';
import '../../domain/usecases/auth/sign_in_with_number_usecase.dart';

// Data Sources
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl();
});

// Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

// Use Cases
final signInWithNumberUseCaseProvider =
    Provider<SignInWithNumberUseCase>((ref) {
  return SignInWithNumberUseCase(ref.watch(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.watch(authRepositoryProvider));
});

/// true cuando ya se intentó restaurar la sesión guardada al abrir la app.
final authRestoredProvider = StateProvider<bool>((ref) => false);

/// true si se volvió al login porque la sesión terminó sola (para avisar al usuario).
final sessionEndedNoticeProvider = StateProvider<bool>((ref) => false);

// State Providers
final currentUserProvider =
    StateNotifierProvider<AuthNotifier, UserEntity?>((ref) {
  return AuthNotifier(
    ref.watch(getCurrentUserUseCaseProvider),
    ref.watch(authRepositoryProvider),
    onRestored: () => ref.read(authRestoredProvider.notifier).state = true,
    onSessionEnded: () => ref.read(sessionEndedNoticeProvider.notifier).state = true,
  );
});

class AuthNotifier extends StateNotifier<UserEntity?> {
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final AuthRepository _repository;
  final void Function() _onRestored;
  final void Function() _onSessionEnded;
  late final StreamSubscription<void> _sessionEndedSubscription;

  AuthNotifier(
    this.getCurrentUserUseCase,
    this._repository, {
    required void Function() onRestored,
    required void Function() onSessionEnded,
  })  : _onRestored = onRestored,
        _onSessionEnded = onSessionEnded,
        super(null) {
    _sessionEndedSubscription = _repository.sessionEnded.listen((_) => _handleSessionEnded());
    loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    state = await getCurrentUserUseCase();
    _onRestored();
  }

  void setUser(UserEntity? user) {
    state = user;
  }

  /// Cierra la sesión en el backend y limpia el usuario.
  Future<void> signOut() async {
    await _repository.signOut();
    state = null;
  }

  void _handleSessionEnded() {
    if (state == null) return;
    state = null;
    _onSessionEnded();
  }

  @override
  void dispose() {
    _sessionEndedSubscription.cancel();
    super.dispose();
  }
}
