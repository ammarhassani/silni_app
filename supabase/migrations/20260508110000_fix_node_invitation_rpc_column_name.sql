-- ============================================================================
-- Codify column-name fix in node-invitation RPCs (drift protection)
-- ============================================================================
-- Migration 20260308100001_invitation_rpcs.sql originally referenced
-- `relatives.name` in two places. The canonical column is `full_name` —
-- the bug was dormant because the phone-invite UI was cut from v1.
--
-- Verified via MCP on 2026-05-08: production has ALREADY been patched
-- directly (both create_node_invitation and get_my_pending_invitations
-- carry a "δ.A fix: column is full_name, not name" comment in their
-- pg_proc source). That patch was applied out-of-band (no migration
-- history). This migration codifies the fix so:
--   1. Migration history matches production state.
--   2. Fresh deploys (staging / dev / new branches) get the same fix.
--   3. Any future drop+recreate of the schema picks it up.
--
-- CREATE OR REPLACE — idempotent. No behavior change against prod.
-- ============================================================================

-- ============================================================================
-- 1. create_node_invitation — replace `name` with `full_name`
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

  -- 2. Validate relative belongs to group (use full_name, not name).
  SELECT id, full_name, relationship_type INTO v_relative
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
-- 2. get_my_pending_invitations — replace `r.name` with `r.full_name`
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

  -- 3. Query pending invitations with joined data (use full_name, not name).
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
      'relative_name', r.full_name,
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
