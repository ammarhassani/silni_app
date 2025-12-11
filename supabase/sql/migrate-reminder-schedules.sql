-- ============================================
-- MIGRATE: Add missing columns to reminder_schedules table
-- Run this in Supabase SQL Editor
-- ============================================

-- Add relative_id column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'reminder_schedules'
    AND column_name = 'relative_id'
  ) THEN
    ALTER TABLE reminder_schedules
    ADD COLUMN relative_id uuid REFERENCES relatives(id) ON DELETE CASCADE;

    RAISE NOTICE '✅ Added relative_id column';
  ELSE
    RAISE NOTICE 'ℹ️ relative_id column already exists';
  END IF;
END $$;

-- Add other potentially missing columns
DO $$
BEGIN
  -- Add frequency column if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'reminder_schedules' AND column_name = 'frequency'
  ) THEN
    ALTER TABLE reminder_schedules
    ADD COLUMN frequency text CHECK (frequency IN ('daily', 'weekly', 'monthly', 'custom'));
    RAISE NOTICE '✅ Added frequency column';
  END IF;

  -- Add notification_hour column if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'reminder_schedules' AND column_name = 'notification_hour'
  ) THEN
    ALTER TABLE reminder_schedules
    ADD COLUMN notification_hour integer CHECK (notification_hour >= 0 AND notification_hour <= 23);
    RAISE NOTICE '✅ Added notification_hour column';
  END IF;

  -- Add days_of_week column if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'reminder_schedules' AND column_name = 'days_of_week'
  ) THEN
    ALTER TABLE reminder_schedules ADD COLUMN days_of_week integer[];
    RAISE NOTICE '✅ Added days_of_week column';
  END IF;

  -- Add interval_days column if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'reminder_schedules' AND column_name = 'interval_days'
  ) THEN
    ALTER TABLE reminder_schedules ADD COLUMN interval_days integer;
    RAISE NOTICE '✅ Added interval_days column';
  END IF;

  -- Add custom_title column if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'reminder_schedules' AND column_name = 'custom_title'
  ) THEN
    ALTER TABLE reminder_schedules ADD COLUMN custom_title text;
    RAISE NOTICE '✅ Added custom_title column';
  END IF;

  -- Add custom_message column if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'reminder_schedules' AND column_name = 'custom_message'
  ) THEN
    ALTER TABLE reminder_schedules ADD COLUMN custom_message text;
    RAISE NOTICE '✅ Added custom_message column';
  END IF;

  -- Add is_active column if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'reminder_schedules' AND column_name = 'is_active'
  ) THEN
    ALTER TABLE reminder_schedules ADD COLUMN is_active boolean DEFAULT true;
    RAISE NOTICE '✅ Added is_active column';
  END IF;

  -- Add last_sent column if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'reminder_schedules' AND column_name = 'last_sent'
  ) THEN
    ALTER TABLE reminder_schedules ADD COLUMN last_sent timestamptz;
    RAISE NOTICE '✅ Added last_sent column';
  END IF;
END $$;

-- Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_reminder_schedules_user_id ON reminder_schedules(user_id);
CREATE INDEX IF NOT EXISTS idx_reminder_schedules_relative_id ON reminder_schedules(relative_id);
CREATE INDEX IF NOT EXISTS idx_reminder_schedules_active_hour
  ON reminder_schedules(is_active, notification_hour)
  WHERE is_active = true;

-- Enable RLS if not already enabled
ALTER TABLE reminder_schedules ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can view own reminder schedules" ON reminder_schedules;
DROP POLICY IF EXISTS "Users can insert own reminder schedules" ON reminder_schedules;
DROP POLICY IF EXISTS "Users can update own reminder schedules" ON reminder_schedules;
DROP POLICY IF EXISTS "Users can delete own reminder schedules" ON reminder_schedules;

-- Create RLS policies
CREATE POLICY "Users can view own reminder schedules"
ON reminder_schedules FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own reminder schedules"
ON reminder_schedules FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own reminder schedules"
ON reminder_schedules FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own reminder schedules"
ON reminder_schedules FOR DELETE
USING (auth.uid() = user_id);

-- Create or replace trigger for updated_at
DROP TRIGGER IF EXISTS reminder_schedules_updated_at ON reminder_schedules;
CREATE TRIGGER reminder_schedules_updated_at
  BEFORE UPDATE ON reminder_schedules
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- Final success message
DO $$
BEGIN
  RAISE NOTICE '🎉 Migration complete!';
  RAISE NOTICE '✅ reminder_schedules table updated with all required columns';
  RAISE NOTICE '🔗 Foreign key to relatives table established';
  RAISE NOTICE '🔒 RLS policies configured';
END $$;
