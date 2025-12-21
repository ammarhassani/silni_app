-- =====================================================
-- Migration: Convert streak system to 24h-based (Snapchat-like)
-- Date: 2024-12-20
-- Purpose: Change last_streak_date from DATE to TIMESTAMPTZ
--          and rename to last_interaction_at for clarity
-- =====================================================

-- Step 1: Alter column type from DATE to TIMESTAMPTZ
-- This preserves existing data by converting DATE to TIMESTAMPTZ at midnight
ALTER TABLE users
  ALTER COLUMN last_streak_date TYPE TIMESTAMPTZ
  USING last_streak_date::TIMESTAMPTZ;

-- Step 2: Rename column for clarity (tracks last interaction time, not just date)
ALTER TABLE users
  RENAME COLUMN last_streak_date TO last_interaction_at;

-- Step 3: Update index name to match new column name
DROP INDEX IF EXISTS idx_users_last_streak_date;
CREATE INDEX IF NOT EXISTS idx_users_last_interaction_at ON users(last_interaction_at);

-- Log completion
DO $$
BEGIN
  RAISE NOTICE '✅ Migration complete: Streak system converted to 24h-based';
  RAISE NOTICE '   - Column type changed: DATE → TIMESTAMPTZ';
  RAISE NOTICE '   - Column renamed: last_streak_date → last_interaction_at';
END $$;
