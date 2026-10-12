import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/routes/app_router.dart';
import 'domain/entities/app_notification_entity.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/widgets/notification_toast.dart';
import 'presentation/widgets/offline_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  // En release no se escriben logs (pueden contener datos de clientes)
  if (kReleaseMode) debugPrint = (String? message, {int? wrapWidth}) {};
  try {
    await initializeDateFormatting('es');
  } catch (_) {
    // Si falla el locale (p. ej. en algún emulador), la app sigue con formato por defecto
  }

  void startApp() => runApp(const ProviderScope(child: RecaudoProApp()));

  // Reporte de errores: solo si SENTRY_DSN está en .env (el DSN no es un secreto)
  final sentryDsn = dotenv.env['SENTRY_DSN']?.trim() ?? '';
  if (sentryDsn.isEmpty) return startApp();
  await SentryFlutter.init(
    (options) {
      options.dsn = sentryDsn;
      options.environment = kReleaseMode ? 'production' : 'development';
      options.sendDefaultPii = false;
    },
    appRunner: startApp,
  );
}

class RecaudoProApp extends ConsumerWidget {
  const RecaudoProApp({super.key});

  static final ThemeData _lightTheme = AppTheme.light();
  static final ThemeData _darkTheme = AppTheme.dark();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    // Avisos del panel (retiro aprobado, gasto rechazado, caja cerrada...) en cualquier pantalla
    ref.listen<List<AppNotificationEntity>>(notificationWatcherProvider, (_, incoming) => showNotificationToast(incoming));
    return MaterialApp.router(
      title: 'RecaudoPro',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: appMessengerKey,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: themeMode,
      routerConfig: ref.watch(routerProvider),
      // Sincroniza el color principal adaptativo (AppColors.primary/onPrimary) con el tema activo
      builder: (context, child) {
        AppColors.syncBrightness(Theme.of(context).brightness);
        return SyncBannerLayout(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
