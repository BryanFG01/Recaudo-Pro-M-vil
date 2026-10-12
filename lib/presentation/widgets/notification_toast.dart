import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/entities/app_notification_entity.dart';

/// Messenger de toda la app: los avisos se muestran en cualquier pantalla.
final GlobalKey<ScaffoldMessengerState> appMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Texto del aviso: el más reciente y cuántos más llegaron (función pura, con test).
String notificationToastText(List<AppNotificationEntity> incoming) {
  final latest = incoming.last;
  final more = incoming.length - 1;
  final suffix = more <= 0 ? '' : '\n+$more ${more == 1 ? 'aviso más' : 'avisos más'}';
  return '${latest.title}: ${latest.body}$suffix';
}

/// Color según el resultado: rechazado en rojo, aprobado o caja en verde.
Color notificationColor(AppNotificationEntity n) =>
    n.type.endsWith('_rejected') ? AppColors.error : AppColors.success;

void showNotificationToast(List<AppNotificationEntity> incoming) {
  if (incoming.isEmpty) return;
  appMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(notificationToastText(incoming)),
      backgroundColor: notificationColor(incoming.last),
      duration: const Duration(seconds: 6),
      behavior: SnackBarBehavior.floating,
    ));
}
