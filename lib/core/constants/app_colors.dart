import 'package:flutter/material.dart';

/// Paleta de RecaudoPro (misma guía que la web y el panel Admin: ver DESIGN.MD).
/// Monocromo plano + acento mint. Los colores de estado (éxito, error, alerta)
/// se mantienen porque comunican información financiera.
class AppColors {
  AppColors._();

  // ─── Paleta base ───────────────────────────────────────────────────────────
  static const Color carbon = Color(0xFF000000);
  static const Color paper = Color(0xFFFFFFFF);
  static const Color canvas = Color(0xFFE5E5E5);
  static const Color mist = Color(0xFFF3F3F3);
  static const Color ash = Color(0xFFC6C6C6);
  static const Color smoke = Color(0xFF979797);
  static const Color slate = Color(0xFF444444);
  static const Color graphite = Color(0xFF2F2F2F);
  static const Color mint = Color(0xFFD1FFCA);
  static const Color voltage = Color(0xFFFFF100);

  // Superficies del modo oscuro
  static const Color _darkBackground = Color(0xFF000000);
  static const Color _darkSurface = Color(0xFF1A1A1A);

  // ─── Tema activo ───────────────────────────────────────────────────────────
  /// La app lo sincroniza en cada build de MaterialApp (ver main.dart),
  /// para que [primary] y [onPrimary] se adapten sin necesitar BuildContext.
  static Brightness _brightness = Brightness.dark;

  static void syncBrightness(Brightness brightness) => _brightness = brightness;

  static bool get _isDarkMode => _brightness == Brightness.dark;

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // ─── Color principal ──────────────────────────────────────────────────────
  /// Acción principal: negro en modo claro, mint en modo oscuro.
  static Color get primary => _isDarkMode ? mint : carbon;

  /// Texto/icono que va SOBRE [primary] (botones, chips, banners).
  static Color get onPrimary => _isDarkMode ? carbon : paper;

  // ─── Superficies y texto (dependen del tema) ───────────────────────────────
  /// Fondo de pantalla: gris canvas en claro, negro en oscuro.
  static Color background(BuildContext context) =>
      _isDark(context) ? _darkBackground : canvas;

  /// Tarjetas y paneles.
  static Color surface(BuildContext context) =>
      _isDark(context) ? _darkSurface : paper;

  /// Superficie secundaria (inputs, filas, chips neutros).
  static Color surfaceLight(BuildContext context) =>
      _isDark(context) ? graphite : mist;

  static Color textPrimary(BuildContext context) =>
      _isDark(context) ? paper : carbon;

  static Color textSecondary(BuildContext context) =>
      _isDark(context) ? smoke : slate;

  /// Líneas divisorias finas.
  static Color divider(BuildContext context) =>
      _isDark(context) ? graphite : ash;

  // ─── Estados (iguales en ambos temas) ──────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);
  static const Color overdue = warning;
  static const Color accent = success;
}
