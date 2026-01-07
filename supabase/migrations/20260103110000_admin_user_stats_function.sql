-- =====================================================
-- Admin User Stats Function
-- =====================================================
-- Creates a function that returns user statistics
-- bypassing RLS so admins can see all users
-- =====================================================

-- Create function to get user stats (bypasses RLS)
CREATE OR REPLACE FUNCTION get_admin_user_stats()
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  -- Only allow admins to call this
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied: admin role required';
  END IF;

  SELECT json_build_object(
    'auth_users', (SELECT count(*) FROM auth.users),
    'profiles', (SELECT count(*) FROM profiles),
    'admins', (SELECT count(*) FROM profiles WHERE role = 'admin'),
    'moderators', (SELECT count(*) FROM profiles WHERE role = 'moderator'),
    'regular_users', (SELECT count(*) FROM profiles WHERE role = 'user'),
    'profiles_without_role', (SELECT count(*) FROM profiles WHERE role IS NULL),
    'auth_without_profile', (
      SELECT count(*) FROM auth.users u
      LEFT JOIN profiles p ON u.id = p.id
      WHERE p.id IS NULL
    )
  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute to authenticated users (RLS check is inside the function)
GRANT EXECUTE ON FUNCTION get_admin_user_stats() TO authenticated;
