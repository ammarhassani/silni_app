-- Fix enforce_group_id_immutable to allow initial assignment (NULL → value)
-- while still preventing group reassignment (value → different value).
--
-- The previous version blocked ALL changes including NULL → value, which broke
-- migrateRelativesToGroup (personal relatives being assigned to a group).

CREATE OR REPLACE FUNCTION enforce_group_id_immutable()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  -- Allow initial assignment (NULL → value) but block reassignment
  IF OLD.family_group_id IS NOT NULL
     AND OLD.family_group_id IS DISTINCT FROM NEW.family_group_id THEN
    RAISE EXCEPTION 'Cannot change family_group_id';
  END IF;
  RETURN NEW;
END;
$$;
