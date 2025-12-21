-- Migration: Redesign streak system to Snapchat-style
-- Date: 2024-12-21
-- Description: Add streak_deadline and streak_day_start columns for proper Snapchat-style streaks

-- Add new columns for Snapchat-style streak tracking
ALTER TABLE users
ADD COLUMN IF NOT EXISTS streak_deadline TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS streak_day_start TIMESTAMPTZ;

-- Migrate existing data from last_interaction_at
-- streak_deadline = last_interaction_at + 24 hours (when streak would break)
-- streak_day_start = last_interaction_at (when current streak "day" started)
UPDATE users
SET
  streak_deadline = last_interaction_at + INTERVAL '24 hours',
  streak_day_start = last_interaction_at
WHERE last_interaction_at IS NOT NULL
  AND streak_deadline IS NULL;

-- Create index for efficient deadline queries (used by cron job)
CREATE INDEX IF NOT EXISTS idx_users_streak_deadline ON users(streak_deadline);

-- Add comment explaining the columns
COMMENT ON COLUMN users.streak_deadline IS 'UTC timestamp when streak will break if no interaction. Resets to now+24h on each interaction.';
COMMENT ON COLUMN users.streak_day_start IS 'UTC timestamp when current streak "day" started. Used to determine when streak increments.';
