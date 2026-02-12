-- ============================================================================
-- Family Sharing Hardening: Fix critical RLS gap
-- ============================================================================
-- Add missing UPDATE policy on family_group_members.
-- Without this, all .update({'relative_id_in_tree': ...}) calls silently fail
-- because RLS blocks the update with no error.
-- ============================================================================

CREATE POLICY "Members can update their own membership"
  ON family_group_members FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
