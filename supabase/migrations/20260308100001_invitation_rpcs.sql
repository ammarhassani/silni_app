-- ============================================================================
-- Node Invitation RPCs
-- ============================================================================
-- SECURITY DEFINER functions for the node invitation lifecycle:
--   1. create_node_invitation  — admin creates an invitation for a tree node
--   2. accept_node_invitation  — invitee accepts and claims the node
--   3. cancel_node_invitation  — admin cancels a pending invitation
--   4. get_my_pending_invitations — invitee retrieves their pending invitations
-- ============================================================================

-- ============================================================================
-- 1. create_node_invitation
-- ============================================================================

CREATE OR REPLACE FUNCTION create_node_invitation(
  p_group_id UUID,
  p_relative_id UUID,
  p_phone TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_admin RECORD;
  v_relative RECORD;
  v_normalized_phone TEXT;
  v_invitation RECORD;
BEGIN
  -- 1. Validate caller is admin of p_group_id
  SELECT id, role INTO v_admin
  FROM family_group_members
  WHERE group_id = p_group_id AND user_id = v_caller_id
  FOR UPDATE;

  IF v_admin IS NULL OR v_admin.role != 'admin' THEN
    RAISE EXCEPTION 'ليس لديك صلاحية إدارة هذه المجموعة';
  END IF;

  -- 2. Validate relative belongs to group
  SELECT id, name, relationship_type INTO v_relative
  FROM relatives
  WHERE id = p_relative_id AND family_group_id = p_group_id
  FOR UPDATE;

  IF v_relative IS NULL THEN
    RAISE EXCEPTION 'هذا الشخص لا ينتمي لهذه المجموعة';
  END IF;

  -- 3. Normalize phone: strip whitespace, ensure '+' prefix, validate length
  v_normalized_phone := regexp_replace(trim(p_phone), '\s+', '', 'g');

  IF left(v_normalized_phone, 1) != '+' THEN
    v_normalized_phone := '+' || v_normalized_phone;
  END IF;

  IF length(v_normalized_phone) < 8 OR length(v_normalized_phone) > 16 THEN
    RAISE EXCEPTION 'رقم الهاتف غير صالح';
  END IF;

  -- 4. Check no existing pending invitation for this node
  IF EXISTS (
    SELECT 1 FROM node_invitations
    WHERE group_id = p_group_id
      AND relative_id = p_relative_id
      AND status = 'pending'
  ) THEN
    RAISE EXCEPTION 'يوجد دعوة معلقة لهذا الشخص بالفعل';
  END IF;

  -- 5. Check node isn't already claimed
  IF EXISTS (
    SELECT 1 FROM family_group_members
    WHERE group_id = p_group_id
      AND relative_id_in_tree = p_relative_id
  ) THEN
    RAISE EXCEPTION 'هذا الشخص مرتبط بعضو بالفعل';
  END IF;

  -- 6. Insert invitation
  INSERT INTO node_invitations (group_id, relative_id, phone_number, invited_by)
  VALUES (p_group_id, p_relative_id, v_normalized_phone, v_caller_id)
  RETURNING * INTO v_invitation;

  -- 7. Return JSONB
  RETURN jsonb_build_object(
    'id', v_invitation.id,
    'group_id', v_invitation.group_id,
    'relative_id', v_invitation.relative_id,
    'phone_number', v_invitation.phone_number,
    'invited_by', v_invitation.invited_by,
    'status', v_invitation.status,
    'created_at', v_invitation.created_at
  );
END;
$$;

GRANT EXECUTE ON FUNCTION create_node_invitation(UUID, UUID, TEXT) TO authenticated;

-- ============================================================================
-- 2. accept_node_invitation
-- ============================================================================

CREATE OR REPLACE FUNCTION accept_node_invitation(p_invitation_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_caller_phone TEXT;
  v_invitation RECORD;
  v_normalized_caller_phone TEXT;
  v_group_name TEXT;
BEGIN
  -- 1. Get caller's verified phone from auth.users
  SELECT phone INTO v_caller_phone
  FROM auth.users
  WHERE id = v_caller_id;

  -- 2. Validate phone is verified
  IF v_caller_phone IS NULL OR trim(v_caller_phone) = '' THEN
    RAISE EXCEPTION 'يجب التحقق من رقم هاتفك أولاً';
  END IF;

  -- Normalize caller phone for comparison
  v_normalized_caller_phone := regexp_replace(trim(v_caller_phone), '\s+', '', 'g');
  IF left(v_normalized_caller_phone, 1) != '+' THEN
    v_normalized_caller_phone := '+' || v_normalized_caller_phone;
  END IF;

  -- 3. Get invitation with FOR UPDATE lock
  SELECT * INTO v_invitation
  FROM node_invitations
  WHERE id = p_invitation_id
  FOR UPDATE;

  IF v_invitation IS NULL THEN
    RAISE EXCEPTION 'الدعوة غير موجودة';
  END IF;

  -- 4. Validate status = 'pending'
  IF v_invitation.status != 'pending' THEN
    RAISE EXCEPTION 'هذه الدعوة لم تعد صالحة';
  END IF;

  -- 5. Validate normalized phone match
  IF v_normalized_caller_phone != v_invitation.phone_number THEN
    RAISE EXCEPTION 'رقم الهاتف لا يتطابق مع الدعوة';
  END IF;

  -- 6. Check node isn't already claimed (race condition guard)
  IF EXISTS (
    SELECT 1 FROM family_group_members
    WHERE group_id = v_invitation.group_id
      AND relative_id_in_tree = v_invitation.relative_id
  ) THEN
    RAISE EXCEPTION 'هذا الشخص مرتبط بعضو آخر بالفعل';
  END IF;

  -- 7/8. Upsert membership
  IF NOT EXISTS (
    SELECT 1 FROM family_group_members
    WHERE group_id = v_invitation.group_id AND user_id = v_caller_id
  ) THEN
    -- New member: insert with relative_id_in_tree
    INSERT INTO family_group_members (group_id, user_id, role, relative_id_in_tree)
    VALUES (v_invitation.group_id, v_caller_id, 'member', v_invitation.relative_id);
  ELSE
    -- Existing member: update relative_id_in_tree
    UPDATE family_group_members
    SET relative_id_in_tree = v_invitation.relative_id
    WHERE group_id = v_invitation.group_id AND user_id = v_caller_id;
  END IF;

  -- 9. Claim the node
  UPDATE relatives
  SET is_self = true,
      user_id = v_caller_id
  WHERE id = v_invitation.relative_id;

  -- 10. Update invitation status
  UPDATE node_invitations
  SET status = 'accepted',
      accepted_by = v_caller_id,
      accepted_at = now()
  WHERE id = p_invitation_id;

  -- 11. Get group name for response
  SELECT name INTO v_group_name
  FROM family_groups
  WHERE id = v_invitation.group_id;

  RETURN jsonb_build_object(
    'group_id', v_invitation.group_id,
    'group_name', v_group_name,
    'relative_id', v_invitation.relative_id
  );
END;
$$;

GRANT EXECUTE ON FUNCTION accept_node_invitation(UUID) TO authenticated;

-- ============================================================================
-- 3. cancel_node_invitation
-- ============================================================================

CREATE OR REPLACE FUNCTION cancel_node_invitation(p_invitation_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_invitation RECORD;
BEGIN
  -- 1. Get invitation with FOR UPDATE lock
  SELECT * INTO v_invitation
  FROM node_invitations
  WHERE id = p_invitation_id
  FOR UPDATE;

  IF v_invitation IS NULL THEN
    RAISE EXCEPTION 'الدعوة غير موجودة';
  END IF;

  IF v_invitation.status != 'pending' THEN
    RAISE EXCEPTION 'لا يمكن إلغاء هذه الدعوة';
  END IF;

  -- 2. Validate caller is admin of the group
  IF NOT EXISTS (
    SELECT 1 FROM family_group_members
    WHERE group_id = v_invitation.group_id
      AND user_id = v_caller_id
      AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'ليس لديك صلاحية إلغاء هذه الدعوة';
  END IF;

  -- 3. Update status
  UPDATE node_invitations
  SET status = 'cancelled',
      cancelled_at = now()
  WHERE id = p_invitation_id;
END;
$$;

GRANT EXECUTE ON FUNCTION cancel_node_invitation(UUID) TO authenticated;

-- ============================================================================
-- 4. get_my_pending_invitations
-- ============================================================================

CREATE OR REPLACE FUNCTION get_my_pending_invitations()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_caller_phone TEXT;
  v_normalized_phone TEXT;
  v_result JSONB;
BEGIN
  -- 1. Get caller's phone from auth.users
  SELECT phone INTO v_caller_phone
  FROM auth.users
  WHERE id = v_caller_id;

  -- 2. If phone null/empty, return empty array
  IF v_caller_phone IS NULL OR trim(v_caller_phone) = '' THEN
    RETURN '[]'::jsonb;
  END IF;

  -- Normalize phone for comparison
  v_normalized_phone := regexp_replace(trim(v_caller_phone), '\s+', '', 'g');
  IF left(v_normalized_phone, 1) != '+' THEN
    v_normalized_phone := '+' || v_normalized_phone;
  END IF;

  -- 3. Query pending invitations with joined data
  SELECT COALESCE(jsonb_agg(row_data), '[]'::jsonb)
  INTO v_result
  FROM (
    SELECT jsonb_build_object(
      'id', ni.id,
      'group_id', ni.group_id,
      'relative_id', ni.relative_id,
      'status', ni.status,
      'created_at', ni.created_at,
      'group_name', fg.name,
      'relative_name', r.name,
      'relationship_type', r.relationship_type,
      'invited_by_name', COALESCE(
        u.raw_user_meta_data ->> 'full_name',
        u.raw_user_meta_data ->> 'name',
        'عضو المجموعة'
      )
    ) AS row_data
    FROM node_invitations ni
    JOIN family_groups fg ON fg.id = ni.group_id
    JOIN relatives r ON r.id = ni.relative_id
    LEFT JOIN auth.users u ON u.id = ni.invited_by
    WHERE ni.phone_number = v_normalized_phone
      AND ni.status = 'pending'
    ORDER BY ni.created_at DESC
  ) sub;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION get_my_pending_invitations() TO authenticated;
