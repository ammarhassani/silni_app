-- ============================================================================
-- Family Sharing: Shared Edges, Self Node, Relationship Labels
-- ============================================================================
-- 1. Add family_group_id to family_edges for shared graph edges
-- 2. Add is_self to relatives for the self-node concept
-- 3. Create admin_relationship_labels for admin-panelized perspective labels
-- 4. Seed relationship label rows (~24 covering common family relationships)
-- 5. Seed join notification template
-- ============================================================================

-- ============================================================================
-- 1. Add family_group_id to family_edges
-- ============================================================================

ALTER TABLE family_edges
  ADD COLUMN IF NOT EXISTS family_group_id UUID REFERENCES family_groups(id) ON DELETE CASCADE;

-- Partial index for efficient shared-edge lookups
CREATE INDEX IF NOT EXISTS idx_family_edges_family_group
  ON family_edges(family_group_id)
  WHERE family_group_id IS NOT NULL;

-- ============================================================================
-- 2. RLS policies on family_edges for group members
-- ============================================================================

-- Group members can view shared edges
CREATE POLICY "Group members can view shared edges"
  ON family_edges FOR SELECT
  USING (
    family_group_id IS NOT NULL
    AND family_group_id IN (SELECT auth_user_group_ids())
  );

-- Group members can insert shared edges
CREATE POLICY "Group members can insert shared edges"
  ON family_edges FOR INSERT
  WITH CHECK (
    family_group_id IS NOT NULL
    AND family_group_id IN (SELECT auth_user_group_ids())
  );

-- Group members can update shared edges
CREATE POLICY "Group members can update shared edges"
  ON family_edges FOR UPDATE
  USING (
    family_group_id IS NOT NULL
    AND family_group_id IN (SELECT auth_user_group_ids())
  );

-- Group members can delete shared edges
CREATE POLICY "Group members can delete shared edges"
  ON family_edges FOR DELETE
  USING (
    family_group_id IS NOT NULL
    AND family_group_id IN (SELECT auth_user_group_ids())
  );

-- ============================================================================
-- 3. Add is_self to relatives
-- ============================================================================

ALTER TABLE relatives
  ADD COLUMN IF NOT EXISTS is_self BOOLEAN DEFAULT false;

-- ============================================================================
-- 4. Create admin_relationship_labels table
-- ============================================================================

CREATE TABLE IF NOT EXISTS admin_relationship_labels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  edge_path TEXT NOT NULL,
  parent_side TEXT CHECK (parent_side IN ('paternal', 'maternal')),
  gender TEXT NOT NULL CHECK (gender IN ('male', 'female')),
  label_ar TEXT NOT NULL,
  label_en TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Use COALESCE so NULLs in parent_side are treated as equal for uniqueness
CREATE UNIQUE INDEX IF NOT EXISTS idx_admin_relationship_labels_unique
  ON admin_relationship_labels (edge_path, COALESCE(parent_side, ''), gender);

-- ============================================================================
-- 5. RLS on admin_relationship_labels
-- ============================================================================

ALTER TABLE admin_relationship_labels ENABLE ROW LEVEL SECURITY;

-- Anyone can read active labels
CREATE POLICY "Anyone can read active relationship labels"
  ON admin_relationship_labels FOR SELECT
  USING (is_active = true);

-- Admins can manage all labels
CREATE POLICY "Admins can insert relationship labels"
  ON admin_relationship_labels FOR INSERT
  WITH CHECK (is_admin());

CREATE POLICY "Admins can update relationship labels"
  ON admin_relationship_labels FOR UPDATE
  USING (is_admin());

CREATE POLICY "Admins can delete relationship labels"
  ON admin_relationship_labels FOR DELETE
  USING (is_admin());

-- ============================================================================
-- 6. Seed relationship labels
-- ============================================================================
-- edge_path conventions:
--   self           = the user themselves
--   parent         = direct parent
--   child          = direct child
--   spouse         = spouse
--   sibling        = sibling
--   grandparent    = parent's parent
--   grandchild     = child's child
--   uncle_aunt     = parent's sibling (paternal/maternal)
--   nephew_niece   = sibling's child
--   cousin         = parent's sibling's child (paternal/maternal)

INSERT INTO admin_relationship_labels (edge_path, parent_side, gender, label_ar, label_en) VALUES
  -- Self
  ('self', NULL, 'male',   'أنا',      'Self'),
  ('self', NULL, 'female', 'أنا',      'Self'),

  -- Parent
  ('parent', NULL, 'male',   'أب',     'Father'),
  ('parent', NULL, 'female', 'أم',     'Mother'),

  -- Child
  ('child', NULL, 'male',   'ابن',     'Son'),
  ('child', NULL, 'female', 'بنت',     'Daughter'),

  -- Spouse
  ('spouse', NULL, 'male',   'زوج',    'Husband'),
  ('spouse', NULL, 'female', 'زوجة',   'Wife'),

  -- Sibling
  ('sibling', NULL, 'male',   'أخ',    'Brother'),
  ('sibling', NULL, 'female', 'أخت',   'Sister'),

  -- Grandparent
  ('grandparent', 'paternal', 'male',   'جد (من الأب)',    'Paternal Grandfather'),
  ('grandparent', 'paternal', 'female', 'جدة (من الأب)',   'Paternal Grandmother'),
  ('grandparent', 'maternal', 'male',   'جد (من الأم)',    'Maternal Grandfather'),
  ('grandparent', 'maternal', 'female', 'جدة (من الأم)',   'Maternal Grandmother'),

  -- Grandchild
  ('grandchild', NULL, 'male',   'حفيد',   'Grandson'),
  ('grandchild', NULL, 'female', 'حفيدة',  'Granddaughter'),

  -- Uncle / Aunt (paternal)
  ('uncle_aunt', 'paternal', 'male',   'عم',    'Paternal Uncle'),
  ('uncle_aunt', 'paternal', 'female', 'عمة',   'Paternal Aunt'),

  -- Uncle / Aunt (maternal)
  ('uncle_aunt', 'maternal', 'male',   'خال',   'Maternal Uncle'),
  ('uncle_aunt', 'maternal', 'female', 'خالة',  'Maternal Aunt'),

  -- Nephew / Niece
  ('nephew_niece', NULL, 'male',   'ابن أخ/أخت',   'Nephew'),
  ('nephew_niece', NULL, 'female', 'بنت أخ/أخت',   'Niece'),

  -- Cousin (paternal)
  ('cousin', 'paternal', 'male',   'ابن عم',   'Paternal Male Cousin'),
  ('cousin', 'paternal', 'female', 'بنت عم',   'Paternal Female Cousin'),

  -- Cousin (maternal)
  ('cousin', 'maternal', 'male',   'ابن خال',  'Maternal Male Cousin'),
  ('cousin', 'maternal', 'female', 'بنت خال',  'Maternal Female Cousin')

ON CONFLICT (edge_path, COALESCE(parent_side, ''), gender) DO NOTHING;

-- ============================================================================
-- 7. Seed join notification template
-- ============================================================================

INSERT INTO admin_notification_templates (template_key, title_ar, body_ar, category, variables)
VALUES (
  'family_join_1',
  'انضمام عضو جديد! 👨‍👩‍👧‍👦',
  'انضم {{member_name}} إلى عائلة {{family_name}}',
  'system',
  '["member_name", "family_name"]'
)
ON CONFLICT (template_key) DO NOTHING;
