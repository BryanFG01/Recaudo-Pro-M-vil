/// Configuración de la API del backend.
/// Base URL desde .env (BASE_BACK) o valor por defecto.
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static const String _defaultBaseUrl =
      'https://recaudo-pro-back-production.up.railway.app';

  static String get baseUrl {
    try {
      final fromEnv = dotenv.env['BASE_BACK']?.trim();
      if (fromEnv != null && fromEnv.isNotEmpty) {
        return fromEnv.endsWith('/')
            ? fromEnv.substring(0, fromEnv.length - 1)
            : fromEnv;
      }
    } catch (_) {}
    return _defaultBaseUrl;
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
