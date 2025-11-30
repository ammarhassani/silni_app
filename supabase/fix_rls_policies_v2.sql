-- Fixed RLS policies for user signup (v2)
-- The issue: during signup, users are in 'anon' role, not 'authenticated' yet
-- Run this in Supabase Dashboard → SQL Editor → STAGING database

-- Drop ALL existing policies on users table
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Users can insert their own profile" ON users;
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Users can delete own profile" ON users;
DROP POLICY IF EXISTS "Users can delete their own profile" ON users;

-- INSERT: Allow BOTH anon and authenticated users to insert their own profile
-- This is crucial because during signup, the user is still 'anon'
CREATE POLICY "Enable insert for users during signup"
ON users
FOR INSERT
TO anon, authenticated
WITH CHECK (auth.uid() = id);

-- SELECT: Allow authenticated users to view their own profile
CREATE POLICY "Enable select for own user"
ON users
FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- UPDATE: Allow authenticated users to update their own profile
CREATE POLICY "Enable update for own user"
ON users
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- DELETE: Allow authenticated users to delete their own profile
CREATE POLICY "Enable delete for own user"
ON users
FOR DELETE
TO authenticated
USING (auth.uid() = id);

-- Ensure RLS is enabled
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Verify the policies
SELECT
  policyname,
  cmd as command,
  roles,
  qual as using_expression,
  with_check
FROM pg_policies
WHERE tablename = 'users'
ORDER BY cmd;
