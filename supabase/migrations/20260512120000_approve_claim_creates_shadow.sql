-- ============================================================================
-- 20260512120000_approve_claim_creates_shadow.sql
-- ============================================================================
-- approve_node_claim now also creates a personal-scope shadow of the
-- ANCHOR on the claimant's personal side. This makes the relationship
-- visible to the claimant everywhere they view (personal mode, other
-- groups, address book).
--
-- Shadows are only created for DIRECT relationships in v1:
-- parent / child / spouse / sibling. Extended relations (uncle/cousin/etc.)
-- come through the claim flow but are not shadowed yet.
--
-- Idempotency: the shadow INSERT is guarded by an EXISTS check on
-- (user_id, mirrors_relative_id, family_group_id IS NULL) so re-running
-- approve (after a hypothetical reject + reapprove cycle) is safe.
--
-- All existing function behavior is preserved verbatim: admin auth,
-- target-relative resolution (Path A / Path B), is_self flip, membership
-- upsert, in-group family_edges, status update, claim_approved notification.
-- ============================================================================

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
  -- NEW: locals for personal-shadow projection
  v_anchor_relative RECORD;
  v_claimant_personal_self_id UUID;
  v_shadow_relationship_type TEXT;
  v_shadow_id UUID;
  v_edge_type TEXT;
  v_edge_from TEXT;
  v_edge_to TEXT;
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

  INSERT INTO family_group_members (group_id, user_id, role, relative_id_in_tree)
  VALUES (v_claim.group_id, v_claim.claimant_user_id, 'member', v_target_relative_id)
  ON CONFLICT (group_id, user_id)
  DO UPDATE SET relative_id_in_tree = EXCLUDED.relative_id_in_tree;

  IF v_claim.claimed_relative_id IS NULL THEN
    IF v_claim.declared_edge_path = 'spouse' THEN
      INSERT INTO family_edges (user_id, from_id, to_id, edge_type, family_group_id)
      VALUES (v_caller_id, v_anchor_id::text, v_target_relative_id::text,
              'spouse_of', v_claim.group_id)
      ON CONFLICT (user_id, from_id, to_id, edge_type) DO NOTHING;
    ELSIF v_claim.declared_edge_path = 'parent' THEN
      INSERT INTO family_edges (user_id, from_id, to_id, edge_type, family_group_id)
      VALUES (v_caller_id, v_target_relative_id::text, v_anchor_id::text,
              'parent_of', v_claim.group_id)
      ON CONFLICT (user_id, from_id, to_id, edge_type) DO NOTHING;
    ELSIF v_claim.declared_edge_path = 'child' THEN
      INSERT INTO family_edges (user_id, from_id, to_id, edge_type, family_group_id)
      VALUES (v_caller_id, v_anchor_id::text, v_target_relative_id::text,
              'parent_of', v_claim.group_id)
      ON CONFLICT (user_id, from_id, to_id, edge_type) DO NOTHING;
    ELSIF v_claim.declared_edge_path = 'sibling' THEN
      INSERT INTO family_edges (user_id, from_id, to_id, edge_type, family_group_id)
      VALUES (v_caller_id, v_anchor_id::text, v_target_relative_id::text,
              'sibling_of', v_claim.group_id)
      ON CONFLICT (user_id, from_id, to_id, edge_type) DO NOTHING;
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

  -- Notify the claimant that their request was approved.
  PERFORM public._notify_claim_status(
    v_claim.claimant_user_id, v_claim.group_id, 'claim_approved'
  );

  -- ==========================================================================
  -- NEW: Personal-shadow projection.
  -- ==========================================================================
  -- For direct relationships (parent/child/spouse/sibling) we create a
  -- personal NULL-scope shadow of the ANCHOR on the CLAIMANT's side, with
  -- mirrors_relative_id pointing to the canonical anchor row. This makes
  -- the relationship visible to the claimant in personal mode, other
  -- groups, and the address book — without duplicating the anchor's
  -- canonical data (the merge logic in groupTreeRelativesProvider handles
  -- rendering by following mirrors_relative_id).
  --
  -- Extended relations (uncle / cousin / nephew / grandparent / grandchild)
  -- are intentionally NOT shadowed in v1. The direct cases are the
  -- high-value targets.
  --
  -- Idempotent: re-running approve does not double-insert. Guarded by an
  -- EXISTS check on (user_id, mirrors_relative_id, NULL family_group_id).
  -- ==========================================================================
  IF v_claim.declared_edge_path IN ('parent', 'child', 'spouse', 'sibling') THEN
    -- Fetch anchor's canonical metadata.
    SELECT id, full_name, gender, user_id
      INTO v_anchor_relative
      FROM relatives
     WHERE id = v_claim.declared_anchor_relative_id;

    -- Find claimant's personal NULL-scope self-node.
    SELECT id INTO v_claimant_personal_self_id
      FROM relatives
     WHERE user_id = v_claim.claimant_user_id
       AND is_self = true
       AND family_group_id IS NULL
     LIMIT 1;

    -- Defensive: only project if both sides resolved.
    IF v_anchor_relative.id IS NOT NULL
       AND v_claimant_personal_self_id IS NOT NULL THEN

      -- Inverse relationship: anchor's role in claimant's personal scope.
      -- declared_edge_path describes the claimant's relationship TO the anchor.
      v_shadow_relationship_type := CASE v_claim.declared_edge_path
        WHEN 'spouse' THEN
          CASE WHEN v_anchor_relative.gender = 'male' THEN 'husband' ELSE 'wife' END
        WHEN 'parent' THEN
          -- claimant is parent OF anchor => anchor is claimant's child
          CASE WHEN v_anchor_relative.gender = 'male' THEN 'son' ELSE 'daughter' END
        WHEN 'child' THEN
          -- claimant is child OF anchor => anchor is claimant's parent
          CASE WHEN v_anchor_relative.gender = 'male' THEN 'father' ELSE 'mother' END
        WHEN 'sibling' THEN
          CASE WHEN v_anchor_relative.gender = 'male' THEN 'brother' ELSE 'sister' END
      END;

      -- Idempotency guard: skip if shadow already exists.
      IF NOT EXISTS (
        SELECT 1 FROM relatives sh
        WHERE sh.user_id = v_claim.claimant_user_id
          AND sh.mirrors_relative_id = v_anchor_relative.id
          AND sh.family_group_id IS NULL
      ) THEN
        -- Insert shadow row. Direct relations are 'household', priority 1.
        INSERT INTO relatives (
          user_id, full_name, relationship_type, gender,
          family_group_id, is_self, added_by, mirrors_relative_id,
          relative_category, priority
        ) VALUES (
          v_claim.claimant_user_id,
          v_anchor_relative.full_name,
          v_shadow_relationship_type,
          v_anchor_relative.gender,
          NULL,                           -- personal scope
          false,                          -- not the claimant's self
          v_caller_id,                    -- approving admin
          v_anchor_relative.id,           -- canonical pointer
          'household',                    -- direct relations
          1                               -- high priority
        )
        RETURNING id INTO v_shadow_id;

        -- Edge type + direction.
        v_edge_type := CASE v_claim.declared_edge_path
          WHEN 'spouse' THEN 'spouse_of'
          WHEN 'sibling' THEN 'sibling_of'
          ELSE 'parent_of'
        END;

        IF v_claim.declared_edge_path = 'child' THEN
          -- claimant is child of anchor; anchor (=shadow) is parent.
          -- parent_of: from parent -> to child
          v_edge_from := v_shadow_id::text;
          v_edge_to := v_claimant_personal_self_id::text;
        ELSIF v_claim.declared_edge_path = 'parent' THEN
          -- claimant is parent of anchor; shadow (=anchor) is child.
          v_edge_from := v_claimant_personal_self_id::text;
          v_edge_to := v_shadow_id::text;
        ELSE
          -- spouse / sibling: symmetric. Canonical direction: self -> shadow.
          v_edge_from := v_claimant_personal_self_id::text;
          v_edge_to := v_shadow_id::text;
        END IF;

        INSERT INTO family_edges (
          user_id, from_id, to_id, edge_type, family_group_id
        ) VALUES (
          v_claim.claimant_user_id,       -- edge owned by claimant
          v_edge_from, v_edge_to, v_edge_type,
          NULL                            -- personal scope
        )
        ON CONFLICT (user_id, from_id, to_id, edge_type) DO NOTHING;
      END IF;
    END IF;
  END IF;
  -- ==========================================================================
  -- END personal-shadow projection.
  -- ==========================================================================

  RETURN jsonb_build_object(
    'claim_id', p_claim_id,
    'group_id', v_claim.group_id,
    'claimant_user_id', v_claim.claimant_user_id,
    'relative_id', v_target_relative_id,
    'created_new_node', (v_claim.claimed_relative_id IS NULL)
  );
END;
$function$;

GRANT EXECUTE ON FUNCTION public.approve_node_claim(UUID) TO authenticated;
