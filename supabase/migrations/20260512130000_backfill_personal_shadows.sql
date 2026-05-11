-- 20260512130000_backfill_personal_shadows.sql
-- One-shot backfill of personal shadows for approved claims that
-- predate the shadow logic in 20260512120000 (Task 3).
--
-- For each approved direct-relationship claim (parent/child/spouse/
-- sibling) where the anchor has a known gender and the claimant doesn't
-- already have a shadow of the anchor, create:
--   1. A personal-scope relative row (the shadow) with the inverse
--      relationship_type from the claimant's POV
--   2. A personal-scope family_edge connecting the claimant's personal
--      self-node to the shadow
--
-- Idempotent — re-running on a clean state is a no-op.

DO $$
DECLARE
  rec RECORD;
  v_claimant_self_id UUID;
  v_shadow_id UUID;
  v_rel_type TEXT;
  v_edge_type TEXT;
  v_from TEXT;
  v_to TEXT;
  v_count INT := 0;
BEGIN
  FOR rec IN
    -- DISTINCT ON dedupes when a (claimant, anchor) pair has multiple
    -- approved claims (can happen if the wizard was re-submitted after
    -- a previous approval). Without this, the cursor returns N rows for
    -- the same logical relationship and the loop creates N duplicate
    -- shadows because the NOT EXISTS check is evaluated once at
    -- cursor-fetch time, before any iteration has inserted.
    SELECT DISTINCT ON (nc.claimant_user_id, nc.declared_anchor_relative_id)
           nc.claimant_user_id, nc.declared_anchor_relative_id,
           nc.declared_edge_path,
           r.full_name AS anchor_name,
           r.gender AS anchor_gender
    FROM node_claims nc
    JOIN relatives r ON r.id = nc.declared_anchor_relative_id
    WHERE nc.status = 'approved'
      AND r.gender IS NOT NULL
      AND nc.declared_edge_path IN ('parent','child','spouse','sibling')
      AND NOT EXISTS (
        SELECT 1 FROM relatives sh
        WHERE sh.user_id = nc.claimant_user_id
          AND sh.mirrors_relative_id = nc.declared_anchor_relative_id
          AND sh.family_group_id IS NULL
      )
    ORDER BY nc.claimant_user_id, nc.declared_anchor_relative_id, nc.decided_at DESC
  LOOP
    -- Claimant's personal self-node (guaranteed by Task 2)
    SELECT id INTO v_claimant_self_id
      FROM relatives
     WHERE user_id = rec.claimant_user_id
       AND is_self = true AND family_group_id IS NULL
     LIMIT 1;

    CONTINUE WHEN v_claimant_self_id IS NULL;

    v_rel_type := CASE rec.declared_edge_path
      WHEN 'spouse' THEN
        CASE WHEN rec.anchor_gender = 'male' THEN 'husband' ELSE 'wife' END
      WHEN 'parent' THEN
        CASE WHEN rec.anchor_gender = 'male' THEN 'son' ELSE 'daughter' END
      WHEN 'child' THEN
        CASE WHEN rec.anchor_gender = 'male' THEN 'father' ELSE 'mother' END
      WHEN 'sibling' THEN
        CASE WHEN rec.anchor_gender = 'male' THEN 'brother' ELSE 'sister' END
    END;

    INSERT INTO relatives (
      user_id, full_name, gender, relationship_type, family_group_id,
      is_self, added_by, mirrors_relative_id, relative_category, priority
    ) VALUES (
      rec.claimant_user_id, rec.anchor_name, rec.anchor_gender,
      v_rel_type, NULL, false,
      rec.claimant_user_id,  -- backfill uses claimant as added_by (admin not tracked here)
      rec.declared_anchor_relative_id, 'household', 1
    ) RETURNING id INTO v_shadow_id;

    v_edge_type := CASE rec.declared_edge_path
      WHEN 'spouse' THEN 'spouse_of'
      WHEN 'sibling' THEN 'sibling_of'
      ELSE 'parent_of'
    END;

    IF rec.declared_edge_path = 'child' THEN
      v_from := v_shadow_id::text;
      v_to := v_claimant_self_id::text;
    ELSIF rec.declared_edge_path = 'parent' THEN
      v_from := v_claimant_self_id::text;
      v_to := v_shadow_id::text;
    ELSE
      v_from := v_claimant_self_id::text;
      v_to := v_shadow_id::text;
    END IF;

    INSERT INTO family_edges (user_id, from_id, to_id, edge_type, family_group_id)
    VALUES (rec.claimant_user_id, v_from, v_to, v_edge_type, NULL)
    ON CONFLICT DO NOTHING;

    v_count := v_count + 1;
    RAISE NOTICE 'Backfilled shadow #%: claimant=% anchor=% type=%',
      v_count, rec.claimant_user_id, rec.anchor_name, v_rel_type;
  END LOOP;

  RAISE NOTICE 'Total shadows backfilled: %', v_count;
END $$;
