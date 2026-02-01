-- Family groups for shared family trees
CREATE TABLE IF NOT EXISTS family_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_by UUID REFERENCES auth.users(id) NOT NULL,
  invite_code TEXT UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(6), 'hex'),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS family_group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES family_groups(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  relative_id_in_tree UUID,
  role TEXT DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  joined_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(group_id, user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_family_groups_created_by ON family_groups(created_by);
CREATE INDEX IF NOT EXISTS idx_family_group_members_user_id ON family_group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_family_group_members_group_id ON family_group_members(group_id);

-- RLS
ALTER TABLE family_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_group_members ENABLE ROW LEVEL SECURITY;

-- Group policies
CREATE POLICY "Members can view their groups"
  ON family_groups FOR SELECT
  USING (id IN (SELECT group_id FROM family_group_members WHERE user_id = auth.uid()));

CREATE POLICY "Creator can insert groups"
  ON family_groups FOR INSERT
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "Creator can update their groups"
  ON family_groups FOR UPDATE
  USING (created_by = auth.uid());

CREATE POLICY "Creator can delete their groups"
  ON family_groups FOR DELETE
  USING (created_by = auth.uid());

-- Creator can also view their own groups (covers the case before member row exists)
CREATE POLICY "Creator can view their groups"
  ON family_groups FOR SELECT
  USING (created_by = auth.uid());

-- Secure function for invite code lookup (bypasses RLS safely)
CREATE OR REPLACE FUNCTION lookup_group_by_invite_code(code TEXT)
RETURNS SETOF family_groups
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT * FROM family_groups WHERE invite_code = code LIMIT 1;
$$;

-- Member policies
CREATE POLICY "Members can view group members"
  ON family_group_members FOR SELECT
  USING (group_id IN (SELECT group_id FROM family_group_members WHERE user_id = auth.uid()));

CREATE POLICY "Users can insert themselves as members"
  ON family_group_members FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Members can remove themselves"
  ON family_group_members FOR DELETE
  USING (user_id = auth.uid());

CREATE POLICY "Admins can remove other members"
  ON family_group_members FOR DELETE
  USING (
    group_id IN (
      SELECT group_id FROM family_group_members
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );
