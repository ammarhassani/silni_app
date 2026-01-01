-- =====================================================
-- Fix Profiles RLS Infinite Recursion
-- =====================================================
-- The original policy caused infinite recursion because
-- checking admin status required selecting from profiles,
-- which triggered the same policy check.
--
-- Solution: Use a SECURITY DEFINER function that bypasses RLS.
-- =====================================================

-- Drop the problematic policies
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;

-- Create a helper function to check if current user is admin
-- SECURITY DEFINER runs with the privileges of the function owner (postgres)
-- bypassing RLS for the internal query
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
DECLARE
  user_role TEXT;
BEGIN
  -- Direct table access bypasses RLS due to SECURITY DEFINER
  SELECT role INTO user_role
  FROM profiles
  WHERE id = auth.uid();

  RETURN user_role = 'admin';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Create fixed policies using the helper function
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- Now this doesn't cause recursion because is_admin() bypasses RLS
CREATE POLICY "Admins can view all profiles" ON profiles
  FOR SELECT USING (is_admin());

-- Also allow admins to update any profile (for role changes)
CREATE POLICY "Admins can update all profiles" ON profiles
  FOR UPDATE USING (is_admin());

-- =====================================================
-- Create profile for admin user if not exists
-- =====================================================

-- First, let's ensure the handle_new_user function works correctly
-- It should create a profile when a user signs up

-- Also create an upsert function for admin use
CREATE OR REPLACE FUNCTION ensure_admin_profile(user_email TEXT)
RETURNS VOID AS $$
DECLARE
  user_id UUID;
BEGIN
  -- Get user ID from auth.users
  SELECT id INTO user_id
  FROM auth.users
  WHERE email = user_email;

  IF user_id IS NULL THEN
    RAISE EXCEPTION 'User with email % not found in auth.users', user_email;
  END IF;

  -- Upsert profile with admin role
  INSERT INTO profiles (id, email, role)
  VALUES (user_id, user_email, 'admin')
  ON CONFLICT (id) DO UPDATE SET role = 'admin';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- USAGE: After running this migration, run:
-- SELECT ensure_admin_profile('azahrani337@gmail.com');
-- =====================================================
