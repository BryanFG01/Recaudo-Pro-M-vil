import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Tema de la app según DESIGN.MD: superficies planas (sin sombras), radios amplios,
/// Inter para el texto y Barlow Condensed (mayúsculas) solo para titulares grandes.
class AppTheme {
  AppTheme._();

  static const double radiusCard = 24;
  static const double radiusControl = 12;

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? AppColors.carbon : AppColors.canvas;
    final surface = isDark ? const Color(0xFF1A1A1A) : AppColors.paper;
    final surfaceAlt = isDark ? AppColors.graphite : AppColors.mist;
    final text = isDark ? AppColors.paper : AppColors.carbon;
    final textMuted = isDark ? AppColors.smoke : AppColors.slate;
    final primary = isDark ? AppColors.mint : AppColors.carbon;
    final onPrimary = isDark ? AppColors.carbon : AppColors.paper;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: AppColors.mint,
      onSecondary: AppColors.carbon,
      error: AppColors.error,
      onError: AppColors.paper,
      surface: surface,
      onSurface: text,
      surfaceContainerHighest: surfaceAlt,
      onSurfaceVariant: textMuted,
      outline: isDark ? AppColors.graphite : AppColors.ash,
    );

    final baseText = GoogleFonts.interTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ).apply(bodyColor: text, displayColor: text);

    // Titulares grandes condensados (marca); el resto en Inter
    TextStyle? display(TextStyle? s) => GoogleFonts.barlowCondensed(
          textStyle: s,
          fontWeight: FontWeight.w700,
          color: text,
          height: 0.95,
        );

    final textTheme = baseText.copyWith(
      displayLarge: display(baseText.displayLarge),
      displayMedium: display(baseText.displayMedium),
      displaySmall: display(baseText.displaySmall),
      headlineLarge: display(baseText.headlineLarge),
    );

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusControl),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      dividerColor: colorScheme.outline,
      splashFactory: InkRipple.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: text,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(64, 50),
          shape: controlShape,
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size(64, 50),
          shape: controlShape,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          minimumSize: const Size(64, 50),
          side: BorderSide(color: textMuted, width: 1.5),
          shape: controlShape,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: text),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: controlShape,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        hintStyle: TextStyle(color: textMuted),
        labelStyle: TextStyle(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: BorderSide(color: text, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceAlt,
        selectedColor: AppColors.mint,
        labelStyle: GoogleFonts.inter(color: text, fontSize: 14),
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusCard)),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusCard)),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: text,
        unselectedItemColor: textMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.paper : AppColors.carbon,
        contentTextStyle: GoogleFonts.inter(
          color: isDark ? AppColors.carbon : AppColors.paper,
        ),
        behavior: SnackBarBehavior.floating,
        shape: controlShape,
        elevation: 0,
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : null,
        ),
        checkColor: WidgetStatePropertyAll(onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: text),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        headerForegroundColor: text,
        dayForegroundColor: WidgetStatePropertyAll(text),
        yearForegroundColor: WidgetStatePropertyAll(text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusCard)),
      ),
    );
  }
}
