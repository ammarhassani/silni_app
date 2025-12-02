-- =====================================================
-- Gamification RPC Functions
-- =====================================================
-- These functions handle gamification logic on the database side
-- Run this in Supabase SQL Editor after running schema.sql
-- =====================================================

-- -----------------------------------------------------
-- Award Points Function
-- -----------------------------------------------------
-- Safely updates user points and total interactions count
CREATE OR REPLACE FUNCTION award_points(
  p_user_id UUID,
  p_points INTEGER
)
RETURNS void AS $$
BEGIN
  UPDATE users
  SET
    points = points + p_points,
    total_interactions = total_interactions + 1,
    updated_at = now()
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- -----------------------------------------------------
-- Get User Gamification Stats
-- -----------------------------------------------------
-- Returns comprehensive gamification statistics for a user
CREATE OR REPLACE FUNCTION get_gamification_stats(p_user_id UUID)
RETURNS TABLE(
  total_interactions INTEGER,
  current_streak INTEGER,
  longest_streak INTEGER,
  points INTEGER,
  level INTEGER,
  badges TEXT[]
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.total_interactions,
    u.current_streak,
    u.longest_streak,
    u.points,
    u.level,
    u.badges
  FROM users u
  WHERE u.id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- -----------------------------------------------------
-- Get Leaderboard (Top Users by Points)
-- -----------------------------------------------------
-- Returns top users ranked by points (for future features)
CREATE OR REPLACE FUNCTION get_leaderboard(p_limit INTEGER DEFAULT 10)
RETURNS TABLE(
  user_id UUID,
  full_name TEXT,
  points INTEGER,
  level INTEGER,
  total_interactions INTEGER,
  current_streak INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id AS user_id,
    u.full_name,
    u.points,
    u.level,
    u.total_interactions,
    u.current_streak
  FROM users u
  ORDER BY u.points DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Completion Message
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '✅ Gamification RPC functions created successfully!';
  RAISE NOTICE '🎮 Functions: award_points, get_gamification_stats, get_leaderboard';
END $$;
