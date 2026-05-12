-- 20260514200000_approve_preserves_prior_owner_shadow.sql
-- When Path A promotes a SHADOW (not a regular existing relative) into
-- the target group, the prior owner of that shadow loses their
-- representation of the promoted person. This regenerates a fresh
-- shadow on the prior owner's side so their personal-mode tree,
-- relatives list, and home carousel still surface that relationship.

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
  v_anchor_relative RECORD;
  v_claimant_personal_self_id UUID;
  v_shadow_relationship_type TEXT;
  v_shadow_id UUID;
  v_edge_type TEXT;
  v_edge_from TEXT;
  v_edge_to TEXT;
  v_effective_anchor_gender TEXT;
  -- NEW: prior-owner capture for shadow-promotion preservation
  v_target_prior_mirrored UUID;
  v_target_prior_owner UUID;
  v_target_prior_rel_type TEXT;
  v_target_prior_gender TEXT;
  v_target_prior_full_name TEXT;
  v_new_prior_shadow_id UUID;
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

  -- NEW: capture prior state of the target row BEFORE the promotion UPDATE.
  -- Used downstream to detect "was a shadow owned by someone other than the
  -- claimant" and regenerate a personal-scope shadow on the prior owner's side.
  SELECT mirrors_relative_id, user_id, relationship_type, gender, full_name
    INTO v_target_prior_mirrored, v_target_prior_owner,
         v_target_prior_rel_type, v_target_prior_gender, v_target_prior_full_name
    FROM relatives
   WHERE id = v_target_relative_id;

  UPDATE relatives
  SET is_self = true,
      user_id = v_claim.claimant_user_id,
      family_group_id = v_claim.group_id,
      mirrors_relative_id = NULL,
      updated_at = NOW()
  WHERE id = v_target_relative_id;

  -- NEW: if the target WAS a shadow AND the prior owner is NOT the claimant,
  -- recreate a shadow on the prior owner's side so they still have a
  -- personal-scope representation of this person, and re-anchor their
  -- personal-scope edges to that new shadow.
  IF v_target_prior_mirrored IS NOT NULL
     AND v_target_prior_owner IS NOT NULL
     AND v_target_prior_owner <> v_claim.claimant_user_id THEN
    INSERT INTO relatives (
      user_id, full_name, gender, relationship_type, family_group_id,
      is_self, added_by, mirrors_relative_id, relative_category, priority
    ) VALUES (
      v_target_prior_owner,
      v_target_prior_full_name,
      v_target_prior_gender,
      v_target_prior_rel_type,
      NULL,
      false,
      v_claim.claimant_user_id,
      v_target_relative_id,
      'household',
      1
    )
    RETURNING id INTO v_new_prior_shadow_id;

    UPDATE family_edges
       SET from_id = v_new_prior_shadow_id::text
     WHERE user_id = v_target_prior_owner
       AND family_group_id IS NULL
       AND from_id = v_target_relative_id::text;

    UPDATE family_edges
       SET to_id = v_new_prior_shadow_id::text
     WHERE user_id = v_target_prior_owner
       AND family_group_id IS NULL
       AND to_id = v_target_relative_id::text;
  END IF;

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

  PERFORM public._notify_claim_status(
    v_claim.claimant_user_id, v_claim.group_id, 'claim_approved'
  );

  IF v_claim.declared_edge_path IN ('parent', 'child', 'spouse', 'sibling') THEN
    SELECT id, full_name, gender, user_id
      INTO v_anchor_relative
      FROM relatives
     WHERE id = v_claim.declared_anchor_relative_id;

    SELECT id INTO v_claimant_personal_self_id
      FROM relatives
     WHERE user_id = v_claim.claimant_user_id
       AND is_self = true
       AND family_group_id IS NULL
     LIMIT 1;

    v_effective_anchor_gender := v_anchor_relative.gender;
    IF v_effective_anchor_gender IS NULL
       AND v_claim.declared_edge_path = 'spouse'
       AND v_claim.declared_gender IN ('male', 'female') THEN
      v_effective_anchor_gender := CASE v_claim.declared_gender
        WHEN 'male' THEN 'female'
        WHEN 'female' THEN 'male'
      END;

      UPDATE relatives
         SET gender = v_effective_anchor_gender, updated_at = NOW()
       WHERE id = v_anchor_relative.id
         AND gender IS NULL;
    END IF;

    IF v_anchor_relative.id IS NOT NULL
       AND v_claimant_personal_self_id IS NOT NULL
       AND v_effective_anchor_gender IS NOT NULL THEN

      v_shadow_relationship_type := CASE v_claim.declared_edge_path
        WHEN 'spouse' THEN
          CASE WHEN v_effective_anchor_gender = 'male' THEN 'husband' ELSE 'wife' END
        WHEN 'parent' THEN
          CASE WHEN v_effective_anchor_gender = 'male' THEN 'son' ELSE 'daughter' END
        WHEN 'child' THEN
          CASE WHEN v_effective_anchor_gender = 'male' THEN 'father' ELSE 'mother' END
        WHEN 'sibling' THEN
          CASE WHEN v_effective_anchor_gender = 'male' THEN 'brother' ELSE 'sister' END
      END;

      IF NOT EXISTS (
        SELECT 1 FROM relatives sh
        WHERE sh.user_id = v_claim.claimant_user_id
          AND sh.mirrors_relative_id = v_anchor_relative.id
          AND sh.family_group_id IS NULL
      ) THEN
        INSERT INTO relatives (
          user_id, full_name, relationship_type, gender,
          family_group_id, is_self, added_by, mirrors_relative_id,
          relative_category, priority
        ) VALUES (
          v_claim.claimant_user_id,
          v_anchor_relative.full_name,
          v_shadow_relationship_type,
          v_effective_anchor_gender,
          NULL,
          false,
          v_caller_id,
          v_anchor_relative.id,
          'household',
          1
        )
        RETURNING id INTO v_shadow_id;

        v_edge_type := CASE v_claim.declared_edge_path
          WHEN 'spouse' THEN 'spouse_of'
          WHEN 'sibling' THEN 'sibling_of'
          ELSE 'parent_of'
        END;

        IF v_claim.declared_edge_path = 'child' THEN
          v_edge_from := v_shadow_id::text;
          v_edge_to := v_claimant_personal_self_id::text;
        ELSIF v_claim.declared_edge_path = 'parent' THEN
          v_edge_from := v_claimant_personal_self_id::text;
          v_edge_to := v_shadow_id::text;
        ELSE
          v_edge_from := v_claimant_personal_self_id::text;
          v_edge_to := v_shadow_id::text;
        END IF;

        INSERT INTO family_edges (
          user_id, from_id, to_id, edge_type, family_group_id
        ) VALUES (
          v_claim.claimant_user_id,
          v_edge_from, v_edge_to, v_edge_type,
          NULL
        )
        ON CONFLICT (user_id, from_id, to_id, edge_type) DO NOTHING;
      END IF;
    END IF;
  END IF;

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

