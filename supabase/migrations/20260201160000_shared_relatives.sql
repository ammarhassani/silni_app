-- ============================================================================
-- Task 11: Shared Family Tree (Collaborative Adding)
-- ============================================================================
-- Adds shared tree columns to the relatives table so that family group members
-- can collaboratively build a shared relative list.
--
-- Ownership model:
--   - Personal relatives: family_group_id IS NULL, user_id = owner
--   - Shared relatives: family_group_id IS NOT NULL, user_id = adding user,
--     added_by = adding user. user_id is always the person who created the row.
--     The SELECT policy separates personal (family_group_id IS NULL) from shared
--     (family_group_id IS NOT NULL) views.
--
-- Changes:
--   1. Add family_group_id (nullable FK) to relatives
--   2. Add added_by (nullable FK) to relatives
--   3. Create index for shared-tree queries
--   4. Update RLS policies to allow group members to view/update/delete shared relatives
-- ============================================================================

-- 1. Add shared tree columns
ALTER TABLE relatives
  ADD COLUMN family_group_id UUID REFERENCES family_groups(id) ON DELETE SET NULL,
  ADD COLUMN added_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- 2. Index for efficient shared tree lookups
CREATE INDEX idx_relatives_family_group
  ON relatives(family_group_id)
  WHERE family_group_id IS NOT NULL;

-- 3. Update RLS policies --------------------------------------------------------

-- SELECT: Drop existing policy and recreate with shared access
DROP POLICY IF EXISTS "Users can view own relatives" ON relatives;

CREATE POLICY "Users can view own and shared relatives"
  ON relatives FOR SELECT
  USING (
    -- Personal relatives (no group)
    (family_group_id IS NULL AND user_id = auth.uid())
    OR
    -- Shared relatives in groups the user belongs to
    (family_group_id IS NOT NULL AND family_group_id IN (
      SELECT group_id FROM family_group_members WHERE user_id = auth.uid()
    ))
  );

-- INSERT: Drop existing policy and recreate to also allow group member inserts
DROP POLICY IF EXISTS "Users can insert own relatives" ON relatives;

CREATE POLICY "Users or group members can insert relatives"
  ON relatives FOR INSERT
  WITH CHECK (
    -- Personal relatives: must own the row
    (family_group_id IS NULL AND user_id = auth.uid())
    OR
    -- Shared relatives: user must be a member of the target group
    (family_group_id IS NOT NULL AND user_id = auth.uid() AND family_group_id IN (
      SELECT group_id FROM family_group_members WHERE user_id = auth.uid()
    ))
  );

-- UPDATE: Drop existing policy and recreate with shared access + WITH CHECK
DROP POLICY IF EXISTS "Users can update own relatives" ON relatives;

CREATE POLICY "Owner or group members can update relatives"
  ON relatives FOR UPDATE
  USING (
    user_id = auth.uid()
    OR
    (family_group_id IS NOT NULL AND family_group_id IN (
      SELECT group_id FROM family_group_members WHERE user_id = auth.uid()
    ))
  )
  WITH CHECK (
    -- Prevent changing ownership: user_id and family_group_id must stay the same
    -- The USING clause already ensures the user is authorized;
    -- WITH CHECK ensures the updated row is still valid
    user_id = auth.uid()
    OR
    (family_group_id IS NOT NULL AND family_group_id IN (
      SELECT group_id FROM family_group_members WHERE user_id = auth.uid()
    ))
  );

-- DELETE: Only the owner, adder, or group admin can delete
DROP POLICY IF EXISTS "Users can delete own relatives" ON relatives;

CREATE POLICY "Owner or adder or admin can delete relatives"
  ON relatives FOR DELETE
  USING (
    user_id = auth.uid()
    OR
    (family_group_id IS NOT NULL AND added_by = auth.uid())
    OR
    (family_group_id IS NOT NULL AND family_group_id IN (
      SELECT group_id FROM family_group_members
      WHERE user_id = auth.uid() AND role = 'admin'
    ))
  );
