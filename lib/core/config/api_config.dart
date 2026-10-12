import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuración de la API del backend. La URL base sale de BASE_BACK en .env
/// (ej. https://api.recaudopro.cloud).
///
/// Para probar contra la API local sin tocar .env:
/// `flutter run --dart-define=BASE_BACK=http://10.0.2.2:3001` (emulador) o la IP del PC en la
/// Wi-Fi para un teléfono físico (ej. http://192.168.40.8:3001).
class ApiConfig {
  /// BASE_BACK pasada con --dart-define al compilar (tiene prioridad sobre .env).
  static const String _compiledBaseUrl = String.fromEnvironment('BASE_BACK');

  /// Sin valor por defecto a propósito: si falta BASE_BACK es mejor un error claro que
  /// conectarse en silencio a un backend equivocado.
  static String get baseUrl => resolveBaseUrl(
        compiled: _compiledBaseUrl,
        fromEnv: dotenv.isInitialized ? dotenv.env['BASE_BACK'] : null,
      );

  /// Regla pura: primero --dart-define, después .env; sin barra final.
  static String resolveBaseUrl({String? compiled, String? fromEnv}) {
    final candidates = [compiled?.trim(), fromEnv?.trim()];
    final url = candidates.firstWhere((u) => u != null && u.isNotEmpty, orElse: () => null);
    if (url == null) throw StateError('BASE_BACK no está configurada en .env');
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Arma la URL final para un endpoint (sin query string).
  /// [endpoint] debe empezar con / (ej: /api/users/business/123).
  static String buildApiUrl(String endpoint) {
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$baseUrl$path';
  }

  /// Arma la URL con query parameters.
  static String buildApiUrlWithQuery(String endpoint, Map<String, String> queryParams) {
    final base = buildApiUrl(endpoint);
    if (queryParams.isEmpty) return base;
    final query = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return '$base?$query';
  }
}
