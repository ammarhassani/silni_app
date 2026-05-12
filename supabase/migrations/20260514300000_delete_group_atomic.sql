-- 20260514300000_delete_group_atomic.sql
-- Atomic group deletion. The raw DELETE FROM family_groups cascaded to
-- family_group_members in an order that tripped trg_prevent_last_admin
-- (which blocks deleting an admin while non-admin members still exist).
-- Solution: explicitly purge each non-admin member's group data, delete
-- their member row, THEN delete the admin's row (no other members exist,
-- so the trigger no-ops), then delete the group itself.

CREATE OR REPLACE FUNCTION public.delete_group_atomic(p_group_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_caller_role TEXT;
  v_member RECORD;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- Verify the caller is admin of this group
  SELECT role INTO v_caller_role
    FROM family_group_members
   WHERE group_id = p_group_id
     AND user_id = v_caller;

  IF v_caller_role IS NULL THEN
    RAISE EXCEPTION 'Caller is not a member of this group';
  END IF;
  IF v_caller_role <> 'admin' THEN
    RAISE EXCEPTION 'Only admins can delete the group';
  END IF;

  -- Purge + delete every non-admin member FIRST. Iterating with FOR + DELETE
  -- inside the loop is fine because the cursor is materialized at LOOP start.
  FOR v_member IN
    SELECT id, user_id
    FROM family_group_members
    WHERE group_id = p_group_id
      AND role <> 'admin'
  LOOP
    PERFORM public._purge_member_group_data(p_group_id, v_member.user_id);
    DELETE FROM family_group_members WHERE id = v_member.id;
  END LOOP;

  -- Now purge + delete the admin's row. At this point no non-admin members
  -- remain, so the trg_prevent_last_admin trigger's "other members exist"
  -- check returns false → it allows the delete.
  FOR v_member IN
    SELECT id, user_id
    FROM family_group_members
    WHERE group_id = p_group_id
      AND role = 'admin'
  LOOP
    PERFORM public._purge_member_group_data(p_group_id, v_member.user_id);
    DELETE FROM family_group_members WHERE id = v_member.id;
  END LOOP;

  -- Finally, delete the group itself.
  DELETE FROM family_groups WHERE id = p_group_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.delete_group_atomic(UUID) TO authenticated;
