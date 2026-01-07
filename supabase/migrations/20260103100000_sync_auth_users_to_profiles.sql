-- =====================================================
-- Sync All Auth Users to Profiles
-- =====================================================
-- This migration ensures ALL auth.users have a corresponding
-- profile entry, not just new sign-ups.
--
-- Problem: Users who signed up before the handle_new_user trigger
-- was created don't have profiles, so admins can't see them.
-- =====================================================

-- Insert profiles for any auth.users that don't have one
INSERT INTO profiles (id, email, display_name, role, created_at, updated_at)
SELECT
  u.id,
  u.email,
  COALESCE(u.raw_user_meta_data->>'full_name', u.email),
  'user',  -- Default role
  u.created_at,
  NOW()
FROM auth.users u
LEFT JOIN profiles p ON u.id = p.id
WHERE p.id IS NULL;

-- Log how many were synced
DO $$
DECLARE
  synced_count INT;
BEGIN
  GET DIAGNOSTICS synced_count = ROW_COUNT;
  RAISE NOTICE 'Synced % auth users to profiles table', synced_count;
END $$;
