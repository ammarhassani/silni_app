-- ============================================================================
-- Family Sharing Hardening: Admin Management + Invite Code Rotation
-- ============================================================================
-- 1. Extend group UPDATE/DELETE from creator-only to any admin
-- 2. Add member role UPDATE policy (was missing entirely)
-- 3. Add rotate_invite_code() SECURITY DEFINER RPC
-- ============================================================================

-- ============================================================================
-- 1. Extend family_groups policies to admins (not just creator)
-- ============================================================================

-- Replace creator-only UPDATE with admin UPDATE
DROP POLICY IF EXISTS "Creator can update their groups" ON family_groups;
CREATE POLICY "Admins can update their groups"
  ON family_groups FOR UPDATE
  USING (
    created_by = auth.uid()
    OR id IN (SELECT auth_user_admin_group_ids())
  );

-- Replace creator-only DELETE with admin DELETE
DROP POLICY IF EXISTS "Creator can delete their groups" ON family_groups;
CREATE POLICY "Admins can delete their groups"
  ON family_groups FOR DELETE
  USING (
    created_by = auth.uid()
    OR id IN (SELECT auth_user_admin_group_ids())
  );

-- ============================================================================
-- 2. Add member role UPDATE policy
-- ============================================================================

-- Admins can update member roles within their groups
CREATE POLICY "Admins can update member roles"
  ON family_group_members FOR UPDATE
  USING (group_id IN (SELECT auth_user_admin_group_ids()))
  WITH CHECK (group_id IN (SELECT auth_user_admin_group_ids()));

-- ============================================================================
-- 3. Secure invite code rotation function
-- ============================================================================

CREATE OR REPLACE FUNCTION rotate_invite_code(target_group_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  new_code TEXT;
BEGIN
  -- Verify caller is admin of this group
  IF NOT EXISTS (
    SELECT 1 FROM family_group_members
    WHERE group_id = target_group_id
      AND user_id = auth.uid()
      AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only admins can rotate invite codes';
  END IF;

  new_code := encode(gen_random_bytes(6), 'hex');

  UPDATE family_groups
  SET invite_code = new_code, updated_at = now()
  WHERE id = target_group_id;

  RETURN new_code;
END;
$$;
