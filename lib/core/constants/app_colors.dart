import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (igual en ambos modos)
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF64B5F6);

  // Modo oscuro
  static const Color _backgroundDark = Color(0xFF121212);
  static const Color _surfaceDark = Color(0xFF1E1E1E);
  static const Color _surfaceLightVariantDark = Color(0xFF2C2C2C);
  static const Color _textPrimaryDark = Color(0xFFFFFFFF);
  static const Color _textSecondaryDark = Color(0xFFB0B0B0);

  // Modo claro
  static const Color _backgroundLight = Color(0xFFFAFAFA);
  static const Color _surfaceLight = Color(0xFFF5F5F5);
  static const Color _surfaceLightVariantLight = Color(0xFFEEEEEE);
  static const Color _textPrimaryLight = Color(0xFF1C1C1C);
  static const Color _textSecondaryLight = Color(0xFF616161);

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Fondo principal de la app (depende del tema)
  static Color background(BuildContext context) =>
      _isDark(context) ? _backgroundDark : _backgroundLight;

  /// Superficie de tarjetas/controles
  static Color surface(BuildContext context) =>
      _isDark(context) ? _surfaceDark : _surfaceLight;

  /// Superficie más clara (variante)
  static Color surfaceLight(BuildContext context) =>
      _isDark(context) ? _surfaceLightVariantDark : _surfaceLightVariantLight;

  /// Texto principal
  static Color textPrimary(BuildContext context) =>
      _isDark(context) ? _textPrimaryDark : _textPrimaryLight;

  /// Texto secundario
  static Color textSecondary(BuildContext context) =>
      _isDark(context) ? _textSecondaryDark : _textSecondaryLight;

  // Accent / Status (igual en ambos modos)
  static const Color accent = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color success = Color(0xFF4CAF50);
  static const Color overdue = Color(0xFFFF9800);
}

