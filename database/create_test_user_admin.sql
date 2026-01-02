-- ============================================
-- CREAR USUARIO DE PRUEBA EN SUPABASE
-- ============================================
-- IMPORTANTE: Este script debe ejecutarse desde el SQL Editor 
-- del Dashboard de Supabase con permisos de administrador
-- ============================================

-- Paso 1: Crear el usuario en auth.users
DO $$
DECLARE
  new_user_id UUID := '00000000-0000-0000-0000-000000000001';
  user_email TEXT := 'test@recaudopro.com';
  user_password TEXT := 'Test123456';
  user_name TEXT := 'Usuario de Prueba';
BEGIN
  -- Insertar en auth.users (requiere permisos de service_role)
  INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    confirmation_sent_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    role,
    aud
  ) VALUES (
    new_user_id,
    '00000000-0000-0000-0000-000000000000',
    user_email,
    crypt(user_password, gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    NOW(),
    jsonb_build_object('provider', 'email', 'providers', array['email']),
    jsonb_build_object('name', user_name),
    false,
    'authenticated',
    'authenticated'
  ) ON CONFLICT (id) DO NOTHING;

  -- Insertar en auth.identities
  INSERT INTO auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    last_sign_in_at,
    created_at,
    updated_at
  ) VALUES (
    new_user_id,
    new_user_id,
    jsonb_build_object(
      'sub', new_user_id::text,
      'email', user_email
    ),
    'email',
    NOW(),
    NOW(),
    NOW()
  ) ON CONFLICT (provider, id) DO NOTHING;

  -- Insertar en public.users
  INSERT INTO public.users (id, email, name, created_at, updated_at)
  VALUES (new_user_id, user_email, user_name, NOW(), NOW())
  ON CONFLICT (id) DO UPDATE
  SET email = EXCLUDED.email, name = EXCLUDED.name, updated_at = NOW();

  RAISE NOTICE 'Usuario creado exitosamente: %', user_email;
END $$;

-- Verificar que el usuario se creó correctamente
SELECT 
  'auth.users' as tabla,
  id, 
  email, 
  email_confirmed_at,
  created_at
FROM auth.users 
WHERE email = 'test@recaudopro.com'
UNION ALL
SELECT 
  'public.users' as tabla,
  id::text,
  email,
  created_at,
  updated_at
FROM public.users 
WHERE email = 'test@recaudopro.com';

