-- =====================================================
-- COMPREHENSIVE FIX: Sync auth.users → profiles + users
-- =====================================================
-- Problem: handle_new_user() trigger only inserts into
-- profiles. The app's main `users` table was NEVER
-- populated by the trigger — hence only 6 old entries.
-- Also, 4 newest users are missing from profiles
-- (likely trigger errors swallowed silently).
--
-- Fix:
-- 1. Rewrite handle_new_user() to insert into BOTH tables
-- 2. Sync ALL missing auth.users → profiles
-- 3. Sync ALL missing auth.users → users
-- =====================================================

-- 1. Rewrite the trigger function to insert into BOTH tables
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert into profiles (admin panel table)
  INSERT INTO profiles (id, email, display_name, role, created_at, updated_at)
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
    email = COALESCE(EXCLUDED.email, profiles.email),
    display_name = COALESCE(EXCLUDED.display_name, profiles.display_name),
    updated_at = NOW();

  -- Insert into users (main app table)
  INSERT INTO users (id, email, full_name, created_at, last_login_at)
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
    -- Log error but don't block signup
    RAISE LOG 'handle_new_user failed for user %: % (SQLSTATE: %)', NEW.id, SQLERRM, SQLSTATE;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Recreate the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 3. Sync ALL missing auth.users → profiles
INSERT INTO profiles (id, email, display_name, role, created_at, updated_at)
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
  SELECT 1 FROM profiles p WHERE p.id = au.id
)
ON CONFLICT (id) DO NOTHING;

-- 4. Sync ALL missing auth.users → users (main app table)
INSERT INTO users (id, email, full_name, created_at, last_login_at)
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
  SELECT 1 FROM users u WHERE u.id = au.id
)
ON CONFLICT (id) DO NOTHING;

-- 5. Ensure proper permissions
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON profiles TO postgres, service_role;
GRANT ALL ON users TO postgres, service_role;
GRANT SELECT, INSERT, UPDATE ON profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE ON users TO authenticated;

-- 6. Verify counts
DO $$
DECLARE
  total_auth INTEGER;
  total_profiles INTEGER;
  total_users INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_auth FROM auth.users;
  SELECT COUNT(*) INTO total_profiles FROM profiles;
  SELECT COUNT(*) INTO total_users FROM users;
  RAISE NOTICE 'Sync complete: % auth.users, % profiles, % users', total_auth, total_profiles, total_users;
END $$;

-- =====================================================
-- After running: All 3 counts should match.
-- Future signups will auto-create in BOTH tables.
-- =====================================================
