-- Leaderboard RPC: returns top users by points, streak, or level.
-- SECURITY DEFINER bypasses RLS so all users are visible,
-- but only safe columns are exposed (no email/phone).
CREATE OR REPLACE FUNCTION get_leaderboard(
  order_by TEXT DEFAULT 'points',
  result_limit INT DEFAULT 50
)
RETURNS TABLE (
  id UUID,
  full_name TEXT,
  avatar_url TEXT,
  points INT,
  current_streak INT,
  level INT,
  rank BIGINT
) AS $$
BEGIN
  IF order_by NOT IN ('points', 'current_streak', 'level') THEN
    order_by := 'points';
  END IF;

  RETURN QUERY EXECUTE format(
    'SELECT u.id, u.full_name, u.profile_picture_url AS avatar_url,
            u.points, u.current_streak, u.level,
            ROW_NUMBER() OVER (ORDER BY u.%I DESC, u.created_at ASC) AS rank
     FROM users u
     ORDER BY u.%I DESC, u.created_at ASC
     LIMIT %s',
    order_by, order_by, result_limit
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_leaderboard(TEXT, INT) TO authenticated;
