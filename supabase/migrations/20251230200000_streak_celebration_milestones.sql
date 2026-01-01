-- Add celebration_milestones column to admin_streak_config
-- These are streak values that trigger celebration notifications (confetti, etc.)
-- Different from freeze_award_milestones which grant streak freezes

ALTER TABLE admin_streak_config
ADD COLUMN IF NOT EXISTS celebration_milestones INTEGER[] DEFAULT '{3,7,10,14,21,30,50,100,200,365,500}';

-- Update existing row with default values
UPDATE admin_streak_config
SET celebration_milestones = '{3,7,10,14,21,30,50,100,200,365,500}'
WHERE celebration_milestones IS NULL;

-- Add comment for documentation
COMMENT ON COLUMN admin_streak_config.celebration_milestones IS 'Streak counts that trigger celebration events (confetti, notifications). Configurable from admin panel.';
