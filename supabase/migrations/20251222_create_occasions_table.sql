-- Migration: Create Occasions table
-- Date: 2024-12-22
-- Description: Table for tracking important dates and occasions for relatives

CREATE TABLE IF NOT EXISTS occasions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  relative_id UUID REFERENCES relatives(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'custom', -- 'birthday', 'anniversary', 'death_anniversary', 'religious', 'custom'
  date DATE NOT NULL,
  is_recurring BOOLEAN DEFAULT true, -- yearly recurrence
  reminder_days_before INTEGER DEFAULT 3, -- days before to send reminder
  notes TEXT,
  ai_reminder BOOLEAN DEFAULT true, -- whether AI should provide suggestions
  last_ai_suggestion TIMESTAMPTZ, -- when AI last provided suggestion
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_occasions_user_id ON occasions(user_id);
CREATE INDEX IF NOT EXISTS idx_occasions_relative_id ON occasions(relative_id);
CREATE INDEX IF NOT EXISTS idx_occasions_date ON occasions(date);
CREATE INDEX IF NOT EXISTS idx_occasions_type ON occasions(type);

-- RLS
ALTER TABLE occasions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own occasions"
  ON occasions FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own occasions"
  ON occasions FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own occasions"
  ON occasions FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can delete own occasions"
  ON occasions FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- Comments
COMMENT ON TABLE occasions IS 'Important dates and occasions for relatives (birthdays, anniversaries, etc.)';
COMMENT ON COLUMN occasions.type IS 'Occasion type: birthday, anniversary, death_anniversary, religious, custom';
COMMENT ON COLUMN occasions.is_recurring IS 'Whether this occasion repeats yearly';
COMMENT ON COLUMN occasions.ai_reminder IS 'Whether AI should provide gift/message suggestions';
