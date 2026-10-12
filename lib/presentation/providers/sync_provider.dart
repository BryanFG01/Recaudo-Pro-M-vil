import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/sync_repository_impl.dart';
import '../../domain/entities/sync_status_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/sync_repository.dart';
import 'auth_provider.dart';
import 'cash_session_provider.dart';
import 'client_provider.dart';
import 'collection_provider.dart';
import 'credit_provider.dart';
import 'payment_attempt_provider.dart';

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepositoryImpl(
    clients: ref.watch(clientRemoteDataSourceProvider),
    credits: ref.watch(creditRemoteDataSourceProvider),
    collections: ref.watch(collectionRemoteDataSourceProvider),
    paymentAttempts: ref.watch(paymentAttemptRemoteDataSourceProvider),
  );
});

/// Conexión y cola de cobros sin enviar del cobrador actual.
final syncStatusProvider = StateNotifierProvider<SyncNotifier, SyncStatusEntity>((ref) {
  final notifier = SyncNotifier(ref.watch(syncRepositoryProvider), onSynced: () {
    // Lo enviado ya está en el backend: recargar saldos, historial y caja
    ref.invalidate(creditsProvider);
    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(recentCollectionsProvider);
    ref.invalidate(paymentAttemptsProvider);
    ref.invalidate(paymentAttemptsByCreditIdProvider);
    ref.invalidate(cashSessionFlowProvider);
    ref.invalidate(cashSessionByUserProvider);
  });
  ref.listen<UserEntity?>(currentUserProvider, (_, user) => notifier.setUser(user), fireImmediately: true);
  return notifier;
});

class SyncNotifier extends StateNotifier<SyncStatusEntity> {
  /// Cada cuánto se reintenta enviar la cola (y comprobar si volvió la conexión).
  static const Duration retryEvery = Duration(minutes: 1);

  SyncNotifier(this._repository, {required void Function() onSynced})
      : _onSynced = onSynced,
        super(SyncStatusEntity(isOnline: _repository.isOnline)) {
    _subscriptions = [
      _repository.connectivity.listen(_handleConnectivity),
      _repository.queueChanges.listen((_) => _refreshQueue()),
    ];
    _timer = Timer.periodic(retryEvery, (_) => _retry());
  }

  final SyncRepository _repository;
  final void Function() _onSynced;
  late final List<StreamSubscription<Object?>> _subscriptions;
  late final Timer _timer;
  UserEntity? _user;

  void setUser(UserEntity? user) {
    final isNewUser = user?.id != _user?.id;
    _user = user;
    if (user == null) {
      state = SyncStatusEntity(isOnline: state.isOnline);
      return;
    }
    if (!isNewUser) return;
    _refreshQueue().then((_) => syncNow());
    _repository.prepareOffline(businessId: user.businessId, userId: user.id);
  }

  /// Envía ya los pendientes (también lo hace solo al volver la conexión y cada minuto).
  Future<void> syncNow() async {
    final user = _user;
    if (user == null || state.isSyncing || state.pending == 0) return;
    state = state.copyWith(isSyncing: true);
    var sent = 0;
    try {
      sent = await _repository.sync(user.id);
    } finally {
      if (mounted) state = state.copyWith(isSyncing: false);
    }
    await _refreshQueue();
    if (sent > 0 && mounted) _onSynced();
  }

  /// Quita un registro que el backend rechazó (ya revisado por el cobrador).
  Future<void> discard(String id) => _repository.discard(id);

  void _handleConnectivity(bool isOnline) {
    if (!mounted) return;
    state = state.copyWith(isOnline: isOnline);
    if (isOnline) syncNow();
  }

  Future<void> _retry() async {
    final user = _user;
    if (user == null) return;
    // Sin conexión, la precarga sirve de sondeo: si responde, vuelve el estado "en línea"
    if (!state.isOnline) await _repository.prepareOffline(businessId: user.businessId, userId: user.id);
    await syncNow();
  }

  Future<void> _refreshQueue() async {
    final user = _user;
    if (user == null) return;
    final queue = await _repository.queueOf(user.id);
    if (mounted) state = state.copyWith(pending: queue.pending, rejected: queue.rejected);
  }

  @override
  void dispose() {
    _timer.cancel();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
