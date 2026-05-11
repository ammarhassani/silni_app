-- 20260511150000_backfill_remove_unlinked_memberships.sql
-- One-shot cleanup. Removes the "phantom member" rows that motivated
-- the deferred-membership refactor. Idempotent — re-running is a no-op.

BEGIN;

-- Audit row for safety: how many will we delete?
DO $$
DECLARE
  n INT;
BEGIN
  SELECT COUNT(*) INTO n FROM family_group_members WHERE relative_id_in_tree IS NULL;
  RAISE NOTICE 'Deleting % unlinked memberships', n;
END $$;

DELETE FROM family_group_members
 WHERE relative_id_in_tree IS NULL;

COMMIT;
