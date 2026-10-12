# Formularios de privacidad de las tiendas

Respuestas según lo que hace hoy la app. Si cambia lo que se recoge (por ejemplo, si se activa Sentry), hay que actualizarlas.

## Google Play — Seguridad de los datos (Data safety)

**¿La app recoge o comparte datos de usuario?** Sí.
**¿Todos los datos se cifran en tránsito?** Sí (solo HTTPS).
**¿Los usuarios pueden pedir que se borren sus datos?** Sí: el administrador del negocio los borra desde el panel, o por solicitud al correo de la política.

| Tipo de dato (categoría de Play) | ¿Se recoge? | ¿Se comparte? | Obligatorio | Finalidad |
|---|---|---|---|---|
| Ubicación → Ubicación precisa | Sí | No | Opcional (solo al registrar al cliente) | Funcionalidad de la app |
| Información personal → Nombre | Sí | No | Sí | Funcionalidad de la app, gestión de cuentas |
| Información personal → Teléfono | Sí | No | Sí | Funcionalidad de la app |
| Información personal → Dirección | Sí | No | Sí | Funcionalidad de la app |
| Información personal → Otra información (número de documento) | Sí | No | Sí | Funcionalidad de la app |
| Información financiera → Otra información financiera (créditos, pagos, saldos) | Sí | No | Sí | Funcionalidad de la app |
| Fotos y videos → Fotos (foto del documento) | Sí | No | Opcional | Funcionalidad de la app |
| Información y rendimiento de la app → Registros de fallos | Solo si se configura `SENTRY_DSN` | No | — | Análisis (corregir fallos) |

"Compartir" en Play significa transferir a terceros. Los proveedores que procesan datos por cuenta nuestra (servidor y almacenamiento) **no** cuentan como compartir.

**Permisos que declara la app:** Internet, estado de la red, ubicación precisa y aproximada (solo mientras se usa), cámara. No usa ubicación en segundo plano.

**Otros puntos de Play Console:**
- *Acceso a la app:* da a los revisores un usuario de prueba (código de negocio, número de cobrador y contraseña) de un negocio de demostración.
- *Anuncios:* No.
- *Público objetivo:* mayores de 18 años.
- *Apps financieras:* RecaudoPro **no** presta dinero al público; es una herramienta interna de gestión de cobros para empresas. Declárala así, porque Play tiene requisitos especiales para apps de préstamos personales y revisa que la app no se presente como una.

## App Store — Etiquetas de privacidad (App Privacy)

**Datos vinculados al usuario** (todos para *App Functionality*; ninguno para seguimiento):
- Contact Info: Name, Phone Number, Physical Address.
- Identifiers: User ID.
- Financial Info: Other Financial Info.
- Location: Precise Location.
- User Content: Photos.
- Sensitive Info: número de documento (declararlo en *Other Data Types* si no encaja).

**Tracking:** No.
**Diagnostics → Crash Data:** solo si Sentry está activo (*App Functionality*, no vinculado al usuario).

`Info.plist` ya incluye los textos de permisos:
- `NSLocationWhenInUseUsageDescription` (ubicación).
- `NSCameraUsageDescription` (cámara).
- `ITSAppUsesNonExemptEncryption = false`: la app solo usa el cifrado estándar del sistema (HTTPS), así que no hace falta documentación de exportación.

**Revisión de Apple:** igual que en Play, da un usuario de demostración en *App Review Information*. Apple rechaza apps sin acceso de prueba (guía 2.1).
