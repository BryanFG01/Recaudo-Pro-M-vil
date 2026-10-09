import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuración de la API del backend. La URL base sale de BASE_BACK en .env
/// (ej. https://api.recaudopro.cloud, o http://10.0.2.2:3001 para el emulador de Android en local).
class ApiConfig {
  /// Sin valor por defecto a propósito: si falta BASE_BACK es mejor un error claro que
  /// conectarse en silencio a un backend equivocado.
  static String get baseUrl {
    final fromEnv = dotenv.isInitialized ? dotenv.env['BASE_BACK']?.trim() : null;
    if (fromEnv == null || fromEnv.isEmpty) {
      throw StateError('BASE_BACK no está configurada en .env');
    }
    return fromEnv.endsWith('/') ? fromEnv.substring(0, fromEnv.length - 1) : fromEnv;
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
