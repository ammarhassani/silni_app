-- =====================================================
-- Fix Storage RLS Policy for Profile Pictures
-- =====================================================
-- Problem: The policy had an `OR true` clause that allowed any authenticated
-- user to view ALL profile pictures. This was overly permissive.
--
-- Analysis: This app has no user-to-user connection feature. Users track
-- their own relatives privately. Profile pictures are only used for the
-- logged-in user's own profile display, so there's no legitimate need
-- for users to view other users' profile pictures.
--
-- Solution: Restrict profile picture viewing to the owner only (same as
-- relative-photos bucket). This maintains proper data isolation.
-- =====================================================

-- Drop the existing overly permissive policy
DROP POLICY IF EXISTS "Authenticated users can view profile pictures" ON storage.objects;

-- Create new properly scoped policy for profile-pictures
-- Users can ONLY view their own profile pictures
CREATE POLICY "Users can view own profile pictures"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'profile-pictures'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- =====================================================
-- Verify: relative-photos policy is already correct
-- (from 20260101000000_security_fixes.sql)
-- Users can only view files in their own folder
-- =====================================================

-- Note: Upload/delete policies are not modified as they were already
-- correctly scoped to user's own folder in the original bucket setup.

-- =====================================================
-- Summary:
-- - Removed `OR true` that allowed viewing ALL profile pictures
-- - Profile pictures now have same restriction as relative-photos
-- - Users can only view their own files in both buckets
-- =====================================================
