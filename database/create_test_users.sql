-- ============================================
-- CREAR USUARIOS DE PRUEBA POR NEGOCIO
-- ============================================
-- Este script crea usuarios de prueba en la tabla users
-- Cada usuario pertenece a un negocio específico
-- IMPORTANTE: Después de crear el usuario aquí, debes crearlo también en Supabase Auth
-- con la misma contraseña para que el login funcione

-- Usuario para "Negocio Principal" (NEG001)
-- ID del negocio: 6fb48a52-addb-4d95-8dea-ea87485d0297
INSERT INTO public.users (
  id,
  business_id,
  email,
  name,
  employee_code,
  phone,
  role,
  commission_percentage,
  password,
  is_active,
  created_at,
  updated_at
) VALUES (
  gen_random_uuid(),
  '6fb48a52-addb-4d95-8dea-ea87485d0297', -- Negocio Principal
  'cobrador1@negocio1.com',
  'Juan Pérez',
  'COB-001',
  '3001234567',
  'cobrador',
  5.0,
  crypt('Test123456', gen_salt('bf', 10)), -- Contraseña hasheada
  true,
  NOW(),
  NOW()
) ON CONFLICT (business_id, email) 
DO UPDATE SET 
  password = crypt('Test123456', gen_salt('bf', 10)),
  updated_at = NOW();

-- Usuario admin para "Negocio Principal"
INSERT INTO public.users (
  id,
  business_id,
  email,
  name,
  employee_code,
  phone,
  role,
  commission_percentage,
  password,
  is_active,
  created_at,
  updated_at
) VALUES (
  gen_random_uuid(),
  '6fb48a52-addb-4d95-8dea-ea87485d0297', -- Negocio Principal
  'admin1@negocio1.com',
  'María Admin',
  'ADM-001',
  '3001234568',
  'admin',
  0.0,
  crypt('Test123456', gen_salt('bf', 10)), -- Contraseña hasheada
  true,
  NOW(),
  NOW()
) ON CONFLICT (business_id, email) 
DO UPDATE SET 
  password = crypt('Test123456', gen_salt('bf', 10)),
  updated_at = NOW();

-- Usuario para "Sucursal Centro" (NEG002)
-- ID del negocio: 1eff20c4-0379-4559-b992-fe730793478e
INSERT INTO public.users (
  id,
  business_id,
  email,
  name,
  employee_code,
  phone,
  role,
  commission_percentage,
  password,
  is_active,
  created_at,
  updated_at
) VALUES (
  gen_random_uuid(),
  '1eff20c4-0379-4559-b992-fe730793478e', -- Sucursal Centro
  'cobrador2@negocio2.com',
  'Carlos Rodríguez',
  'COB-001',
  '3001234569',
  'cobrador',
  5.0,
  crypt('Test123456', gen_salt('bf', 10)), -- Contraseña hasheada
  true,
  NOW(),
  NOW()
) ON CONFLICT (business_id, email) 
DO UPDATE SET 
  password = crypt('Test123456', gen_salt('bf', 10)),
  updated_at = NOW();

-- Usuario para "Sucursal Norte" (NEG003)
-- ID del negocio: a0de3e89-f641-4a77-954b-4db2c637ffca
INSERT INTO public.users (
  id,
  business_id,
  email,
  name,
  employee_code,
  phone,
  role,
  commission_percentage,
  password,
  is_active,
  created_at,
  updated_at
) VALUES (
  gen_random_uuid(),
  'a0de3e89-f641-4a77-954b-4db2c637ffca', -- Sucursal Norte
  'cobrador3@negocio3.com',
  'Ana Martínez',
  'COB-001',
  '3001234570',
  'cobrador',
  5.0,
  crypt('Test123456', gen_salt('bf', 10)), -- Contraseña hasheada
  true,
  NOW(),
  NOW()
) ON CONFLICT (business_id, email) 
DO UPDATE SET 
  password = crypt('Test123456', gen_salt('bf', 10)),
  updated_at = NOW();

-- Verificar usuarios creados
SELECT 
  u.id,
  u.email,
  u.name,
  u.employee_code,
  u.role,
  b.name as business_name,
  b.code as business_code,
  u.is_active
FROM public.users u
JOIN public.businesses b ON u.business_id = b.id
ORDER BY b.name, u.role, u.name;

-- ============================================
-- INSTRUCCIONES IMPORTANTES:
-- ============================================
-- 1. Este script crea usuarios con contraseñas hasheadas usando bcrypt
--    La contraseña por defecto es: "Test123456"
--
-- 2. Las contraseñas se almacenan hasheadas en la columna 'password' de la tabla users
--    NO necesitas crear usuarios en Supabase Auth
--
-- 3. El sistema de autenticación verifica la contraseña directamente desde la tabla users
--
-- 4. Para cambiar la contraseña de un usuario:
--    UPDATE public.users 
--    SET password = crypt('NuevaContraseña', gen_salt('bf', 10))
--    WHERE email = 'usuario@email.com';
--
-- 5. Los usuarios creados (todos con contraseña "Test123456"):
--    - cobrador1@negocio1.com (Negocio Principal)
--    - admin1@negocio1.com (Negocio Principal)
--    - cobrador2@negocio2.com (Sucursal Centro)
--    - cobrador3@negocio3.com (Sucursal Norte)
--    - test@recaudopro.com (Negocio Principal) - Ya existe con contraseña

