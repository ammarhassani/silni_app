-- 20260511180000_fix_member_removal_cleanup.sql
-- Fix the kick/leave cleanup so it removes ALL data the departing user
-- owned in the group — not just their `relative_id_in_tree` self-node.
--
-- Symptom that motivated this: when an admin kicked a joiner, the
-- joiner's added relatives (e.g. their mother) and the in-group
-- "add-me-approved" self-node stayed behind as orphans (is_self=false,
-- still user_id=joiner, still family_group_id=the_group). Admin's
-- spouse_of edges to the orphan also remained. Result: the joiner saw
-- themselves as their own spouse, with their mother stranded in the
-- ex-group's scope.
--
-- Both leave_group_atomic and remove_member_atomic had the same bug —
-- they only inspected v_member.relative_id_in_tree. We replace that
-- narrow logic with a comprehensive purge helper.

-- ---------------------------------------------------------------------
-- Helper: purge all of one user's contributions to one group
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public._purge_member_group_data(
  p_group_id UUID,
  p_user_id UUID
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_their_ids UUID[];
  v_their_ids_text TEXT[];
BEGIN
  -- 1. Collect every relative the departing user owns in this group.
  --    Empty array is fine — downstream deletes become no-ops.
  SELECT COALESCE(array_agg(id), ARRAY[]::uuid[])
    INTO v_their_ids
    FROM relatives
   WHERE family_group_id = p_group_id AND user_id = p_user_id;

  v_their_ids_text := ARRAY(SELECT unnest(v_their_ids)::text);

  -- 2. Interactions on those relatives.
  DELETE FROM interactions
   WHERE relative_id = ANY(v_their_ids);

  -- 3. Edges in this group that either:
  --      a) belong to the departing user, or
  --      b) reference one of their relatives — admin-owned cross-edges
  --         (e.g. admin's spouse_of → kicked-user's self-node) would
  --         otherwise dangle pointing at a row we're about to delete.
  DELETE FROM family_edges
   WHERE family_group_id = p_group_id
     AND (
       user_id = p_user_id
       OR from_id = ANY(v_their_ids_text)
       OR to_id   = ANY(v_their_ids_text)
     );

  -- 4. The relatives themselves.
  DELETE FROM relatives
   WHERE family_group_id = p_group_id AND user_id = p_user_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public._purge_member_group_data(UUID, UUID) FROM PUBLIC;

-- ---------------------------------------------------------------------
-- leave_group_atomic — replace the self-node-only cleanup with the helper
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.leave_group_atomic(p_group_id UUID, p_user_id UUID)
 RETURNS VOID
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $$
DECLARE
  v_member RECORD;
  v_other_admin_exists BOOLEAN;
  v_next_member RECORD;
  v_remaining_count INTEGER;
BEGIN
  -- SECURITY: only the user themselves can call this for themselves.
  IF p_user_id != auth.uid() THEN
    RAISE EXCEPTION 'Cannot leave group for another user';
  END IF;

  SELECT id, relative_id_in_tree, role
    INTO v_member
    FROM family_group_members
   WHERE group_id = p_group_id AND user_id = p_user_id
   FOR UPDATE;

  IF v_member IS NULL THEN
    RETURN; -- idempotent
  END IF;

  -- Admin transfer: if sole admin, promote oldest remaining member.
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
       WHERE group_id = p_group_id AND user_id != p_user_id
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

  -- Purge ALL of the user's contributions to this group.
  PERFORM public._purge_member_group_data(p_group_id, p_user_id);

  -- Remaining headcount BEFORE we remove our membership.
  v_remaining_count := (
    SELECT COUNT(*) FROM family_group_members
     WHERE group_id = p_group_id AND user_id != p_user_id
  );

  DELETE FROM family_group_members WHERE id = v_member.id;

  -- Ghost-group cleanup.
  IF v_remaining_count = 0 THEN
    DELETE FROM family_groups WHERE id = p_group_id;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.leave_group_atomic(UUID, UUID) TO authenticated;

-- ---------------------------------------------------------------------
-- remove_member_atomic — same helper for the admin-kick path
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.remove_member_atomic(
  p_group_id UUID,
  p_member_id UUID
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_role TEXT;
  v_member RECORD;
BEGIN
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

  SELECT id, user_id, relative_id_in_tree, role
    INTO v_member
    FROM family_group_members
   WHERE id = p_member_id AND group_id = p_group_id
   FOR UPDATE;

  IF v_member IS NULL THEN
    RETURN;
  END IF;

  IF v_member.role = 'admin' THEN
    RAISE EXCEPTION 'Cannot remove another admin from the group';
  END IF;

  IF v_member.user_id = auth.uid() THEN
    RAISE EXCEPTION 'Use leave_group to remove yourself';
  END IF;

  -- Purge all of the target user's contributions to this group.
  PERFORM public._purge_member_group_data(p_group_id, v_member.user_id);

  DELETE FROM family_group_members WHERE id = v_member.id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.remove_member_atomic(UUID, UUID) TO authenticated;

-- ---------------------------------------------------------------------
-- One-shot cleanup of existing orphans from the kick that motivated this
-- migration. Idempotent because _purge_member_group_data filters by
-- (group_id, user_id) — re-running on a clean state is a no-op.
-- ---------------------------------------------------------------------
DO $$
DECLARE
  r RECORD;
BEGIN
  -- For every relative still sitting in a group that the owning user is
  -- NO LONGER a member of, purge that (group, user) pair. This catches
  -- the testprodjoiner residue and any analogous leakage on other groups.
  FOR r IN
    SELECT DISTINCT rel.family_group_id, rel.user_id
      FROM relatives rel
     WHERE rel.family_group_id IS NOT NULL
       AND NOT EXISTS (
         SELECT 1 FROM family_group_members m
          WHERE m.group_id = rel.family_group_id
            AND m.user_id  = rel.user_id
       )
  LOOP
    RAISE NOTICE 'Purging orphan data: group=% user=%', r.family_group_id, r.user_id;
    PERFORM public._purge_member_group_data(r.family_group_id, r.user_id);
  END LOOP;
END $$;
