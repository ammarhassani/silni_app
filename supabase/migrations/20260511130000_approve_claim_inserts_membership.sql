-- 20260511130000_approve_claim_inserts_membership.sql
--
-- approve_node_claim becomes the sole creator of family_group_members rows
-- for joiners. Today the function UPDATEs an existing membership row to set
-- relative_id_in_tree. After the wider refactor (Tasks 1-3), the joiner
-- reaches the approve step WITHOUT a membership row, so the RPC must INSERT
-- one atomically when approving.
--
-- Change is surgical: only the membership write is swapped from UPDATE to
-- INSERT ... ON CONFLICT DO UPDATE. The unique constraint
-- family_group_members_group_id_user_id_key (group_id, user_id) makes this
-- a valid conflict target and keeps the behavior idempotent: re-running
-- approval against a pre-existing membership row simply re-points it to the
-- claimed relative.
--
-- All edge-insertion logic from 20260510134804_approve_node_claim_inserts_edges
-- is preserved inline, matching the existing style. No _insert_claim_edges
-- helper exists in pg_proc; we do not introduce one here.
--
-- Reconciled column names against the live schema:
--   node_claims:     decided_by (not decided_by_user_id), decided_at, status,
--                    declared_anchor_relative_id, declared_edge_path,
--                    declared_parent_side, declared_gender,
--                    proposed_full_name, proposed_gender,
--                    proposed_birth_year (integer), proposed_city,
--                    proposed_photo_url, proposed_phone_number,
--                    claimed_relative_id, claimant_user_id, group_id.
--   relatives:       date_of_birth (timestamptz, not birth_year),
--                    family_side, added_by, relative_category, is_self.
--   family_group_members: unique (group_id, user_id) — confirmed.

