-- =====================================================
-- Add interaction debug info to debug_admin_stats
-- =====================================================

CREATE OR REPLACE FUNCTION debug_admin_stats()
RETURNS JSON AS $$
DECLARE
  result JSON;
  current_uid UUID;
  admin_check BOOLEAN;
  profile_role TEXT;
  gamification_result JSON;
  interaction_debug JSON;
BEGIN
  current_uid := auth.uid();
  admin_check := is_admin();

  SELECT role INTO profile_role
  FROM profiles
  WHERE id = current_uid;

  BEGIN
    gamification_result := get_admin_gamification_stats();
  EXCEPTION WHEN OTHERS THEN
    gamification_result := json_build_object('error', SQLERRM);
  END;

  -- Get interaction type debug info
  SELECT json_build_object(
    'total_interactions', (SELECT count(*) FROM interactions),
    'null_type_count', (SELECT count(*) FROM interactions WHERE type IS NULL),
    'distinct_types', (SELECT json_agg(DISTINCT type) FROM interactions),
    'by_type', (
      SELECT json_object_agg(COALESCE(type, 'NULL'), cnt)
      FROM (
        SELECT type, count(*) as cnt
        FROM interactions
        GROUP BY type
      ) t
    )
  ) INTO interaction_debug;

  SELECT json_build_object(
    'auth_uid', current_uid,
    'is_admin_result', admin_check,
    'profile_role', profile_role,
    'users_count', (SELECT count(*) FROM users),
    'users_total_points', (SELECT COALESCE(sum(points), 0) FROM users),
    'gamification_stats_test', gamification_result,
    'interaction_debug', interaction_debug,
    'subscription_status_values', (
      SELECT json_agg(row_to_json(t))
      FROM (
        SELECT subscription_status, count(*) as cnt
        FROM users
        GROUP BY subscription_status
      ) t
    ),
    'your_subscription', (
      SELECT json_build_object(
        'subscription_status', subscription_status,
        'trial_started_at', trial_started_at,
        'trial_used', trial_used
      )
      FROM users
      WHERE id = current_uid
    ),
    'users_sample', (
      SELECT json_agg(row_to_json(t))
      FROM (
        SELECT id, full_name, points, subscription_status
        FROM users
        ORDER BY points DESC NULLS LAST
        LIMIT 5
      ) t
    )
  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
