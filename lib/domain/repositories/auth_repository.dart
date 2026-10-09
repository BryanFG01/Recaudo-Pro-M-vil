import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Login del cobrador con su número y contraseña dentro del negocio elegido.
  /// Devuelve null si las credenciales no son válidas o el usuario es de otro negocio.
  Future<UserEntity?> signInWithNumber(
      String businessId, String number, String password);

  /// Cierra la sesión en el backend y borra los datos locales.
  Future<void> signOut();

  /// Usuario de la sesión guardada; null si no hay sesión (o ya no es válida).
  Future<UserEntity?> getCurrentUser();

  /// Emite cuando la sesión terminó sola (vencida o revocada desde el panel).
  Stream<void> get sessionEnded;

  /// Número recordado para el próximo login (la contraseña nunca se guarda).
  Future<String?> getRememberedNumber();
  Future<void> setRememberedNumber(String? number);
}
