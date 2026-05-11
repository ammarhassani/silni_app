-- 20260513200000_restore_testprodjoiner_personal_scope.sql
-- One-shot data fix for testprodjoiner (and any other user with the same
-- damage pattern) whose personal self-node + shadows got promoted into
-- their newly-created group by the now-fixed initializeSharedTree.
--
-- The `enforce_group_id_immutable` trigger blocks reassignment of
-- family_group_id (allows NULL → value but not value → other). We
-- temporarily disable it for this surgical fix and re-enable it after.
--
-- Idempotent: safe to re-run.

BEGIN;

ALTER TABLE relatives DISABLE TRIGGER trg_enforce_relative_group_immutable;
ALTER TABLE family_edges DISABLE TRIGGER trg_enforce_edge_group_immutable;

DO $$
DECLARE
  v_joiner UUID := '6251e7f6-445d-4954-a9c0-d430ae93cc48';
  v_test_group UUID := 'fd07659b-9432-4224-a074-2ad4ba1ab3c1';
  v_personal_self UUID := '633000bb-2615-433c-b714-82e659f1103f';
  v_shadow UUID := '0de0e240-d88a-4132-9cd7-196223d1f3b0';
  v_new_in_group_self UUID;
BEGIN
  -- 1. Move the personal self-node back to personal scope
  UPDATE relatives
     SET family_group_id = NULL, updated_at = NOW()
   WHERE id = v_personal_self
     AND user_id = v_joiner;

  -- 2. Move the shadow back to personal scope
  UPDATE relatives
     SET family_group_id = NULL, updated_at = NOW()
   WHERE id = v_shadow
     AND mirrors_relative_id IS NOT NULL
     AND user_id = v_joiner;

  -- 3. Move the spouse_of edge back to personal scope
  UPDATE family_edges
     SET family_group_id = NULL
   WHERE family_group_id = v_test_group
     AND user_id = v_joiner
     AND from_id = v_personal_self::text;

  -- 4. Create a NEW in-group self-node for the test group (if missing)
  IF NOT EXISTS (
    SELECT 1 FROM relatives
    WHERE user_id = v_joiner
      AND family_group_id = v_test_group
      AND is_self = true
  ) THEN
    INSERT INTO relatives (
      user_id, full_name, relationship_type, gender, priority,
      is_self, family_group_id, added_by, relative_category, created_at, updated_at
    ) VALUES (
      v_joiner, 'testprodjoiner', 'other', 'female', 1,
      true, v_test_group, v_joiner, 'household', NOW(), NOW()
    )
    RETURNING id INTO v_new_in_group_self;

    -- 5. Update the membership to point to the new in-group self-node
    UPDATE family_group_members
       SET relative_id_in_tree = v_new_in_group_self
     WHERE group_id = v_test_group
       AND user_id = v_joiner;

    RAISE NOTICE 'Created new in-group self % for testprodjoiner in test group', v_new_in_group_self;
  END IF;
END $$;

ALTER TABLE relatives ENABLE TRIGGER trg_enforce_relative_group_immutable;
ALTER TABLE family_edges ENABLE TRIGGER trg_enforce_edge_group_immutable;

COMMIT;
