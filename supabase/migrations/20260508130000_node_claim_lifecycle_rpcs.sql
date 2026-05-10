-- ============================================================================
-- Node Claim Lifecycle RPCs
-- ============================================================================
-- SECURITY DEFINER functions for the joiner-initiated identity-claim flow:
--   1. create_node_claim         — joiner submits a claim
--   2. approve_node_claim        — admin confirms a claim
--   3. reject_node_claim         — admin denies a claim
--   4. cancel_node_claim         — joiner withdraws their own claim
--   5. snooze_node_claim         — admin defers decision ("let me think later")
--   6. get_my_pending_claims     — joiner's own claims
--   7. get_group_pending_claims  — admin's review queue
--
-- The "approve" RPC inlines the node-claim mechanic (sets is_self=true and
-- transfers user_id, updates family_group_members.relative_id_in_tree)
-- because it must operate on behalf of the claimant — the existing
-- claim_tree_node RPC uses auth.uid() and assumes the caller IS the
-- claimant, which is not true here. (claim_tree_node has zero callers in
-- lib/ as of 2026-05-08, kept for backward compatibility / future use.)
--
-- The "add me to tree" path (claimed_relative_id IS NULL) is constrained
-- to direct relationships in v1: parent, child, spouse, sibling. Complex
-- placements (uncle, cousin, nephew/niece, grandparent, grandchild) require
-- claimed_relative_id NOT NULL — the joiner must pick an existing candidate.
-- Edges for the new node are NOT inserted here; the Dart-side caller is
-- expected to invoke FamilySharingService.verifySharedEdges() after success
-- to materialize edges via the existing inferEdges() pipeline.
-- ============================================================================

-- ============================================================================
-- 1. create_node_claim
-- ============================================================================

