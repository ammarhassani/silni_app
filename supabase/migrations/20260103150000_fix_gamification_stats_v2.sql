-- =====================================================
-- Fix Gamification Stats Function V2
-- =====================================================
-- Simpler approach with direct subqueries
-- =====================================================

CREATE OR REPLACE FUNCTION get_admin_gamification_stats()
RETURNS JSON AS $$
DECLARE
  result JSON;
  user_count INT;
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied: admin role required';
  END IF;

  -- Get user count
  SELECT count(*) INTO user_count FROM users;

  -- Build result with direct subqueries for clarity
  SELECT json_build_object(
    'total_points', COALESCE((SELECT sum(COALESCE(points, 0)) FROM users), 0),
    'avg_points', CASE
      WHEN user_count > 0 THEN COALESCE((SELECT sum(COALESCE(points, 0)) FROM users), 0) / user_count
      ELSE 0
    END,
    'avg_level', CASE
      WHEN user_count > 0 THEN round((COALESCE((SELECT sum(COALESCE(level, 1)) FROM users), user_count)::numeric / user_count), 1)
      ELSE 1
    END,
    'avg_streak', CASE
      WHEN user_count > 0 THEN round((COALESCE((SELECT sum(COALESCE(current_streak, 0)) FROM users), 0)::numeric / user_count), 1)
      ELSE 0
    END,
    'max_streak', COALESCE((SELECT max(COALESCE(longest_streak, 0)) FROM users), 0),
    'users_with_badges', (SELECT count(*) FROM users WHERE badges IS NOT NULL AND jsonb_array_length(badges) > 0),
    'total_users', user_count
  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
