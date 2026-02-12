-- ============================================================================
-- claim_tree_node RPC
-- 2026-02-09
--
-- Allows a group member to claim a tree node during the join flow.
-- Needed because RLS restricts relative UPDATEs to owner/adder/admin,
-- but joiners need to set is_self=true on nodes they claim.
-- ============================================================================

CREATE OR REPLACE FUNCTION claim_tree_node(
  p_group_id UUID,
  p_node_id UUID
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_membership_id UUID;
  v_node RECORD;
BEGIN
  -- 1. Verify caller is a member of this group
  SELECT id INTO v_membership_id
  FROM family_group_members
  WHERE group_id = p_group_id AND user_id = auth.uid();

  IF v_membership_id IS NULL THEN
    RAISE EXCEPTION 'Caller is not a member of this group';
  END IF;

  -- 2. Verify node belongs to this group and is not already claimed
  SELECT id, family_group_id, is_self
  INTO v_node
  FROM relatives
  WHERE id = p_node_id
  FOR UPDATE;

  IF v_node IS NULL THEN
    RAISE EXCEPTION 'Node not found';
  END IF;

  IF v_node.family_group_id != p_group_id THEN
    RAISE EXCEPTION 'Node does not belong to this group';
  END IF;

  -- 3. Check not already claimed by another member
  IF EXISTS (
    SELECT 1 FROM family_group_members
    WHERE group_id = p_group_id
      AND relative_id_in_tree = p_node_id
      AND user_id != auth.uid()
  ) THEN
    RAISE EXCEPTION 'Node already claimed by another member';
  END IF;

  -- 4. Mark node as self and transfer ownership to the claimer.
  -- user_id must change so the unique index (user_id, family_group_id)
  -- where is_self=true is not violated (creator already has a self-node).
  UPDATE relatives
  SET is_self = true,
      user_id = auth.uid()
  WHERE id = p_node_id;

  -- 5. Link membership to this node
  UPDATE family_group_members
  SET relative_id_in_tree = p_node_id
  WHERE id = v_membership_id;
END;
$$;
