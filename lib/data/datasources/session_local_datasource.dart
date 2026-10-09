import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Par de tokens de la sesión (access JWT corto + refresh token que se rota en cada uso).
class SessionTokens {
  final String accessToken;
  final String refreshToken;

  const SessionTokens({required this.accessToken, required this.refreshToken});

  /// Respuesta del backend: { token, refresh_token, expires_in }.
  static SessionTokens? fromJson(Map<String, dynamic> json) {
    final access = json['token'];
    final refresh = json['refresh_token'];
    if (access is! String || refresh is! String) return null;
    return SessionTokens(accessToken: access, refreshToken: refresh);
  }
}

/// Persistencia local de la sesión. Los tokens van en almacenamiento cifrado del sistema
/// (Keychain en iOS, Keystore en Android); el número recordado (no es secreto) en preferencias.
/// Nunca se guarda la contraseña.
class SessionLocalDataSource {
  static const _accessKey = 'recaudopro_access_token';
  static const _refreshKey = 'recaudopro_refresh_token';
  static const _rememberedNumberKey = 'saved_number';
  static const _legacyPasswordKey = 'saved_password';
  static const _legacyRememberKey = 'remember_credentials';

  final FlutterSecureStorage _secure;

  SessionLocalDataSource([FlutterSecureStorage? secure])
      : _secure = secure ?? const FlutterSecureStorage();

  Future<String?> readAccessToken() => _secure.read(key: _accessKey);

  Future<String?> readRefreshToken() => _secure.read(key: _refreshKey);

  Future<bool> hasSession() async => (await readRefreshToken()) != null;

  Future<void> saveTokens(SessionTokens tokens) async {
    await _secure.write(key: _accessKey, value: tokens.accessToken);
    await _secure.write(key: _refreshKey, value: tokens.refreshToken);
  }

  Future<void> clearTokens() async {
    await _secure.delete(key: _accessKey);
    await _secure.delete(key: _refreshKey);
  }

  /// Número de usuario recordado para el próximo login (nunca la contraseña).
  Future<String?> readRememberedNumber() async {
    final prefs = await SharedPreferences.getInstance();
    await _removeLegacyPassword(prefs);
    return prefs.getString(_rememberedNumberKey);
  }

  Future<void> saveRememberedNumber(String? number) async {
    final prefs = await SharedPreferences.getInstance();
    if (number == null || number.isEmpty) {
      await prefs.remove(_rememberedNumberKey);
    } else {
      await prefs.setString(_rememberedNumberKey, number);
    }
  }

  /// Versiones anteriores guardaban la contraseña en texto plano: se borra al primer uso.
  Future<void> _removeLegacyPassword(SharedPreferences prefs) async {
    if (prefs.containsKey(_legacyPasswordKey)) await prefs.remove(_legacyPasswordKey);
    if (prefs.containsKey(_legacyRememberKey)) await prefs.remove(_legacyRememberKey);
  }
}
