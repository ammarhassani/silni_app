-- Cleanup: revert incorrectly migrated joiner personal relatives.
--
-- Bug: ensureRelativesInGroup ran migrateRelativesToGroup for ALL group
-- members, not just the admin. This stamped joiners' personal relatives
-- with the group's family_group_id, creating duplicates in the shared tree
-- and breaking labels.
--
-- Fix: reset family_group_id to NULL for non-admin members' relatives
-- (except their self-node) so they return to the personal pool.

BEGIN;

-- 1. Temporarily disable the immutability trigger so we can reset group_id
ALTER TABLE relatives DISABLE TRIGGER trg_enforce_relative_group_immutable;

-- 2. Collect the IDs of relatives to reset
CREATE TEMP TABLE _stale_relative_ids AS
SELECT r.id AS relative_id, r.family_group_id AS group_id
FROM relatives r
JOIN family_group_members m
  ON m.user_id = r.user_id
 AND m.group_id = r.family_group_id
WHERE m.role != 'admin'
  AND r.is_self = false
  AND (m.relative_id_in_tree IS NULL OR r.id != m.relative_id_in_tree)
  -- Only relatives the joiner personally migrated (added_by = themselves)
  AND r.added_by = r.user_id;

-- 3. Delete edges that reference these stale relatives
-- family_edges.from_id/to_id are text, temp table IDs are uuid → cast
DELETE FROM family_edges fe
USING _stale_relative_ids s
WHERE fe.family_group_id = s.group_id
  AND (fe.from_id = s.relative_id::text OR fe.to_id = s.relative_id::text);

-- 4. Reset family_group_id to NULL (return to personal pool)
UPDATE relatives r
SET family_group_id = NULL,
    added_by = NULL
FROM _stale_relative_ids s
WHERE r.id = s.relative_id;

-- 5. Re-enable the trigger
ALTER TABLE relatives ENABLE TRIGGER trg_enforce_relative_group_immutable;

DROP TABLE _stale_relative_ids;

COMMIT;