CREATE OR REPLACE FUNCTION public.approve_node_claim(p_claim_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_caller_id UUID := auth.uid();
  v_claim RECORD;
  v_target_relative_id UUID;
  v_relationship_type TEXT;
  v_admin_member RECORD;
  v_anchor_id UUID;
BEGIN
  SELECT * INTO v_claim FROM node_claims WHERE id = p_claim_id FOR UPDATE;
  IF v_claim IS NULL THEN
    RAISE EXCEPTION 'الطلب غير موجود';
  END IF;
  IF v_claim.status != 'pending' THEN
    RAISE EXCEPTION 'لا يمكن تأكيد طلب غير معلق';
  END IF;
  SELECT id, role INTO v_admin_member
  FROM family_group_members
  WHERE group_id = v_claim.group_id AND user_id = v_caller_id;
  IF v_admin_member IS NULL OR v_admin_member.role != 'admin' THEN
    RAISE EXCEPTION 'فقط مسؤول المجموعة يمكنه تأكيد الطلبات';
  END IF;

  v_anchor_id := v_claim.declared_anchor_relative_id;

  IF v_claim.claimed_relative_id IS NOT NULL THEN
    v_target_relative_id := v_claim.claimed_relative_id;
    IF EXISTS (SELECT 1 FROM relatives WHERE id = v_target_relative_id AND is_self = true) THEN
      RAISE EXCEPTION 'هذه العقدة مطالب بها من قبل';
    END IF;
    IF EXISTS (
      SELECT 1 FROM family_group_members
      WHERE group_id = v_claim.group_id AND relative_id_in_tree = v_target_relative_id
        AND user_id != v_claim.claimant_user_id
    ) THEN
      RAISE EXCEPTION 'هذه العقدة مرتبطة بعضو آخر';
    END IF;
  ELSE
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

    INSERT INTO relatives (
      user_id, full_name, relationship_type, gender,
      family_group_id, family_side, added_by, relative_category,
      date_of_birth, city, photo_url
    )
    VALUES (
      v_claim.claimant_user_id,
      v_claim.proposed_full_name,
      v_relationship_type,
      COALESCE(v_claim.proposed_gender, v_claim.declared_gender),
      v_claim.group_id,
      v_claim.declared_parent_side,
      v_caller_id,
      'extended',
      CASE WHEN v_claim.proposed_birth_year IS NOT NULL
           THEN make_timestamptz(v_claim.proposed_birth_year, 1, 1, 0, 0, 0, 'UTC')
           ELSE NULL END,
      v_claim.proposed_city,
      v_claim.proposed_photo_url
    )
    RETURNING id INTO v_target_relative_id;
  END IF;

  UPDATE relatives
  SET is_self = true, user_id = v_claim.claimant_user_id
  WHERE id = v_target_relative_id;

  -- ▼ ATOMIC MEMBERSHIP INSERT — the heart of this refactor ▼
  -- INSERT if missing (new joiner path post-Task 1-3 refactor), otherwise
  -- just update relative_id_in_tree (backwards-compat with legacy flow that
  -- created the membership row at join time).
  INSERT INTO family_group_members (group_id, user_id, role, relative_id_in_tree)
  VALUES (v_claim.group_id, v_claim.claimant_user_id, 'member', v_target_relative_id)
  ON CONFLICT (group_id, user_id)
  DO UPDATE SET relative_id_in_tree = EXCLUDED.relative_id_in_tree;

  -- Wire the new (or claimed) node into the family graph. Edges live in
  -- family_edges with from_id/to_id as TEXT (not UUID) per the original
  -- schema. Idempotent via the existing unique index
  -- (user_id, from_id, to_id, edge_type).
  IF v_claim.claimed_relative_id IS NULL THEN
    -- Add-me path: only direct relationships are allowed by create_node_claim
    -- (parent/child/spouse/sibling). Insert the matching edge.
    IF v_claim.declared_edge_path = 'spouse' THEN
      INSERT INTO family_edges (user_id, from_id, to_id, edge_type, family_group_id)
      VALUES (v_caller_id, v_anchor_id::text, v_target_relative_id::text,
              'spouse_of', v_claim.group_id)
      ON CONFLICT (user_id, from_id, to_id, edge_type) DO NOTHING;
    ELSIF v_claim.declared_edge_path = 'parent' THEN
      -- new relative is parent_of anchor
      INSERT INTO family_edges (user_id, from_id, to_id, edge_type, family_group_id)
      VALUES (v_caller_id, v_target_relative_id::text, v_anchor_id::text,
              'parent_of', v_claim.group_id)
      ON CONFLICT (user_id, from_id, to_id, edge_type) DO NOTHING;
    ELSIF v_claim.declared_edge_path = 'child' THEN
      -- anchor is parent_of new relative
      INSERT INTO family_edges (user_id, from_id, to_id, edge_type, family_group_id)
      VALUES (v_caller_id, v_anchor_id::text, v_target_relative_id::text,
              'parent_of', v_claim.group_id)
      ON CONFLICT (user_id, from_id, to_id, edge_type) DO NOTHING;
    ELSIF v_claim.declared_edge_path = 'sibling' THEN
      -- sibling_of link
      INSERT INTO family_edges (user_id, from_id, to_id, edge_type, family_group_id)
      VALUES (v_caller_id, v_anchor_id::text, v_target_relative_id::text,
              'sibling_of', v_claim.group_id)
      ON CONFLICT (user_id, from_id, to_id, edge_type) DO NOTHING;
      -- Also share the anchor's parents with the new sibling
      INSERT INTO family_edges (user_id, from_id, to_id, edge_type, family_group_id)
      SELECT v_caller_id, e.from_id, v_target_relative_id::text,
             'parent_of', v_claim.group_id
      FROM family_edges e
      WHERE e.to_id = v_anchor_id::text
        AND e.edge_type = 'parent_of'
        AND e.family_group_id = v_claim.group_id
      ON CONFLICT (user_id, from_id, to_id, edge_type) DO NOTHING;
    END IF;
  END IF;

  UPDATE node_claims
  SET status = 'approved', decided_by = v_caller_id, decided_at = now()
  WHERE id = p_claim_id;

  RETURN jsonb_build_object(
    'claim_id', p_claim_id,
    'group_id', v_claim.group_id,
    'claimant_user_id', v_claim.claimant_user_id,
    'relative_id', v_target_relative_id,
    'created_new_node', (v_claim.claimed_relative_id IS NULL)
  );
END;
$function$;
