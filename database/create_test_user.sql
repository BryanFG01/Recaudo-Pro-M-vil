-- Script para crear un usuario de prueba en RecaudoPro
-- IMPORTANTE: Este script debe ejecutarse desde el panel de Supabase
-- Opción 1: Crear usuario desde el panel (RECOMENDADO)
-- 1. Ve a Authentication > Users en el panel de Supabase
-- 2. Haz clic en "Add user" o "Invite user"
-- 3. Ingresa:
--    Email: test@recaudopro.com
--    Password: Test123456
-- 4. Guarda el usuario

-- Opción 2: Crear usuario usando SQL (requiere permisos de administrador)
-- NOTA: Este método puede no funcionar dependiendo de los permisos
-- Si tienes acceso al servicio de administración, puedes ejecutar:

-- Primero, habilita la extensión pgcrypto si no está habilitada
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Función para crear usuario y sincronizar con la tabla public.users
CREATE OR REPLACE FUNCTION create_test_user()
RETURNS UUID AS $$
DECLARE
  new_user_id UUID;
  user_email TEXT := 'test@recaudopro.com';
  user_password TEXT := 'Test123456';
  user_name TEXT := 'Usuario de Prueba';
BEGIN
  -- Generar nuevo UUID
  new_user_id := gen_random_uuid();
  
  -- Insertar en auth.users
  -- NOTA: Esto requiere permisos de administrador y puede fallar
  -- La contraseña debe estar hasheada correctamente
  INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    role,
    aud,
    confirmation_token,
    recovery_token
  ) VALUES (
    new_user_id,
    '00000000-0000-0000-0000-000000000000',
    user_email,
    crypt(user_password, gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"name":"' || user_name || '"}',
    false,
    'authenticated',
    'authenticated',
    '',
    ''
  ) ON CONFLICT (id) DO NOTHING
  RETURNING id INTO new_user_id;
  
  -- Si el usuario se creó, insertar en public.users
  IF new_user_id IS NOT NULL THEN
    INSERT INTO public.users (id, email, name)
    VALUES (new_user_id, user_email, user_name)
    ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, name = EXCLUDED.name;
  END IF;
  
  RETURN new_user_id;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error al crear usuario: %', SQLERRM;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función trigger para sincronizar usuarios automáticamente
CREATE OR REPLACE FUNCTION sync_user_to_public()
RETURNS TRIGGER AS $$
BEGIN
  -- Cuando se crea un usuario en auth.users, crear el registro en public.users
  INSERT INTO public.users (id, email, name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1))
  )
  ON CONFLICT (id) DO UPDATE
  SET email = EXCLUDED.email,
      updated_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Crear trigger si no existe
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION sync_user_to_public();

-- INSTRUCCIONES PARA CREAR EL USUARIO:
-- 
-- MÉTODO RECOMENDADO (Panel de Supabase):
-- 1. Ve a: https://supabase.com/dashboard/project/zuksfgjhfdrgeoxtvvyn
-- 2. Navega a: Authentication > Users
-- 3. Haz clic en "Add user" o el botón "+"
-- 4. Completa:
--    - Email: test@recaudopro.com
--    - Password: Test123456
--    - Auto Confirm User: ✅ (marcar)
-- 5. Haz clic en "Create user"
--
-- CREDENCIALES PARA LOGIN:
-- Email: test@recaudopro.com
-- Password: Test123456

