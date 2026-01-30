-- =====================================================
-- URGENT: Fix Profiles Sync for Production
-- =====================================================
-- Issue: New users signing up are not being added to profiles table
-- This migration ensures the trigger exists and syncs missing users
-- =====================================================

-- 1. Ensure update_updated_at_column function exists
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Recreate the handle_new_user function with better logging
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert profile for new user
  INSERT INTO profiles (id, email, display_name, role, created_at, updated_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email, 'User'),
    'user',
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = COALESCE(EXCLUDED.email, profiles.email),
    display_name = COALESCE(EXCLUDED.display_name, profiles.display_name),
    updated_at = NOW();

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't fail signup - user can still authenticate
    RAISE LOG 'handle_new_user failed for user %: % (SQLSTATE: %)', NEW.id, SQLERRM, SQLSTATE;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Drop and recreate the trigger to ensure it's active
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 4. Add INSERT policy for service_role (needed for trigger)
DROP POLICY IF EXISTS "Service role can insert profiles" ON profiles;
CREATE POLICY "Service role can insert profiles" ON profiles
  FOR INSERT
  WITH CHECK (true);

-- 5. Grant explicit permissions
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON profiles TO postgres, service_role;
GRANT SELECT, INSERT, UPDATE ON profiles TO authenticated;

-- 6. SYNC ALL EXISTING AUTH USERS WHO ARE MISSING FROM PROFILES
-- This is the critical fix for users who already signed up but weren't synced
INSERT INTO profiles (id, email, display_name, role, created_at, updated_at)
SELECT
  au.id,
  COALESCE(au.email, ''),
  COALESCE(au.raw_user_meta_data->>'full_name', au.email, 'User'),
  'user',
  COALESCE(au.created_at, NOW()),
  NOW()
FROM auth.users au
WHERE NOT EXISTS (
  SELECT 1 FROM profiles p WHERE p.id = au.id
)
ON CONFLICT (id) DO NOTHING;

-- 7. Log how many users were synced (check Supabase logs)
DO $$
DECLARE
  total_auth_users INTEGER;
  total_profiles INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_auth_users FROM auth.users;
  SELECT COUNT(*) INTO total_profiles FROM profiles;
  RAISE NOTICE 'Sync complete: % auth users, % profiles', total_auth_users, total_profiles;
END $$;

-- =====================================================
-- After running: Check profiles table in Supabase Dashboard
-- All auth.users should now have corresponding profiles
-- =====================================================