CREATE OR REPLACE FUNCTION create_node_claim(
  p_group_id UUID,
  p_claimed_relative_id UUID,           -- NULL for "add me" path
  p_anchor_relative_id UUID,
  p_edge_path TEXT,
  p_parent_side TEXT,                   -- nullable
  p_gender TEXT,
  p_proposed_full_name TEXT,            -- NULL when claiming existing node
  p_proposed_gender TEXT,
  p_proposed_birth_year INT,
  p_proposed_city TEXT,
  p_proposed_photo_url TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_active_count INT;
  v_anchor RECORD;
  v_target RECORD;
  v_claim RECORD;
BEGIN
  -- 1. Validate caller is a member of the group.
  IF NOT EXISTS (
    SELECT 1 FROM family_group_members
    WHERE group_id = p_group_id AND user_id = v_caller_id
  ) THEN
    RAISE EXCEPTION 'يجب أن تكون عضواً في المجموعة لتقديم طلب';
  END IF;

  -- 2. Rate limit: max 3 active pending claims across all groups.
  SELECT COUNT(*) INTO v_active_count
  FROM node_claims
  WHERE claimant_user_id = v_caller_id AND status = 'pending';

  IF v_active_count >= 3 THEN
    RAISE EXCEPTION 'لديك 3 طلبات معلقة بالفعل. انتظر قرار أحدها قبل تقديم طلب جديد.';
  END IF;

  -- 3. Validate anchor exists and belongs to the group.
  SELECT id, full_name INTO v_anchor
  FROM relatives
  WHERE id = p_anchor_relative_id AND family_group_id = p_group_id;

  IF v_anchor IS NULL THEN
    RAISE EXCEPTION 'الشخص المرجعي غير موجود في الشجرة';
  END IF;

  -- 4. Validate target consistency:
  --    (a) claim existing node: claimed_relative_id IS NOT NULL, no proposed_*
  --    (b) "add me": claimed_relative_id IS NULL, proposed_full_name IS NOT NULL,
  --        AND edge_path is restricted to direct relationships.
  IF p_claimed_relative_id IS NOT NULL THEN
    IF p_proposed_full_name IS NOT NULL THEN
      RAISE EXCEPTION 'لا يمكن تقديم اسم جديد عند المطالبة بعقدة موجودة';
    END IF;

    -- Validate the claimed relative exists, belongs to group, not already claimed.
    SELECT id, is_self INTO v_target
    FROM relatives
    WHERE id = p_claimed_relative_id AND family_group_id = p_group_id;

    IF v_target IS NULL THEN
      RAISE EXCEPTION 'العقدة المطلوبة غير موجودة في الشجرة';
    END IF;

    IF v_target.is_self = true THEN
      RAISE EXCEPTION 'هذه العقدة مطالب بها بالفعل';
    END IF;

    IF EXISTS (
      SELECT 1 FROM family_group_members
      WHERE group_id = p_group_id AND relative_id_in_tree = p_claimed_relative_id
    ) THEN
      RAISE EXCEPTION 'هذه العقدة مرتبطة بعضو آخر بالفعل';
    END IF;
  ELSE
    -- "Add me" path.
    IF p_proposed_full_name IS NULL OR trim(p_proposed_full_name) = '' THEN
      RAISE EXCEPTION 'الاسم مطلوب لإضافتك للشجرة';
    END IF;
    IF p_edge_path NOT IN ('parent', 'child', 'spouse', 'sibling') THEN
      RAISE EXCEPTION 'إضافة عضو جديد متاحة فقط للقرابة المباشرة (والد، ولد، زوج، أخ/أخت)';
    END IF;
  END IF;

  -- 5. Insert claim. The unique partial index will reject duplicate pending
  --    claims by the same user in the same group.
  INSERT INTO node_claims (
    group_id,
    claimant_user_id,
    claimed_relative_id,
    declared_anchor_relative_id,
    declared_edge_path,
    declared_parent_side,
    declared_gender,
    proposed_full_name,
    proposed_gender,
    proposed_birth_year,
    proposed_city,
    proposed_photo_url,
    status
  )
  VALUES (
    p_group_id,
    v_caller_id,
    p_claimed_relative_id,
    p_anchor_relative_id,
    p_edge_path,
    p_parent_side,
    p_gender,
    NULLIF(trim(p_proposed_full_name), ''),
    p_proposed_gender,
    p_proposed_birth_year,
    NULLIF(trim(p_proposed_city), ''),
    NULLIF(trim(p_proposed_photo_url), ''),
    'pending'
  )
  RETURNING * INTO v_claim;

  RETURN jsonb_build_object(
    'id', v_claim.id,
    'group_id', v_claim.group_id,
    'claimant_user_id', v_claim.claimant_user_id,
    'claimed_relative_id', v_claim.claimed_relative_id,
    'declared_anchor_relative_id', v_claim.declared_anchor_relative_id,
    'declared_edge_path', v_claim.declared_edge_path,
    'declared_parent_side', v_claim.declared_parent_side,
    'declared_gender', v_claim.declared_gender,
    'proposed_full_name', v_claim.proposed_full_name,
    'status', v_claim.status,
    'created_at', v_claim.created_at
  );
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'لديك طلب معلق في هذه المجموعة بالفعل';
END;
$$;

GRANT EXECUTE ON FUNCTION create_node_claim(
  UUID, UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT, INT, TEXT, TEXT
) TO authenticated;

-- ============================================================================
-- 2. approve_node_claim
-- ============================================================================
-- Returns the relative_id that the claimant is now linked to (existing or
-- newly-created). Caller (Dart) should follow up with verifySharedEdges().
-- ============================================================================

CREATE OR REPLACE FUNCTION approve_node_claim(p_claim_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_claim RECORD;
  v_target_relative_id UUID;
  v_relationship_type TEXT;
  v_family_side TEXT;
  v_admin_member RECORD;
BEGIN
  -- 1. Lock the claim row.
  SELECT * INTO v_claim
  FROM node_claims
  WHERE id = p_claim_id
  FOR UPDATE;

  IF v_claim IS NULL THEN
    RAISE EXCEPTION 'الطلب غير موجود';
  END IF;

  IF v_claim.status != 'pending' THEN
    RAISE EXCEPTION 'لا يمكن تأكيد طلب غير معلق';
  END IF;

  -- 2. Validate caller is admin of the claim's group.
  SELECT id, role INTO v_admin_member
  FROM family_group_members
  WHERE group_id = v_claim.group_id AND user_id = v_caller_id;

  IF v_admin_member IS NULL OR v_admin_member.role != 'admin' THEN
    RAISE EXCEPTION 'فقط مسؤول المجموعة يمكنه تأكيد الطلبات';
  END IF;

  -- 3. Determine the target relative_id:
  --    - existing-node path: use claimed_relative_id
  --    - "add me" path: insert a new relatives row first
  IF v_claim.claimed_relative_id IS NOT NULL THEN
    v_target_relative_id := v_claim.claimed_relative_id;

    -- Defensive: re-check the target isn't already claimed.
    IF EXISTS (
      SELECT 1 FROM relatives
      WHERE id = v_target_relative_id AND is_self = true
    ) THEN
      RAISE EXCEPTION 'هذه العقدة مطالب بها من قبل';
    END IF;
    IF EXISTS (
      SELECT 1 FROM family_group_members
      WHERE group_id = v_claim.group_id
        AND relative_id_in_tree = v_target_relative_id
        AND user_id != v_claim.claimant_user_id
    ) THEN
      RAISE EXCEPTION 'هذه العقدة مرتبطة بعضو آخر';
    END IF;
  ELSE
    -- "Add me" path. Map (edge_path, gender) → relationship_type.
    -- Map parent_side → family_side (only for paths that have a side).
    v_relationship_type := CASE
      WHEN v_claim.declared_edge_path = 'parent' AND v_claim.declared_gender = 'male'   THEN 'father'
      WHEN v_claim.declared_edge_path = 'parent' AND v_claim.declared_gender = 'female' THEN 'mother'
      WHEN v_claim.declared_edge_path = 'child'  AND v_claim.declared_gender = 'male'   THEN 'son'
      WHEN v_claim.declared_edge_path = 'child'  AND v_claim.declared_gender = 'female' THEN 'daughter'
      WHEN v_claim.declared_edge_path = 'spouse' AND v_claim.declared_gender = 'male'   THEN 'husband'
      WHEN v_claim.declared_edge_path = 'spouse' AND v_claim.declared_gender = 'female' THEN 'wife'
      WHEN v_claim.declared_edge_path = 'sibling' AND v_claim.declared_gender = 'male'  THEN 'brother'
      WHEN v_claim.declared_edge_path = 'sibling' AND v_claim.declared_gender = 'female' THEN 'sister'
      ELSE NULL
    END;

    IF v_relationship_type IS NULL THEN
      RAISE EXCEPTION 'لا يمكن إنشاء عقدة جديدة لهذه القرابة (يجب اختيار شخص موجود في الشجرة)';
    END IF;

    v_family_side := v_claim.declared_parent_side;  -- may be NULL

    -- Insert the new relative. The Dart caller will follow up with
    -- verifySharedEdges() to materialize family_edges.
    INSERT INTO relatives (
      user_id,
      full_name,
      relationship_type,
      gender,
      family_group_id,
      family_side,
      added_by,
      relative_category,
      date_of_birth,
      city,
      photo_url
    )
    VALUES (
      v_claim.claimant_user_id,
      v_claim.proposed_full_name,
      v_relationship_type,
      COALESCE(v_claim.proposed_gender, v_claim.declared_gender),
      v_claim.group_id,
      v_family_side,
      v_caller_id,           -- admin as added_by
      'extended',
      CASE
        WHEN v_claim.proposed_birth_year IS NOT NULL
          THEN make_timestamptz(v_claim.proposed_birth_year, 1, 1, 0, 0, 0, 'UTC')
        ELSE NULL
      END,
      v_claim.proposed_city,
      v_claim.proposed_photo_url
    )
    RETURNING id INTO v_target_relative_id;
  END IF;

  -- 4. Apply the claim mechanic on v_target_relative_id.
  --    Mirrors claim_tree_node: is_self=true, user_id=claimant.
  UPDATE relatives
  SET is_self = true,
      user_id = v_claim.claimant_user_id
  WHERE id = v_target_relative_id;

  --    Link membership.
  UPDATE family_group_members
  SET relative_id_in_tree = v_target_relative_id
  WHERE group_id = v_claim.group_id
    AND user_id = v_claim.claimant_user_id;

  -- 5. Mark claim approved.
  UPDATE node_claims
  SET status = 'approved',
      decided_by = v_caller_id,
      decided_at = now()
  WHERE id = p_claim_id;

  RETURN jsonb_build_object(
    'claim_id', p_claim_id,
    'group_id', v_claim.group_id,
    'claimant_user_id', v_claim.claimant_user_id,
    'relative_id', v_target_relative_id,
    'created_new_node', (v_claim.claimed_relative_id IS NULL)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION approve_node_claim(UUID) TO authenticated;

-- ============================================================================
-- 3. reject_node_claim
-- ============================================================================

CREATE OR REPLACE FUNCTION reject_node_claim(
  p_claim_id UUID,
  p_reason TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_claim RECORD;
BEGIN
  SELECT * INTO v_claim
  FROM node_claims
  WHERE id = p_claim_id
  FOR UPDATE;

  IF v_claim IS NULL THEN
    RAISE EXCEPTION 'الطلب غير موجود';
  END IF;

  IF v_claim.status != 'pending' THEN
    RAISE EXCEPTION 'لا يمكن رفض طلب غير معلق';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM family_group_members
    WHERE group_id = v_claim.group_id AND user_id = v_caller_id AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'فقط مسؤول المجموعة يمكنه رفض الطلبات';
  END IF;

  UPDATE node_claims
  SET status = 'rejected',
      rejection_reason = NULLIF(trim(p_reason), ''),
      decided_by = v_caller_id,
      decided_at = now()
  WHERE id = p_claim_id;
END;
$$;

GRANT EXECUTE ON FUNCTION reject_node_claim(UUID, TEXT) TO authenticated;

-- ============================================================================
-- 4. cancel_node_claim (claimant-only)
-- ============================================================================

CREATE OR REPLACE FUNCTION cancel_node_claim(p_claim_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_claim RECORD;
BEGIN
  SELECT * INTO v_claim
  FROM node_claims
  WHERE id = p_claim_id
  FOR UPDATE;

  IF v_claim IS NULL THEN
    RAISE EXCEPTION 'الطلب غير موجود';
  END IF;

  IF v_claim.claimant_user_id != v_caller_id THEN
    RAISE EXCEPTION 'يمكنك إلغاء طلبك فقط';
  END IF;

  IF v_claim.status != 'pending' THEN
    RAISE EXCEPTION 'لا يمكن إلغاء طلب غير معلق';
  END IF;

  UPDATE node_claims
  SET status = 'cancelled',
      decided_at = now()
  WHERE id = p_claim_id;
END;
$$;

GRANT EXECUTE ON FUNCTION cancel_node_claim(UUID) TO authenticated;

-- ============================================================================
-- 5. snooze_node_claim (admin "let me think later")
-- ============================================================================
-- Hides the claim from the admin queue until p_until. Claim stays pending;
-- claimant's pending state is unaffected. Admin can snooze repeatedly.
-- ============================================================================

CREATE OR REPLACE FUNCTION snooze_node_claim(
  p_claim_id UUID,
  p_until TIMESTAMPTZ
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_claim RECORD;
BEGIN
  SELECT * INTO v_claim
  FROM node_claims
  WHERE id = p_claim_id
  FOR UPDATE;

  IF v_claim IS NULL THEN
    RAISE EXCEPTION 'الطلب غير موجود';
  END IF;

  IF v_claim.status != 'pending' THEN
    RAISE EXCEPTION 'لا يمكن تأجيل طلب غير معلق';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM family_group_members
    WHERE group_id = v_claim.group_id AND user_id = v_caller_id AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'فقط مسؤول المجموعة يمكنه تأجيل الطلبات';
  END IF;

  IF p_until <= now() THEN
    RAISE EXCEPTION 'وقت التأجيل يجب أن يكون في المستقبل';
  END IF;

  UPDATE node_claims
  SET snoozed_until = p_until
  WHERE id = p_claim_id;
END;
$$;

GRANT EXECUTE ON FUNCTION snooze_node_claim(UUID, TIMESTAMPTZ) TO authenticated;

-- ============================================================================
-- 6. get_my_pending_claims (joiner side)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_my_pending_claims()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_result JSONB;
BEGIN
  SELECT COALESCE(jsonb_agg(row_data), '[]'::jsonb)
  INTO v_result
  FROM (
    SELECT jsonb_build_object(
      'id', nc.id,
      'group_id', nc.group_id,
      'group_name', fg.name,
      'claimed_relative_id', nc.claimed_relative_id,
      'claimed_relative_name', cr.full_name,
      'declared_anchor_relative_id', nc.declared_anchor_relative_id,
      'declared_anchor_name', ar.full_name,
      'declared_edge_path', nc.declared_edge_path,
      'declared_parent_side', nc.declared_parent_side,
      'declared_gender', nc.declared_gender,
      'proposed_full_name', nc.proposed_full_name,
      'status', nc.status,
      'created_at', nc.created_at
    ) AS row_data
    FROM node_claims nc
    JOIN family_groups fg ON fg.id = nc.group_id
    LEFT JOIN relatives cr ON cr.id = nc.claimed_relative_id
    LEFT JOIN relatives ar ON ar.id = nc.declared_anchor_relative_id
    WHERE nc.claimant_user_id = v_caller_id
      AND nc.status = 'pending'
    ORDER BY nc.created_at DESC
  ) sub;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION get_my_pending_claims() TO authenticated;

-- ============================================================================
-- 7. get_group_pending_claims (admin side)
-- ============================================================================
-- Excludes claims whose snoozed_until is in the future.
-- ============================================================================

CREATE OR REPLACE FUNCTION get_group_pending_claims(p_group_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_result JSONB;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM family_group_members
    WHERE group_id = p_group_id AND user_id = v_caller_id AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'فقط مسؤول المجموعة يمكنه عرض الطلبات';
  END IF;

  SELECT COALESCE(jsonb_agg(row_data), '[]'::jsonb)
  INTO v_result
  FROM (
    SELECT jsonb_build_object(
      'id', nc.id,
      'claimant_user_id', nc.claimant_user_id,
      'claimant_name', COALESCE(
        u.raw_user_meta_data ->> 'full_name',
        u.raw_user_meta_data ->> 'name',
        'مستخدم'
      ),
      'claimed_relative_id', nc.claimed_relative_id,
      'claimed_relative_name', cr.full_name,
      'declared_anchor_relative_id', nc.declared_anchor_relative_id,
      'declared_anchor_name', ar.full_name,
      'declared_edge_path', nc.declared_edge_path,
      'declared_parent_side', nc.declared_parent_side,
      'declared_gender', nc.declared_gender,
      'proposed_full_name', nc.proposed_full_name,
      'proposed_gender', nc.proposed_gender,
      'proposed_birth_year', nc.proposed_birth_year,
      'proposed_city', nc.proposed_city,
      'proposed_photo_url', nc.proposed_photo_url,
      'created_at', nc.created_at,
      'snoozed_until', nc.snoozed_until
    ) AS row_data
    FROM node_claims nc
    LEFT JOIN auth.users u ON u.id = nc.claimant_user_id
    LEFT JOIN relatives cr ON cr.id = nc.claimed_relative_id
    LEFT JOIN relatives ar ON ar.id = nc.declared_anchor_relative_id
    WHERE nc.group_id = p_group_id
      AND nc.status = 'pending'
      AND (nc.snoozed_until IS NULL OR nc.snoozed_until <= now())
    ORDER BY nc.created_at DESC
  ) sub;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION get_group_pending_claims(UUID) TO authenticated;

-- ============================================================================
-- Self-verification
-- ============================================================================

DO $$
DECLARE
  v_fns TEXT[] := ARRAY[
    'create_node_claim',
    'approve_node_claim',
    'reject_node_claim',
    'cancel_node_claim',
    'snooze_node_claim',
    'get_my_pending_claims',
    'get_group_pending_claims'
  ];
  v_fn TEXT;
BEGIN
  FOREACH v_fn IN ARRAY v_fns LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_proc p
      JOIN pg_namespace n ON p.pronamespace = n.oid
      WHERE n.nspname = 'public' AND p.proname = v_fn
    ) THEN
      RAISE EXCEPTION 'Missing RPC: %', v_fn;
    END IF;
  END LOOP;
END $$;
