# Política de privacidad — RecaudoPro

> **BORRADOR.** Completa lo que está entre [corchetes] y haz que un abogado lo revise antes de publicarlo. Está pensado para Colombia (Ley 1581 de 2012 y Decreto 1377 de 2013). Play Store y App Store exigen que esta política esté en una URL pública (por ejemplo `https://recaudopro.cloud/privacidad`) y enlazada en la ficha de la app.

**Última actualización:** [fecha]

## 1. Responsable del tratamiento

[Razón social], NIT [número], con domicilio en [dirección, ciudad], correo [correo de contacto] y teléfono [teléfono], es responsable del tratamiento de los datos personales que se recogen con la aplicación móvil RecaudoPro y el panel de administración RecaudoPro (el "Servicio").

RecaudoPro es una herramienta que usan empresas de crédito (los "Negocios") para gestionar sus créditos y cobros. Cada Negocio decide qué clientes registra y para qué; frente a los datos de sus clientes, [Razón social] actúa como **encargado del tratamiento** por cuenta del Negocio.

## 2. Datos que recogemos

**Del personal del Negocio (cobradores y administradores):** nombre, número de usuario, correo (administradores), rol, contraseña (guardada solo como hash, nunca en texto plano) y registro de sesiones.

**De los clientes del Negocio, registrados por el cobrador o el administrador:**
- Identificación y contacto: nombre, número de documento, teléfono y dirección.
- Ubicación: coordenadas GPS de la dirección del cliente, tomadas por el cobrador al registrarlo.
- Foto del documento de identidad.
- Datos financieros: créditos, cuotas, pagos, intentos de cobro ("no pagó") y saldos.

**Técnicos:** dirección IP y registros del servidor por seguridad. Si el Negocio activa el reporte de errores, se envían también datos del fallo (modelo del teléfono, versión del sistema y de la app, y la traza del error) sin datos de clientes.

La app **no** usa la ubicación en segundo plano, **no** accede a contactos, mensajes ni archivos del teléfono y **no** muestra publicidad.

## 3. Para qué usamos los datos

- Prestar el Servicio: registrar clientes, créditos y cobros, calcular saldos, cuadrar la caja y generar recibos.
- Llevar al cobrador a la dirección del cliente (Waze o Google Maps, que se abren fuera de la app).
- Seguridad: autenticar usuarios, limitar intentos de acceso e investigar usos indebidos.
- Corregir fallos de la app.

No vendemos datos personales ni los usamos para publicidad.

## 4. Con quién se comparten

- **El Negocio** al que pertenece la información; cada Negocio solo ve sus propios datos.
- **Proveedores de infraestructura** que alojan el Servicio: [proveedor de servidores o nube, país], almacenamiento de archivos [proveedor] y, si está activo, reporte de errores (Sentry, Estados Unidos). Todos actúan bajo contrato y solo para prestar el Servicio.
- **Autoridades**, cuando una ley u orden judicial lo exija.

Si los datos se alojan fuera de Colombia, la transferencia se hace con las garantías del artículo 26 de la Ley 1581.

## 5. Seguridad

- Todo el tráfico va cifrado con HTTPS.
- Las contraseñas se guardan con bcrypt.
- Las sesiones del teléfono usan el almacenamiento cifrado del sistema (Keychain en iOS, Keystore en Android) y se pueden revocar desde el panel.
- Para trabajar sin señal, la app guarda en el almacenamiento privado del teléfono una copia de los datos de la ruta del cobrador. Esa copia se borra al cerrar sesión y no se incluye en las copias de seguridad del teléfono.

## 6. Conservación

Los datos se conservan mientras el Negocio tenga la cuenta activa y durante el tiempo que exijan las normas contables y comerciales ([plazo, p. ej. 10 años según el art. 28 de la Ley 962 de 2005]). Después se eliminan o se anonimizan.

## 7. Derechos de los titulares

Como titular puedes conocer, actualizar, rectificar y suprimir tus datos, revocar la autorización y presentar quejas ante la Superintendencia de Industria y Comercio. Si eres cliente de un Negocio, dirígete primero a ese Negocio; también puedes escribir a [correo de contacto]. Respondemos consultas en un plazo máximo de 10 días hábiles y reclamos en 15 días hábiles.

## 8. Menores de edad

El Servicio no está dirigido a menores de 18 años y no se deben registrar sus datos.

## 9. Cambios

Si cambiamos esta política, publicaremos la nueva versión en esta página con su fecha y, si el cambio es importante, lo avisaremos en la app.
