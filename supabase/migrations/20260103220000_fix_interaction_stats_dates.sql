-- =====================================================
-- Fix Interaction Stats - Consistent Date Calculations
-- =====================================================
-- "This week" should be last 7 days
-- "This month" should be last 30 days (not calendar month)
-- =====================================================

CREATE OR REPLACE FUNCTION get_admin_interaction_stats()
RETURNS JSON AS $$
DECLARE
  result JSON;
  type_counts JSON;
  start_of_today TIMESTAMPTZ;
  last_7_days TIMESTAMPTZ;
  last_30_days TIMESTAMPTZ;
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied: admin role required';
  END IF;

  -- Use consistent "rolling window" approach
  start_of_today := date_trunc('day', now());
  last_7_days := now() - interval '7 days';
  last_30_days := now() - interval '30 days';

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
    'this_week', (SELECT count(*) FROM interactions WHERE created_at >= last_7_days),
    'this_month', (SELECT count(*) FROM interactions WHERE created_at >= last_30_days),
    'by_type', COALESCE(type_counts, '{}'::json)
  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
