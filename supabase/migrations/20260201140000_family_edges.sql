-- Family graph edges for relationship structure
-- Part of Task 8: Family Tree Graph Restructure
--
-- Stores directed edges between family members:
--   parent_of  : fromId is a parent of toId
--   sibling_of : fromId is a sibling of toId
--   spouse_of  : fromId is a spouse of toId
--
-- Scoped to user_id (each user owns their own graph).
-- No foreign key to family_groups — that table is created in Task 10.

CREATE TABLE IF NOT EXISTS family_edges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  from_id TEXT NOT NULL,
  to_id TEXT NOT NULL,
  edge_type TEXT NOT NULL CHECK (edge_type IN ('parent_of', 'sibling_of', 'spouse_of')),
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, from_id, to_id, edge_type)
);

-- Indexes for fast lookup by user and node
CREATE INDEX idx_family_edges_user_id ON family_edges(user_id);
CREATE INDEX idx_family_edges_from_id ON family_edges(user_id, from_id);
CREATE INDEX idx_family_edges_to_id ON family_edges(user_id, to_id);

-- Row Level Security
ALTER TABLE family_edges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own edges"
  ON family_edges FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own edges"
  ON family_edges FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own edges"
  ON family_edges FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own edges"
  ON family_edges FOR DELETE
  USING (auth.uid() = user_id);
