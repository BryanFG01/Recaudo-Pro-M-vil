import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/notification_cursor_local_datasource.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/app_notification_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import 'auth_provider.dart';
import 'cash_session_provider.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(NotificationRemoteDataSource(), NotificationCursorLocalDataSource());
});

/// Últimos avisos recibidos (la app los muestra en pantalla). Con la app abierta revisa cada 30 s y
/// al volver a la app; si el aviso afecta la caja, recarga saldos, retiros y gastos.
final notificationWatcherProvider =
    StateNotifierProvider<NotificationWatcher, List<AppNotificationEntity>>((ref) {
  final watcher = NotificationWatcher(ref.watch(notificationRepositoryProvider), onCashChanged: (userId) {
    ref.invalidate(dailySummaryByUserProvider(userId));
    ref.invalidate(withdrawalsByUserProvider(userId));
    ref.invalidate(cashSessionByUserProvider(userId));
    ref.invalidate(cashSessionFlowProvider);
  });
  ref.listen<UserEntity?>(currentUserProvider, (_, user) => watcher.setUser(user), fireImmediately: true);
  return watcher;
});

class NotificationWatcher extends StateNotifier<List<AppNotificationEntity>> {
  static const Duration pollEvery = Duration(seconds: 30);

  NotificationWatcher(this._repository, {required void Function(String userId) onCashChanged})
      : _onCashChanged = onCashChanged,
        super(const []) {
    _timer = Timer.periodic(pollEvery, (_) => check());
    _lifecycle = AppLifecycleListener(onResume: check);
  }

  final NotificationRepository _repository;
  final void Function(String userId) _onCashChanged;
  late final Timer _timer;
  late final AppLifecycleListener _lifecycle;
  String? _userId;
  bool _checking = false;

  void setUser(UserEntity? user) {
    _userId = user?.id;
    if (user != null) check();
  }

  /// Consulta avisos nuevos (sin conexión no hace nada).
  Future<void> check() async {
    final userId = _userId;
    if (userId == null || _checking) return;
    _checking = true;
    try {
      final incoming = await _repository.fetchNew(userId);
      if (!mounted || incoming.isEmpty) return;
      if (incoming.any((n) => n.affectsCash)) _onCashChanged(userId);
      state = incoming;
    } finally {
      _checking = false;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _lifecycle.dispose();
    super.dispose();
  }
}
