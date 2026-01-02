# 🔐 Instrucciones para Crear Usuario de Prueba en Supabase

## Opción 1: Desde el Dashboard de Supabase (MÁS FÁCIL) ✅

### Paso 1: Ir a Authentication
1. Abre tu proyecto en [Supabase Dashboard](https://supabase.com/dashboard)
2. Ve a **Authentication** → **Users**
3. Click en **Add user** → **Create new user**

### Paso 2: Configurar el Usuario
```
Email: test@recaudopro.com
Password: Test123456
☑ Auto Confirm User (marcar esta opción)
```

### Paso 3: Guardar
- Click en **Create user**
- El usuario se creará automáticamente en `auth.users` y en `public.users` (gracias al trigger)

---

## Opción 2: Ejecutar SQL en el Dashboard (AVANZADO) 🔧

### Paso 1: Abrir SQL Editor
1. En Supabase Dashboard, ve a **SQL Editor**
2. Click en **+ New query**

### Paso 2: Copiar y Ejecutar
Copia el contenido del archivo `database/create_test_user_admin.sql` y ejecútalo.

### Paso 3: Verificar
Deberías ver un mensaje:
```
Usuario creado exitosamente: test@recaudopro.com
```

---

## ✅ Credenciales del Usuario de Prueba

```
Email: test@recaudopro.com
Password: Test123456
```

---

## 🔍 Verificar que Funcionó

### Desde SQL Editor:
```sql
-- Ver usuario en auth
SELECT id, email, email_confirmed_at 
FROM auth.users 
WHERE email = 'test@recaudopro.com';

-- Ver usuario en tabla pública
SELECT id, email, name 
FROM public.users 
WHERE email = 'test@recaudopro.com';
```

### Desde tu App:
1. Abre la app RecaudoPro
2. En Login, ingresa:
   - Email: `test@recaudopro.com`
   - Password: `Test123456`
3. Deberías poder iniciar sesión correctamente

---

## 🚨 Troubleshooting

### Error: "Invalid login credentials"
- **Causa**: El usuario no está confirmado
- **Solución**: Marca "Auto Confirm User" al crear o ejecuta:
  ```sql
  UPDATE auth.users 
  SET email_confirmed_at = NOW() 
  WHERE email = 'test@recaudopro.com';
  ```

### Error: "User not found in public.users"
- **Causa**: El trigger no se ejecutó
- **Solución**: Inserta manualmente:
  ```sql
  INSERT INTO public.users (id, email, name)
  SELECT id, email, 'Usuario de Prueba'
  FROM auth.users
  WHERE email = 'test@recaudopro.com'
  ON CONFLICT (id) DO NOTHING;
  ```

---

## 📊 Políticas RLS Configuradas

Ya están creadas las siguientes políticas:

### Tabla: `users`
- ✅ Los usuarios autenticados pueden ver todos los perfiles
- ✅ Los usuarios pueden actualizar su propio perfil
- ✅ Service role puede insertar usuarios

### Tabla: `clients`
- ✅ Usuarios autenticados pueden: SELECT, INSERT, UPDATE

### Tabla: `credits`
- ✅ Usuarios autenticados pueden: SELECT, INSERT, UPDATE

### Tabla: `collections`
- ✅ Usuarios autenticados pueden: SELECT, INSERT

---

## 🎯 Siguiente Paso

Una vez creado el usuario, **puedes iniciar sesión en la app** y:
1. Crear clientes
2. Crear créditos
3. Registrar recaudos
4. Ver estadísticas

**¡Todo funcionará correctamente!** 🚀

