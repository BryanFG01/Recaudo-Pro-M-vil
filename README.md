# RecaudoPro — App del cobrador (Flutter)

App móvil (Android e iOS) para el cobrador en ruta: clientes, créditos, visitas, cobros, "no pagó", caja, gastos, retiros y recibos en PDF. Habla con la API .NET (`Recaudo-Pro-Api`).

## Requisitos

- Flutter 3.41 o posterior (Dart 3).
- Android: SDK 36 y JDK 17. iOS: Xcode 16 o posterior y una cuenta de Apple Developer.

## Configuración

`.env` (se empaqueta dentro de la app; **no pongas secretos aquí**):

| Variable | Obligatoria | Uso |
|---|---|---|
| `BASE_BACK` | Sí | URL de la API. Producción: `https://api.recaudopro.cloud`. Emulador de Android contra la API local: `http://10.0.2.2:3001`. |
| `SENTRY_DSN` | No | Reporte de errores en Sentry. Vacío = desactivado. |

Sin `BASE_BACK` la app no arranca (no hay URL por defecto, para no conectarse a un backend equivocado). Ver `.env.example`.

## Desarrollo

```bash
flutter pub get
flutter run                 # en un emulador o teléfono conectado
flutter analyze             # debe quedar en "No issues found!"
flutter test
```

### Contra la API local (Docker)

Levanta `docker-compose.dev.yml` en la raíz del proyecto (la API queda en el puerto 3001) y pasa la URL al correr la app. No hace falta tocar `.env`: `--dart-define` tiene prioridad.

```bash
# Emulador de Android (10.0.2.2 es el PC visto desde el emulador)
flutter run --dart-define=BASE_BACK=http://10.0.2.2:3001

# Teléfono físico en la misma Wi-Fi que el PC (IP del PC: ipconfig → Wi-Fi)
flutter run --dart-define=BASE_BACK=http://192.168.40.8:3001
```

- Las compilaciones de debug permiten HTTP (`android/app/src/debug/res/xml/network_security_config.xml`). El release solo permite HTTPS.
- Si el teléfono no conecta, abre `http://<IP del PC>:3001/api/health` en el navegador del teléfono. Si no carga, el problema es la red: el teléfono debe estar en la misma Wi-Fi y el firewall de Windows tiene que dejar pasar a Docker.
- Usuario de prueba del seed: negocio `DEMO`, cobrador `COB001`, clave `Cobrador123*`.

## Arquitectura

Clean Architecture con Riverpod y go_router. Las reglas de código están en la skill `clean-code` del proyecto.

```
lib/
  core/           configuración, tema, constantes, utilidades
  domain/         entidades, contratos de repositorio, casos de uso, reglas puras (services/)
  data/           datasources (HTTP, almacenamiento local), modelos, repositorios
  presentation/   pantallas, widgets, providers y rutas
```

### Sesión

- Un único cliente HTTP (`lib/data/datasources/api_client.dart`). Adjunta el access token a cada petición, renueva la sesión una sola vez ante un 401 y tiene un timeout de 20 s.
- Los tokens se guardan en `flutter_secure_storage` (Keychain o Keystore). La contraseña nunca se guarda.
- Si la sesión vence o un administrador la revoca, la app vuelve al login con un aviso.

### Modo sin conexión

- **Lecturas:** cada consulta exitosa queda guardada en el teléfono. Sin señal, la app muestra lo último descargado. Un cliente o crédito que nunca se abrió con señal se busca en las listas del negocio; esas listas se descargan al iniciar sesión.
- **Cobros y "no pagó":** sin señal quedan en una cola local, con la hora real del cobro, y aparecen de inmediato en el historial. Al volver la conexión, y además cada minuto, se envían en orden. Cada registro lleva un `id` generado en el teléfono; la API lo usa para que reenviar nunca duplique un cobro.
- Si la API rechaza un registro (por ejemplo, porque el crédito se borró), el aviso superior lo muestra con el motivo para revisarlo.
- La cola sobrevive al cierre de la app y al cierre de sesión. Al cerrar sesión se borran los datos descargados, pero no los cobros pendientes.
- Crear clientes y créditos, registrar gastos o retiros y abrir o cerrar caja **requieren conexión**.

## Publicar

### Android (Play Store)

1. Crea la clave de subida (una sola vez, y guárdala con su contraseña en un lugar seguro: si se pierde no se puede actualizar la app):
   ```bash
   keytool -genkey -v -keystore ~/recaudopro-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Copia `android/key.properties.example` a `android/key.properties` y completa las rutas y contraseñas (este archivo no se sube a git).
3. Sube el número de versión en `pubspec.yaml` (`version: 1.0.1+2`; el número después de `+` debe aumentar en cada envío).
4. Genera el bundle:
   ```bash
   flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
   ```
5. En Play Console activa *Play App Signing*, sube `build/app/outputs/bundle/release/app-release.aab` y completa la ficha de *Seguridad de los datos* (ver `docs/PRIVACIDAD_Y_TIENDAS.md`).

Sin `key.properties` el release se firma con la clave de depuración: sirve para instalar en un teléfono de prueba, pero Play Store lo rechaza.

### iOS (App Store)

1. En un Mac: `flutter pub get`, `cd ios && pod install`.
2. Abre `ios/Runner.xcworkspace` en Xcode y, en *Signing & Capabilities*, elige tu *Team*. El bundle id es `com.bryan.recaudopro`, el mismo que el `applicationId` de Android.
3. `flutter build ipa --release` y súbelo con Transporter o Xcode.
4. En App Store Connect completa las etiquetas de privacidad (ver `docs/PRIVACIDAD_Y_TIENDAS.md`).

### Orden de despliegue

Primero se despliega la API y después se publica la app. La app envía el `id` de cada cobro, y una API anterior a ese cambio lo rechaza con el error `property id should not exist`.

## Documentación

- `docs/API_SESION_CAJA.md` y `docs/API_GASTOS.md`: contratos de caja y gastos.
- `docs/POLITICA_PRIVACIDAD.md`: borrador de la política de privacidad, que debe revisarse legalmente antes de publicarla.
- `docs/PRIVACIDAD_Y_TIENDAS.md`: respuestas para los formularios de privacidad de Play Store y App Store.
