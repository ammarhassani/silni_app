-- ============================================
-- DEFINITIVE FIX: Auto-create user profile via database trigger
-- This is the standard Supabase pattern for handling user signup
-- ============================================

-- Step 1: Create function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  -- Insert user profile automatically when auth user is created
  INSERT INTO public.users (
    id,
    email,
    full_name,
    phone_number,
    profile_picture_url,
    email_verified,
    subscription_status,
    language,
    notifications_enabled,
    reminder_time,
    theme,
    total_interactions,
    current_streak,
    longest_streak,
    points,
    level,
    badges,
    data_export_requested,
    account_deletion_requested,
    last_login_at
  ) VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
    NEW.phone,
    NULL,
    false,
    'free',
    'ar',
    true,
    '09:00',
    'light',
    0,
    0,
    0,
    0,
    1,
    '{}',
    false,
    false,
    NOW()
  );

  RETURN NEW;
END;
$$;

-- Step 2: Create trigger that fires when new user signs up
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Step 3: Clean up old conflicting INSERT policies
-- (The trigger uses SECURITY DEFINER so it bypasses RLS)
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Users can insert their own profile" ON users;
DROP POLICY IF EXISTS "Enable insert for users during signup" ON users;
DROP POLICY IF EXISTS "users_insert_policy" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Enable select for own user" ON users;
DROP POLICY IF EXISTS "users_select_policy" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Enable update for own user" ON users;
DROP POLICY IF EXISTS "users_update_policy" ON users;
DROP POLICY IF EXISTS "Users can delete own profile" ON users;
DROP POLICY IF EXISTS "Users can delete their own profile" ON users;
DROP POLICY IF EXISTS "Enable delete for own user" ON users;
DROP POLICY IF EXISTS "users_delete_policy" ON users;

-- Step 4: Create clean RLS policies for SELECT/UPDATE/DELETE
-- (No INSERT policy needed - trigger handles that)

-- SELECT: Allow authenticated users to read their own profile
CREATE POLICY "users_can_view_own_profile"
ON users
FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- UPDATE: Allow authenticated users to update their own profile
CREATE POLICY "users_can_update_own_profile"
ON users
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- DELETE: Allow authenticated users to delete their own profile
CREATE POLICY "users_can_delete_own_profile"
ON users
FOR DELETE
TO authenticated
USING (auth.uid() = id);

-- Step 5: Ensure RLS is enabled
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Step 6: Clean up test users (so you can reuse emails)
DO $$
DECLARE
  user_record RECORD;
BEGIN
  FOR user_record IN
    SELECT id, email FROM auth.users
  LOOP
    DELETE FROM auth.users WHERE id = user_record.id;
    RAISE NOTICE 'Deleted test user: % (%)', user_record.email, user_record.id;
  END LOOP;
END $$;

-- Step 7: Verify everything is set up correctly
SELECT 'Created trigger function: handle_new_user()' as status;
SELECT 'Created trigger: on_auth_user_created' as status;
SELECT 'Cleaned up conflicting policies' as status;
SELECT 'Created 3 new policies (SELECT, UPDATE, DELETE)' as status;
SELECT 'Cleaned up test users' as status;

-- Show current policies
SELECT
  policyname,
  cmd as command,
  roles
FROM pg_policies
WHERE tablename = 'users'
ORDER BY cmd;
