-- =====================================================
-- Fix Interaction Stats - Handle NULL types
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

  start_of_today := date_trunc('day', now());
  last_7_days := now() - interval '7 days';
  last_30_days := now() - interval '30 days';

  -- Get counts by type (coalesce NULL to 'other')
  SELECT json_object_agg(interaction_type, cnt) INTO type_counts
  FROM (
    SELECT COALESCE(type, 'other') as interaction_type, count(*) as cnt
    FROM interactions
    GROUP BY COALESCE(type, 'other')
  ) t;

  SELECT json_build_object(
    'total', (SELECT count(*) FROM interactions),
    'today', (SELECT count(*) FROM interactions WHERE created_at >= start_of_today),
    'this_week', (SELECT count(*) FROM interactions WHERE created_at >= last_7_days),
    'this_month', (SELECT count(*) FROM interactions WHERE created_at >= last_30_days),
    'by_type', COALESCE(type_counts, '{}'::json),
    'null_type_count', (SELECT count(*) FROM interactions WHERE type IS NULL),
    'distinct_types', (SELECT json_agg(DISTINCT type) FROM interactions)
  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
