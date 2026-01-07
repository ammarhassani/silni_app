-- =====================================================
-- Admin Top Users Function
-- =====================================================
-- Returns top active users bypassing RLS
-- =====================================================

CREATE OR REPLACE FUNCTION get_admin_top_users(user_limit INT DEFAULT 10)
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
      id,
      email,
      full_name,
      total_interactions,
      current_streak,
      level,
      points,
      subscription_status
    FROM users
    ORDER BY total_interactions DESC NULLS LAST
    LIMIT user_limit
  ) t;

  RETURN COALESCE(result, '[]'::json);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_admin_top_users(INT) TO authenticated;
