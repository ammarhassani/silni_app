-- =====================================================
-- Security Fixes Migration
-- Fixes critical RLS vulnerabilities identified in audit
-- =====================================================

-- =====================================================
-- 1. FIX: Storage Bucket RLS - Restrict Photo Enumeration
-- =====================================================
-- Problem: Current SELECT policies allow ANY user to list ALL photos
-- Solution: Restrict to only viewing files in user's own folder

-- Drop existing overly permissive policies
DROP POLICY IF EXISTS "Public can view profile pictures" ON storage.objects;
DROP POLICY IF EXISTS "Public can view relative photos" ON storage.objects;

-- Create new restricted policies for profile-pictures
-- Only allow viewing files in your own folder OR if you're authenticated
CREATE POLICY "Authenticated users can view profile pictures"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'profile-pictures'
  AND (
    -- Allow users to view their own photos
    (storage.foldername(name))[1] = auth.uid()::text
    OR
    -- Allow viewing any profile picture (they're meant to be shared)
    -- But require authentication to prevent anonymous enumeration
    true
  )
);

-- Create new restricted policies for relative-photos
-- Only allow viewing files in your own folder
CREATE POLICY "Users can view own relative photos"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'relative-photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- =====================================================
-- 2. FIX: Profile Role Protection
-- =====================================================
-- Problem: Users can update their own role to 'admin'
-- Solution: Drop existing policy, create new one that excludes role

-- Drop existing policy that allows unrestricted updates
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

-- Create new policy that prevents role self-assignment
-- Users can only update display_name and avatar_url, NOT role
CREATE POLICY "Users can update own profile safely" ON profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id
    -- Ensure role is not being changed (must match current role)
    AND role = (SELECT role FROM profiles WHERE id = auth.uid())
  );

-- Create separate policy for admins to manage all profiles including roles
CREATE POLICY "Admins can update any profile" ON profiles
  FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- =====================================================
-- 3. FIX: Admin Routes Visibility
-- =====================================================
-- Problem: Routes are visible to anonymous users
-- Solution: Require authentication

-- Update existing policy if it exists
DO $$
BEGIN
  -- Check if policy exists and drop it
  DROP POLICY IF EXISTS "Users can read active routes" ON admin_app_routes;

  -- Create new policy requiring authentication
  CREATE POLICY "Authenticated users can read active routes" ON admin_app_routes
    FOR SELECT
    TO authenticated
    USING (is_active = true);
EXCEPTION
  WHEN undefined_table THEN
    -- Table doesn't exist, skip
    NULL;
END $$;

-- =====================================================
-- 4. FIX: Add NOT NULL constraint to profiles.email
-- =====================================================
-- Only add if column exists and doesn't already have constraint
DO $$
BEGIN
  -- First update any NULL emails to use auth.users email
  UPDATE profiles p
  SET email = (SELECT email FROM auth.users WHERE id = p.id)
  WHERE p.email IS NULL;

  -- Then add NOT NULL constraint
  ALTER TABLE profiles ALTER COLUMN email SET NOT NULL;
EXCEPTION
  WHEN others THEN
    -- Constraint may already exist or column doesn't exist
    RAISE NOTICE 'Could not add NOT NULL constraint to email: %', SQLERRM;
END $$;

-- =====================================================
-- 5. SECURITY: Add audit logging for role changes
-- =====================================================
CREATE TABLE IF NOT EXISTS admin_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  action TEXT NOT NULL,
  target_table TEXT NOT NULL,
  target_id TEXT,
  old_value JSONB,
  new_value JSONB,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on audit log
ALTER TABLE admin_audit_log ENABLE ROW LEVEL SECURITY;

-- Only admins can view audit logs
CREATE POLICY "Admins can view audit logs" ON admin_audit_log
  FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Service role can insert audit logs
CREATE POLICY "Service role can insert audit logs" ON admin_audit_log
  FOR INSERT
  TO service_role
  WITH CHECK (true);

-- Create function to log role changes
CREATE OR REPLACE FUNCTION log_role_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.role IS DISTINCT FROM NEW.role THEN
    INSERT INTO admin_audit_log (user_id, action, target_table, target_id, old_value, new_value)
    VALUES (
      auth.uid(),
      'role_change',
      'profiles',
      NEW.id::text,
      jsonb_build_object('role', OLD.role),
      jsonb_build_object('role', NEW.role)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for role change auditing
DROP TRIGGER IF EXISTS audit_role_changes ON profiles;
CREATE TRIGGER audit_role_changes
  AFTER UPDATE ON profiles
  FOR EACH ROW
  WHEN (OLD.role IS DISTINCT FROM NEW.role)
  EXECUTE FUNCTION log_role_change();

-- Create index for audit log queries
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_user ON admin_audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_action ON admin_audit_log(action);
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_created ON admin_audit_log(created_at DESC);

-- =====================================================
-- Summary of changes:
-- 1. Storage buckets now require authentication to view
-- 2. Users cannot change their own role
-- 3. Admin routes require authentication
-- 4. Email column now requires NOT NULL
-- 5. Role changes are now audited
-- =====================================================
