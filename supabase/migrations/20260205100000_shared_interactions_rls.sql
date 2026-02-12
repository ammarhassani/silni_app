-- ============================================================================
-- Shared Interactions: RLS policies for group-wide interaction visibility
-- ============================================================================
-- Allows family group members to view interactions logged by ANY member
-- for relatives that are in their shared family group.
-- ============================================================================

-- 1. Helper function to get relative IDs in user's family group
-- Uses SECURITY DEFINER to avoid RLS recursion
CREATE OR REPLACE FUNCTION auth_user_group_relative_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT r.id
  FROM relatives r
  INNER JOIN family_group_members fgm ON fgm.group_id = r.family_group_id
  WHERE fgm.user_id = auth.uid()
    AND r.is_archived = false;
$$;

-- 2. Update interactions SELECT policy to include shared interactions
-- Drop existing policy first (if exists)
DROP POLICY IF EXISTS "Users can view own interactions" ON interactions;
DROP POLICY IF EXISTS "Users can view own and shared interactions" ON interactions;

-- Create new policy allowing view of:
-- - Own interactions (user_id = auth.uid())
-- - Interactions for relatives in user's family group
CREATE POLICY "Users can view own and shared interactions"
  ON interactions FOR SELECT
  USING (
    user_id = auth.uid()
    OR
    relative_id IN (SELECT auth_user_group_relative_ids())
  );

-- 3. Ensure INSERT/UPDATE/DELETE policies remain personal (user_id = auth.uid())
-- Users can only create/modify their own interactions
DROP POLICY IF EXISTS "Users can insert own interactions" ON interactions;
CREATE POLICY "Users can insert own interactions"
  ON interactions FOR INSERT
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own interactions" ON interactions;
CREATE POLICY "Users can update own interactions"
  ON interactions FOR UPDATE
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own interactions" ON interactions;
CREATE POLICY "Users can delete own interactions"
  ON interactions FOR DELETE
  USING (user_id = auth.uid());

-- 4. Add index to optimize the join
CREATE INDEX IF NOT EXISTS idx_interactions_relative_id
  ON interactions(relative_id);
