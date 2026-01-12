-- =============================================================================
-- Fix AI Route and Create Gamification Stats View
-- =============================================================================

-- Fix 1: Remove incorrect /ai route (correct route is /ai-hub)
DELETE FROM admin_app_routes WHERE path = '/ai';

-- Fix 2: Create gamification_stats view for AI Context Engine
-- This view provides user gamification data from the users table
CREATE OR REPLACE VIEW gamification_stats AS
SELECT
  id as user_id,
  COALESCE(points, 0) as total_points,
  COALESCE(level, 1) as level,
  COALESCE(current_streak, 0) as current_streak,
  COALESCE(longest_streak, 0) as longest_streak,
  COALESCE(total_interactions, 0) as total_interactions,
  COALESCE(badges, '{}'::text[]) as badges,
  created_at,
  updated_at
FROM users;

-- Grant access
GRANT SELECT ON gamification_stats TO authenticated;
GRANT SELECT ON gamification_stats TO anon;

-- Log
DO $$
BEGIN
  RAISE NOTICE 'Migration 20260112120000: Removed /ai route and created gamification_stats view';
END $$;
