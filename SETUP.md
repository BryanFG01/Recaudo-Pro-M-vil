# Guía de Configuración - RecaudoPro

## Pasos para configurar el proyecto

### 1. Instalar dependencias de Flutter

```bash
flutter pub get
```

### 2. Generar archivos de código

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Configurar la base de datos en Supabase

1. Ve al panel de Supabase de tu proyecto RecaudoPro
2. Abre el SQL Editor
3. Ejecuta el script `database/schema.sql` que está en este proyecto
4. Esto creará todas las tablas necesarias con sus políticas RLS

### 4. Configurar autenticación en Supabase

1. En el panel de Supabase, ve a Authentication > Providers
2. Habilita Email/Password si no está habilitado
3. (Opcional) Configura Google y Apple OAuth si quieres usar login social

### 5. Ejecutar la aplicación

```bash
flutter run
```

## Estructura del Proyecto

```
lib/
├── core/              # Configuración y constantes
├── data/              # Capa de datos (repositorios, modelos, datasources)
├── domain/            # Capa de dominio (entidades, casos de uso, repositorios)
└── presentation/      # Capa de presentación (pantallas, widgets, providers)
```

## Características Implementadas

✅ Login con email y contraseña
✅ Dashboard principal con resumen del día
✅ Dashboard de estadísticas con gráficos
✅ Lista de créditos con búsqueda
✅ Pantalla de visita al cliente y recaudo
✅ Integración con Supabase
✅ Clean Architecture
✅ Riverpod para gestión de estado

## Próximos Pasos

- [ ] Implementar registro de usuarios
- [ ] Agregar funcionalidad de búsqueda en lista de créditos
- [ ] Implementar gráficos más avanzados
- [ ] Agregar funcionalidad de ubicación GPS
- [ ] Implementar impresión de recibos
- [ ] Agregar notificaciones push

