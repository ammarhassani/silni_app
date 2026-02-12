-- ============================================================================
-- Final Audit Fixes — Part 3: leave_group_atomic
-- ============================================================================
CREATE OR REPLACE FUNCTION leave_group_atomic(
  p_group_id UUID,
  p_user_id UUID
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_member RECORD;
  v_node_data RECORD;
  v_other_admin_exists BOOLEAN;
  v_next_member RECORD;
  v_remaining_count INTEGER;
BEGIN
  -- SECURITY: Verify caller identity
  IF p_user_id != auth.uid() THEN
    RAISE EXCEPTION 'Cannot leave group for another user';
  END IF;

  -- 1. Find and lock the membership row (prevents concurrent leave)
  SELECT id, relative_id_in_tree, role
  INTO v_member
  FROM family_group_members
  WHERE group_id = p_group_id AND user_id = p_user_id
  FOR UPDATE;

  IF v_member IS NULL THEN
    RETURN; -- Not a member — idempotent
  END IF;

  -- 2. Admin transfer: if sole admin, promote the oldest remaining member
  IF v_member.role = 'admin' THEN
    SELECT EXISTS(
      SELECT 1 FROM family_group_members
      WHERE group_id = p_group_id
        AND role = 'admin'
        AND user_id != p_user_id
    ) INTO v_other_admin_exists;

    IF NOT v_other_admin_exists THEN
      SELECT id INTO v_next_member
      FROM family_group_members
      WHERE group_id = p_group_id
        AND user_id != p_user_id
      ORDER BY joined_at ASC
      LIMIT 1
      FOR UPDATE;

      IF v_next_member IS NOT NULL THEN
        UPDATE family_group_members
        SET role = 'admin'
        WHERE id = v_next_member.id;
      END IF;
    END IF;
  END IF;

  -- 3. Self-node cleanup
  IF v_member.relative_id_in_tree IS NOT NULL THEN
    SELECT added_by INTO v_node_data
    FROM relatives
    WHERE id = v_member.relative_id_in_tree
    FOR UPDATE;

    IF v_node_data IS NOT NULL AND v_node_data.added_by = p_user_id THEN
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
      UPDATE relatives
      SET is_self = false
      WHERE id = v_member.relative_id_in_tree;
    END IF;
  END IF;

  -- 4. Remove membership
  v_remaining_count := (
    SELECT COUNT(*) FROM family_group_members
    WHERE group_id = p_group_id AND user_id != p_user_id
  );

  DELETE FROM family_group_members
  WHERE id = v_member.id;

  -- 5. Ghost group cleanup — if no members remain, delete the group
  IF v_remaining_count = 0 THEN
    DELETE FROM family_groups WHERE id = p_group_id;
  END IF;
END;
$$;
