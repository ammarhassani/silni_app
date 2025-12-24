-- Migration: Create AI Memories table
-- Date: 2024-12-22
-- Description: Store AI-learned facts about user and their family for context

-- AI Memories Table
CREATE TABLE IF NOT EXISTS ai_memories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category TEXT NOT NULL CHECK (category IN ('user_preference', 'relative_fact', 'family_dynamic', 'important_date', 'conversation_insight')),
  content TEXT NOT NULL,
  relative_id UUID REFERENCES relatives(id) ON DELETE CASCADE,
  importance INTEGER DEFAULT 5 CHECK (importance >= 1 AND importance <= 10),
  source_conversation_id UUID REFERENCES chat_conversations(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_ai_memories_user_id ON ai_memories(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_memories_relative_id ON ai_memories(relative_id);
CREATE INDEX IF NOT EXISTS idx_ai_memories_category ON ai_memories(category);
CREATE INDEX IF NOT EXISTS idx_ai_memories_importance ON ai_memories(importance DESC);

-- Row Level Security
ALTER TABLE ai_memories ENABLE ROW LEVEL SECURITY;

-- RLS Policies (drop if exists to make idempotent)
DROP POLICY IF EXISTS "Users can view own memories" ON ai_memories;
CREATE POLICY "Users can view own memories"
  ON ai_memories FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own memories" ON ai_memories;
CREATE POLICY "Users can insert own memories"
  ON ai_memories FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own memories" ON ai_memories;
CREATE POLICY "Users can update own memories"
  ON ai_memories FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own memories" ON ai_memories;
CREATE POLICY "Users can delete own memories"
  ON ai_memories FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- Add comments
COMMENT ON TABLE ai_memories IS 'AI-learned facts and memories about user and family';
COMMENT ON COLUMN ai_memories.category IS 'Memory type: user_preference, relative_fact, family_dynamic, important_date, conversation_insight';
COMMENT ON COLUMN ai_memories.importance IS 'Priority 1-10, higher = more important to include in context';
COMMENT ON COLUMN ai_memories.is_active IS 'Whether this memory should be used in AI context';
