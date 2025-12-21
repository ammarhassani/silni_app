-- =====================================================
-- Migration: Add last_streak_date column to users table
-- Date: 2024-12-20
-- Purpose: Enable proper streak tracking in gamification
-- =====================================================

-- Add the last_streak_date column if it doesn't exist
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_streak_date DATE;

-- Create index for efficient queries on streak date
CREATE INDEX IF NOT EXISTS idx_users_last_streak_date ON users(last_streak_date);

-- Log completion
DO $$
BEGIN
  RAISE NOTICE '✅ Migration complete: last_streak_date column added to users table';
END $$;
