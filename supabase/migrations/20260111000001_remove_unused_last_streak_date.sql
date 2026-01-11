-- ============================================
-- Remove last_streak_date column from users
-- This column exists in production but not staging
-- Staging is the source of truth
-- ============================================

-- Drop the index first
DROP INDEX IF EXISTS idx_users_last_streak_date;

-- Drop the column
ALTER TABLE public.users DROP COLUMN IF EXISTS last_streak_date;
