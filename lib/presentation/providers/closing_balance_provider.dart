import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/closing_balance_storage.dart';
import 'auth_provider.dart';

/// Último cierre de caja guardado (caja actual del día que se cerró). Al otro día se usa como caja inicial.
final lastClosingDataProvider = FutureProvider<LastClosingData?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return getLastClosingData(user.id);
});
