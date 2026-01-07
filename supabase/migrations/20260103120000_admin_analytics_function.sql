-- =====================================================
-- Admin Analytics Functions
-- =====================================================
-- Creates functions that return analytics data
-- bypassing RLS so admins can see all app data
-- =====================================================

-- Dashboard overview stats
CREATE OR REPLACE FUNCTION get_admin_dashboard_overview()
RETURNS JSON AS $$
DECLARE
  result JSON;
  start_of_today TIMESTAMPTZ;
  start_of_week TIMESTAMPTZ;
  start_of_month TIMESTAMPTZ;
BEGIN
  -- Only allow admins
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied: admin role required';
  END IF;

  start_of_today := date_trunc('day', now());
  start_of_week := date_trunc('day', now() - interval '7 days');
  start_of_month := date_trunc('month', now());

  SELECT json_build_object(
    'total_users', (SELECT count(*) FROM users),
    'new_users_today', (SELECT count(*) FROM users WHERE created_at >= start_of_today),
    'new_users_week', (SELECT count(*) FROM users WHERE created_at >= start_of_week),
    'new_users_month', (SELECT count(*) FROM users WHERE created_at >= start_of_month),
    'active_users_today', (SELECT count(*) FROM users WHERE last_interaction_at >= start_of_today),
    'active_users_week', (SELECT count(*) FROM users WHERE last_interaction_at >= start_of_week),
    'total_interactions', (SELECT count(*) FROM interactions),
    'total_relatives', (SELECT count(*) FROM relatives),
    'premium_users', (SELECT count(*) FROM users WHERE subscription_status = 'premium'),
    'free_users', (SELECT count(*) FROM users WHERE subscription_status = 'free' OR subscription_status IS NULL)
  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- User growth over time
CREATE OR REPLACE FUNCTION get_admin_user_growth(days_back INT DEFAULT 30)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied: admin role required';
  END IF;

  SELECT json_agg(row_to_json(t)) INTO result
  FROM (
    SELECT
      date_trunc('day', created_at)::date as date,
      count(*) as count
    FROM users
    WHERE created_at >= now() - (days_back || ' days')::interval
    GROUP BY date_trunc('day', created_at)
    ORDER BY date
  ) t;

  RETURN COALESCE(result, '[]'::json);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Subscription distribution
CREATE OR REPLACE FUNCTION get_admin_subscription_distribution()
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied: admin role required';
  END IF;

  SELECT json_build_object(
    'premium', (SELECT count(*) FROM users WHERE subscription_status = 'premium' AND (trial_started_at IS NULL OR trial_used = true)),
    'free', (SELECT count(*) FROM users WHERE subscription_status = 'free' OR subscription_status IS NULL),
    'trial', (SELECT count(*) FROM users WHERE subscription_status = 'premium' AND trial_started_at IS NOT NULL AND trial_used = false)
  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Interaction stats
CREATE OR REPLACE FUNCTION get_admin_interaction_stats()
RETURNS JSON AS $$
DECLARE
  result JSON;
  type_counts JSON;
  start_of_today TIMESTAMPTZ;
  start_of_week TIMESTAMPTZ;
  start_of_month TIMESTAMPTZ;
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied: admin role required';
  END IF;

  start_of_today := date_trunc('day', now());
  start_of_week := date_trunc('day', now() - interval '7 days');
  start_of_month := date_trunc('month', now());

  -- Get counts by type
  SELECT json_object_agg(type, cnt) INTO type_counts
  FROM (
    SELECT type, count(*) as cnt
    FROM interactions
    GROUP BY type
  ) t;

  SELECT json_build_object(
    'total', (SELECT count(*) FROM interactions),
    'today', (SELECT count(*) FROM interactions WHERE created_at >= start_of_today),
    'this_week', (SELECT count(*) FROM interactions WHERE created_at >= start_of_week),
    'this_month', (SELECT count(*) FROM interactions WHERE created_at >= start_of_month),
    'by_type', COALESCE(type_counts, '{}'::json)
  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Gamification stats
CREATE OR REPLACE FUNCTION get_admin_gamification_stats()
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied: admin role required';
  END IF;

  SELECT json_build_object(
    'total_points', COALESCE((SELECT sum(points) FROM users), 0),
    'avg_points', COALESCE((SELECT round(avg(points)) FROM users), 0),
    'avg_level', COALESCE((SELECT round(avg(level)::numeric, 1) FROM users), 1),
    'avg_streak', COALESCE((SELECT round(avg(current_streak)::numeric, 1) FROM users), 0),
    'max_streak', COALESCE((SELECT max(longest_streak) FROM users), 0),
    'users_with_badges', (SELECT count(*) FROM users WHERE badges IS NOT NULL AND jsonb_array_length(badges) > 0)
  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute
GRANT EXECUTE ON FUNCTION get_admin_dashboard_overview() TO authenticated;
GRANT EXECUTE ON FUNCTION get_admin_user_growth(INT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_admin_subscription_distribution() TO authenticated;
GRANT EXECUTE ON FUNCTION get_admin_interaction_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION get_admin_gamification_stats() TO authenticated;