-- One-shot restore: testprodjoiner lost her shadow of testprod when
-- testprod's claim was approved via the shadow path (before this fix).
-- Re-create it pointing at testprod's test-group self (the row that was
-- formerly her shadow). Idempotent — guarded on NOT EXISTS.

DO $$
DECLARE
  v_joiner UUID := '6251e7f6-445d-4954-a9c0-d430ae93cc48';
  v_testprod UUID := '8b3be95f-8c18-482e-848c-f5db4b6e3afd';
  v_old_shadow_now_in_test UUID := '0de0e240-d88a-4132-9cd7-196223d1f3b0';
  v_joiner_personal_self UUID := '633000bb-2615-433c-b714-82e659f1103f';
  v_new_shadow_id UUID;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM relatives
    WHERE user_id = v_joiner
      AND mirrors_relative_id IS NOT NULL
      AND family_group_id IS NULL
  ) THEN
    INSERT INTO relatives (
      user_id, full_name, gender, relationship_type, family_group_id,
      is_self, added_by, mirrors_relative_id, relative_category, priority
    ) VALUES (
      v_joiner, 'testprod', 'male', 'husband', NULL,
      false, v_testprod, v_old_shadow_now_in_test, 'household', 1
    )
    RETURNING id INTO v_new_shadow_id;

    UPDATE family_edges
       SET to_id = v_new_shadow_id::text
     WHERE user_id = v_joiner
       AND family_group_id IS NULL
       AND from_id = v_joiner_personal_self::text
       AND edge_type = 'spouse_of'
       AND to_id = v_old_shadow_now_in_test::text;

    RAISE NOTICE 'Restored testprodjoiner shadow of testprod: %', v_new_shadow_id;
  END IF;
END $$;
