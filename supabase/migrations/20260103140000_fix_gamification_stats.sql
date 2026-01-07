-- =====================================================
-- Fix Gamification Stats Function
-- =====================================================
-- Better handling of NULL values and type casting
-- =====================================================

CREATE OR REPLACE FUNCTION get_admin_gamification_stats()
RETURNS JSON AS $$
DECLARE
  result JSON;
  total_pts BIGINT;
  avg_pts NUMERIC;
  avg_lvl NUMERIC;
  avg_strk NUMERIC;
  max_strk INT;
  badge_users INT;
  user_count INT;
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied: admin role required';
  END IF;

  -- Get user count first
  SELECT count(*) INTO user_count FROM users;

  -- Calculate stats with explicit NULL handling
  SELECT
    COALESCE(sum(COALESCE(points, 0)), 0),
    CASE WHEN user_count > 0 THEN COALESCE(sum(COALESCE(points, 0)), 0) / user_count ELSE 0 END,
    CASE WHEN user_count > 0 THEN COALESCE(sum(COALESCE(level, 1)), user_count) / user_count ELSE 1 END,
    CASE WHEN user_count > 0 THEN COALESCE(sum(COALESCE(current_streak, 0)), 0)::NUMERIC / user_count ELSE 0 END,
    COALESCE(max(COALESCE(longest_streak, 0)), 0),
    count(*) FILTER (WHERE badges IS NOT NULL AND jsonb_array_length(badges) > 0)
  INTO total_pts, avg_pts, avg_lvl, avg_strk, max_strk, badge_users
  FROM users;

  SELECT json_build_object(
    'total_points', total_pts,
    'avg_points', round(avg_pts),
    'avg_level', round(avg_lvl::numeric, 1),
    'avg_streak', round(avg_strk, 1),
    'max_streak', max_strk,
    'users_with_badges', badge_users
  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
