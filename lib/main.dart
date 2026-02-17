import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

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

  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2196F3),
      brightness: Brightness.light,
    ).copyWith(
      surface: const Color(0xFFF5F5F5),
      onSurface: const Color(0xFF1C1C1C),
    ),
    datePickerTheme: const DatePickerThemeData(
      backgroundColor: Color(0xFFFFFFFF),
      headerForegroundColor: Color(0xFF1C1C1C),
      dayForegroundColor: WidgetStatePropertyAll(Color(0xFF1C1C1C)),
      yearForegroundColor: WidgetStatePropertyAll(Color(0xFF1C1C1C)),
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2196F3),
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF1E1E1E),
      onSurface: const Color(0xFFFFFFFF),
    ),
    datePickerTheme: const DatePickerThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      headerForegroundColor: Color(0xFFFFFFFF),
      dayForegroundColor: WidgetStatePropertyAll(Color(0xFFFFFFFF)),
      yearForegroundColor: WidgetStatePropertyAll(Color(0xFFFFFFFF)),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'RecaudoPro',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
    );
  }
}
