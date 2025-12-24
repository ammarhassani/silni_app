-- Migration: Create Family Wisdom Archive table
-- Date: 2024-12-22
-- Description: Table for storing family stories, wisdom, and heritage

CREATE TABLE IF NOT EXISTS wisdom_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  relative_id UUID REFERENCES relatives(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'story', -- 'story', 'wisdom', 'history', 'recipe', 'dua', 'tradition'
  tags TEXT[],
  audio_url TEXT, -- URL to audio recording if transcribed
  transcription_status TEXT DEFAULT 'none', -- 'none', 'pending', 'completed', 'failed'
  is_favorite BOOLEAN DEFAULT false,
  view_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_wisdom_entries_user_id ON wisdom_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_wisdom_entries_relative_id ON wisdom_entries(relative_id);
CREATE INDEX IF NOT EXISTS idx_wisdom_entries_category ON wisdom_entries(category);
CREATE INDEX IF NOT EXISTS idx_wisdom_entries_tags ON wisdom_entries USING GIN(tags);

-- RLS
ALTER TABLE wisdom_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own wisdom entries"
  ON wisdom_entries FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own wisdom entries"
  ON wisdom_entries FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own wisdom entries"
  ON wisdom_entries FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can delete own wisdom entries"
  ON wisdom_entries FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- Comments
COMMENT ON TABLE wisdom_entries IS 'Family wisdom archive for stories, advice, traditions, and heritage';
COMMENT ON COLUMN wisdom_entries.category IS 'Content type: story, wisdom, history, recipe, dua, tradition';
COMMENT ON COLUMN wisdom_entries.audio_url IS 'URL to audio recording from elder interviews';
COMMENT ON COLUMN wisdom_entries.transcription_status IS 'Status of AI transcription: none, pending, completed, failed';
