-- =====================================================
-- FIX: Trigger never fires because search_path missing
-- =====================================================
-- When auth.users fires a trigger, it runs in the auth
-- context where 'public' is NOT in the search_path.
-- The function can't find the profiles/users tables.
--
-- Fix: Add "SET search_path = public" and use fully
-- qualified table names (public.profiles, public.users).
-- This is the standard Supabase pattern for auth triggers.
-- =====================================================

-- 1. Recreate function with proper search_path
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Insert into profiles (admin panel)
  INSERT INTO public.profiles (id, email, display_name, role, created_at, updated_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    COALESCE(
      NEW.raw_user_meta_data->>'display_name',
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      NEW.email,
      'User'
    ),
    'user',
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = COALESCE(EXCLUDED.email, public.profiles.email),
    display_name = COALESCE(EXCLUDED.display_name, public.profiles.display_name),
    updated_at = NOW();

  -- Insert into users (main app table)
  INSERT INTO public.users (id, email, full_name, created_at, last_login_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    COALESCE(
      NEW.raw_user_meta_data->>'display_name',
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      NEW.email,
      'User'
    ),
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    RAISE LOG 'handle_new_user FAILED for user %: % (SQLSTATE: %)', NEW.id, SQLERRM, SQLSTATE;
    RETURN NEW;
END;
$$;

-- 2. Drop and recreate trigger with fully qualified function name
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 3. Sync the test user (and any others missing)
INSERT INTO public.profiles (id, email, display_name, role, created_at, updated_at)
SELECT
  au.id,
  COALESCE(au.email, ''),
  COALESCE(
    au.raw_user_meta_data->>'display_name',
    au.raw_user_meta_data->>'full_name',
    au.raw_user_meta_data->>'name',
    au.email,
    'User'
  ),
  'user',
  COALESCE(au.created_at, NOW()),
  NOW()
FROM auth.users au
WHERE NOT EXISTS (
  SELECT 1 FROM public.profiles p WHERE p.id = au.id
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.users (id, email, full_name, created_at, last_login_at)
SELECT
  au.id,
  COALESCE(au.email, ''),
  COALESCE(
    au.raw_user_meta_data->>'display_name',
    au.raw_user_meta_data->>'full_name',
    au.raw_user_meta_data->>'name',
    au.email,
    'User'
  ),
  COALESCE(au.created_at, NOW()),
  NOW()
FROM auth.users au
WHERE NOT EXISTS (
  SELECT 1 FROM public.users u WHERE u.id = au.id
)
ON CONFLICT (id) DO NOTHING;

-- 4. Verify
DO $$
DECLARE
  total_auth INTEGER;
  total_profiles INTEGER;
  total_users INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_auth FROM auth.users;
  SELECT COUNT(*) INTO total_profiles FROM public.profiles;
  SELECT COUNT(*) INTO total_users FROM public.users;
  RAISE NOTICE 'Sync: % auth, % profiles, % users', total_auth, total_profiles, total_users;
END $$;
