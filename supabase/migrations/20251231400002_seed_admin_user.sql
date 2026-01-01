-- =====================================================
-- Seed Admin User Profile
-- =====================================================
-- Creates admin profile for the primary admin user.
-- If user doesn't exist in auth.users yet, creates placeholder.
-- =====================================================

-- First, check if the user exists in auth.users and insert profile
DO $$
DECLARE
  target_email TEXT := 'azahrani337@gmail.com';
  user_id UUID;
BEGIN
  -- Try to find user in auth.users
  SELECT id INTO user_id
  FROM auth.users
  WHERE email = target_email;

  IF user_id IS NOT NULL THEN
    -- User exists, upsert profile with admin role
    INSERT INTO profiles (id, email, display_name, role, created_at, updated_at)
    VALUES (
      user_id,
      target_email,
      'Admin',
      'admin',
      NOW(),
      NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
      role = 'admin',
      updated_at = NOW();

    RAISE NOTICE 'Admin profile created/updated for user: %', target_email;
  ELSE
    RAISE NOTICE 'User % not found in auth.users. They need to sign up first.', target_email;
  END IF;
END $$;

-- Also grant execute on the helper function
GRANT EXECUTE ON FUNCTION is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION ensure_admin_profile(TEXT) TO authenticated;
