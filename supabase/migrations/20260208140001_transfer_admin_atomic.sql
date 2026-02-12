-- ============================================================================
-- Final Audit Fixes — Part 2: transfer_admin_atomic
-- ============================================================================
CREATE OR REPLACE FUNCTION transfer_admin_atomic(
  p_group_id UUID,
  p_current_user_id UUID,
  p_new_admin_member_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_role TEXT;
  v_target_exists BOOLEAN;
BEGIN
  -- SECURITY: Verify caller identity
  IF p_current_user_id != auth.uid() THEN
    RAISE EXCEPTION 'Cannot transfer admin for another user';
  END IF;

  -- Verify caller is admin of this group (with lock)
  SELECT role INTO v_caller_role
  FROM family_group_members
  WHERE group_id = p_group_id AND user_id = p_current_user_id
  FOR UPDATE;

  IF v_caller_role IS NULL THEN
    RAISE EXCEPTION 'Caller is not a member of this group';
  END IF;
  IF v_caller_role != 'admin' THEN
    RAISE EXCEPTION 'Only admins can transfer admin role';
  END IF;

  -- Verify target member exists (with lock to prevent concurrent changes)
  SELECT EXISTS(
    SELECT 1 FROM family_group_members
    WHERE id = p_new_admin_member_id AND group_id = p_group_id
    FOR UPDATE
  ) INTO v_target_exists;

  IF NOT v_target_exists THEN
    RAISE EXCEPTION 'Target member not found in this group';
  END IF;

  -- Promote target (within same transaction)
  UPDATE family_group_members
  SET role = 'admin'
  WHERE id = p_new_admin_member_id AND group_id = p_group_id;

  -- Demote caller (within same transaction)
  UPDATE family_group_members
  SET role = 'member'
  WHERE group_id = p_group_id AND user_id = p_current_user_id;
END;
$$;
