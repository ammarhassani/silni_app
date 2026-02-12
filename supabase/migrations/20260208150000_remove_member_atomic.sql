-- ============================================================================
-- Atomic remove_member RPC
-- 2026-02-08
--
-- Wraps the admin remove-member flow in a single transaction:
--   1. Verify caller is admin of the group
--   2. Verify target is a non-admin member
--   3. Clean up self-node (delete joiner-created, unmark pre-existing)
--   4. Delete membership
-- ============================================================================

CREATE OR REPLACE FUNCTION remove_member_atomic(
  p_group_id UUID,
  p_member_id UUID  -- family_group_members.id of the target
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_role TEXT;
  v_member RECORD;
  v_node_data RECORD;
BEGIN
  -- SECURITY: Verify caller is admin of this group
  SELECT role INTO v_caller_role
  FROM family_group_members
  WHERE group_id = p_group_id AND user_id = auth.uid()
  FOR UPDATE;

  IF v_caller_role IS NULL THEN
    RAISE EXCEPTION 'Caller is not a member of this group';
  END IF;
  IF v_caller_role != 'admin' THEN
    RAISE EXCEPTION 'Only admins can remove members';
  END IF;

  -- Lock and fetch target member
  SELECT id, user_id, relative_id_in_tree, role
  INTO v_member
  FROM family_group_members
  WHERE id = p_member_id AND group_id = p_group_id
  FOR UPDATE;

  IF v_member IS NULL THEN
    RETURN; -- Already removed — idempotent
  END IF;

  -- Prevent removing another admin
  IF v_member.role = 'admin' THEN
    RAISE EXCEPTION 'Cannot remove another admin from the group';
  END IF;

  -- Prevent self-removal via this RPC (use leave_group_atomic instead)
  IF v_member.user_id = auth.uid() THEN
    RAISE EXCEPTION 'Use leave_group to remove yourself';
  END IF;

  -- Self-node cleanup
  IF v_member.relative_id_in_tree IS NOT NULL THEN
    SELECT added_by INTO v_node_data
    FROM relatives
    WHERE id = v_member.relative_id_in_tree
    FOR UPDATE;

    IF v_node_data IS NOT NULL AND v_node_data.added_by = v_member.user_id THEN
      -- Joiner-created node: delete interactions, edges, and the relative
      DELETE FROM interactions
      WHERE relative_id = v_member.relative_id_in_tree;

      DELETE FROM family_edges
      WHERE family_group_id = p_group_id
        AND (from_id = v_member.relative_id_in_tree
             OR to_id = v_member.relative_id_in_tree);

      DELETE FROM relatives
      WHERE id = v_member.relative_id_in_tree
        AND is_self = true;
    ELSIF v_node_data IS NOT NULL THEN
      -- Pre-existing node claimed by the user: just unmark is_self
      UPDATE relatives
      SET is_self = false
      WHERE id = v_member.relative_id_in_tree;
    END IF;
  END IF;

  -- Remove membership
  DELETE FROM family_group_members
  WHERE id = v_member.id;
END;
$$;
