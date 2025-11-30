-- ============================================
-- PART 1: Check current RLS policies
-- ============================================
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual as using_check,
  with_check
FROM pg_policies
WHERE tablename = 'users';

-- ============================================
-- PART 2: Clean up test users
-- ============================================
-- Delete all test users from auth.users (this will cascade to users table)
-- Run this if you want to clean up and reuse emails
DO $$
DECLARE
  user_record RECORD;
BEGIN
  FOR user_record IN
    SELECT id FROM auth.users
  LOOP
    DELETE FROM auth.users WHERE id = user_record.id;
    RAISE NOTICE 'Deleted user: %', user_record.id;
  END LOOP;
END $$;

-- ============================================
-- PART 3: Fix RLS policies (FINAL VERSION)
-- ============================================

-- Drop ALL policies on users table
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'users') LOOP
    EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON users';
  END LOOP;
END $$;

-- Create fresh policies
-- INSERT: Allow anon users to create their profile during signup
CREATE POLICY "users_insert_policy"
ON users
FOR INSERT
TO anon, authenticated
WITH CHECK (auth.uid() = id);

-- SELECT: Allow authenticated users to read their own data
CREATE POLICY "users_select_policy"
ON users
FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- UPDATE: Allow authenticated users to update their own data
CREATE POLICY "users_update_policy"
ON users
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- DELETE: Allow authenticated users to delete their own data
CREATE POLICY "users_delete_policy"
ON users
FOR DELETE
TO authenticated
USING (auth.uid() = id);

-- Ensure RLS is enabled
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PART 4: Disable email confirmation for testing (OPTIONAL)
-- ============================================
-- This allows signup without email verification
-- Uncomment the lines below if you want to test without email confirmation:

-- UPDATE auth.config
-- SET config = jsonb_set(
--   config,
--   '{MAILER_AUTOCONFIRM}',
--   'true'
-- );

-- ============================================
-- PART 5: Verify everything
-- ============================================
SELECT 'RLS Policies on users table:' as info;
SELECT policyname, cmd, roles FROM pg_policies WHERE tablename = 'users' ORDER BY cmd;

SELECT 'Users in auth.users:' as info;
SELECT id, email, created_at FROM auth.users ORDER BY created_at DESC LIMIT 5;

SELECT 'Users in users table:' as info;
SELECT id, email, full_name, created_at FROM users ORDER BY created_at DESC LIMIT 5;
