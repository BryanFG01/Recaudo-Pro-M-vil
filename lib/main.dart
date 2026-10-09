import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  try {
    await initializeDateFormatting('es');
  } catch (_) {
    // Si falla el locale (p. ej. en algún emulador), la app sigue con formato por defecto
  }
  runApp(const ProviderScope(child: RecaudoProApp()));
}

class RecaudoProApp extends ConsumerWidget {
  const RecaudoProApp({super.key});

  static final ThemeData _lightTheme = AppTheme.light();
  static final ThemeData _darkTheme = AppTheme.dark();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'RecaudoPro',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: themeMode,
      routerConfig: ref.watch(routerProvider),
      // Sincroniza el color principal adaptativo (AppColors.primary/onPrimary) con el tema activo
      builder: (context, child) {
        AppColors.syncBrightness(Theme.of(context).brightness);
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
