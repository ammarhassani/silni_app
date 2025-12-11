-- ============================================
-- FIX: Add reminder_schedules table with proper relationships
-- Run this in Supabase SQL Editor
-- ============================================

-- Check if reminder_schedules table exists, create if not
CREATE TABLE IF NOT EXISTS reminder_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  relative_id uuid NOT NULL REFERENCES relatives(id) ON DELETE CASCADE,
  frequency text NOT NULL CHECK (frequency IN ('daily', 'weekly', 'monthly', 'custom')),
  notification_hour integer NOT NULL CHECK (notification_hour >= 0 AND notification_hour <= 23),
  days_of_week integer[], -- For weekly: [0,1,2,3,4,5,6] where 0=Sunday
  interval_days integer, -- For custom frequency: every N days
  custom_title text,
  custom_message text,
  is_active boolean DEFAULT true,
  last_sent timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_reminder_schedules_user_id ON reminder_schedules(user_id);
CREATE INDEX IF NOT EXISTS idx_reminder_schedules_relative_id ON reminder_schedules(relative_id);
CREATE INDEX IF NOT EXISTS idx_reminder_schedules_active_hour
  ON reminder_schedules(is_active, notification_hour)
  WHERE is_active = true;

-- Row Level Security
ALTER TABLE reminder_schedules ENABLE ROW LEVEL SECURITY;

-- Users can view their own reminder schedules
CREATE POLICY "Users can view own reminder schedules"
ON reminder_schedules
FOR SELECT
USING (auth.uid() = user_id);

-- Users can insert their own reminder schedules
CREATE POLICY "Users can insert own reminder schedules"
ON reminder_schedules
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can update their own reminder schedules
CREATE POLICY "Users can update own reminder schedules"
ON reminder_schedules
FOR UPDATE
USING (auth.uid() = user_id);

-- Users can delete their own reminder schedules
CREATE POLICY "Users can delete own reminder schedules"
ON reminder_schedules
FOR DELETE
USING (auth.uid() = user_id);

-- Auto-update trigger for updated_at
DROP TRIGGER IF EXISTS reminder_schedules_updated_at ON reminder_schedules;
CREATE TRIGGER reminder_schedules_updated_at
  BEFORE UPDATE ON reminder_schedules
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ reminder_schedules table created/updated successfully!';
  RAISE NOTICE '🔗 Foreign key to relatives table established';
  RAISE NOTICE '🔒 RLS policies enabled';
END $$;
