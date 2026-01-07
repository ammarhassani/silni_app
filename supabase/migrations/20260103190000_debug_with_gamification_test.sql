-- =====================================================
-- Debug Admin Stats with Gamification Test
-- =====================================================

CREATE OR REPLACE FUNCTION debug_admin_stats()
RETURNS JSON AS $$
DECLARE
  result JSON;
  current_uid UUID;
  admin_check BOOLEAN;
  profile_role TEXT;
  gamification_result JSON;
BEGIN
  -- Get current auth context
  current_uid := auth.uid();
  admin_check := is_admin();

  -- Get role from profiles
  SELECT role INTO profile_role
  FROM profiles
  WHERE id = current_uid;

  -- Test gamification stats function directly
  BEGIN
    gamification_result := get_admin_gamification_stats();
  EXCEPTION WHEN OTHERS THEN
    gamification_result := json_build_object('error', SQLERRM);
  END;

  SELECT json_build_object(
    'auth_uid', current_uid,
    'is_admin_result', admin_check,
    'profile_role', profile_role,
    'users_count', (SELECT count(*) FROM users),
    'profiles_count', (SELECT count(*) FROM profiles),
    'users_total_points', (SELECT COALESCE(sum(points), 0) FROM users),
    'gamification_stats_test', gamification_result,
    'users_sample', (
      SELECT json_agg(row_to_json(t))
      FROM (
        SELECT id, full_name, points, level
        FROM users
        ORDER BY points DESC NULLS LAST
        LIMIT 5
      ) t
    )
  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
