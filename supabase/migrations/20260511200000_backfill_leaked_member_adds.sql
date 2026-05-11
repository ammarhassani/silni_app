-- 20260511200000_backfill_leaked_member_adds.sql
-- Relatives added by non-admin group members are now personal-to-owner.
-- Flip family_group_id back to NULL on any leaked rows.
-- Edges that referenced those rows in group scope get their family_group_id
-- nulled too so they travel with the owner.
--
-- SAFE because: when the row's user_id is NOT the group admin, the row was
-- the member's personal addition that shouldn't have been shared. The
-- member's self-node (is_self = true) is excluded — that one IS supposed
-- to be group-scoped because the admin approved the claim. Same goes for
-- relatives the admin added (user_id = admin); those stay shared.

BEGIN;

-- Audit row count
DO $$
DECLARE
  v_relatives_count INT;
  v_edges_count INT;
BEGIN
  SELECT COUNT(*) INTO v_relatives_count
  FROM relatives r
  WHERE r.family_group_id IS NOT NULL
    AND r.is_self = false
    AND EXISTS (
      SELECT 1 FROM family_group_members fgm
       WHERE fgm.group_id = r.family_group_id
         AND fgm.user_id  = r.user_id
         AND fgm.role <> 'admin'
    );

  SELECT COUNT(*) INTO v_edges_count
  FROM family_edges e
  WHERE e.family_group_id IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM family_group_members fgm
       WHERE fgm.group_id = e.family_group_id
         AND fgm.user_id  = e.user_id
         AND fgm.role <> 'admin'
    );

  RAISE NOTICE 'Unscoping % leaked relatives + % leaked edges',
    v_relatives_count, v_edges_count;
END $$;

-- Unscope leaked relatives
UPDATE relatives r
   SET family_group_id = NULL
 WHERE r.family_group_id IS NOT NULL
   AND r.is_self = false
   AND EXISTS (
     SELECT 1 FROM family_group_members fgm
      WHERE fgm.group_id = r.family_group_id
        AND fgm.user_id  = r.user_id
        AND fgm.role <> 'admin'
   );

-- Unscope edges owned by non-admins
UPDATE family_edges e
   SET family_group_id = NULL
 WHERE e.family_group_id IS NOT NULL
   AND EXISTS (
     SELECT 1 FROM family_group_members fgm
      WHERE fgm.group_id = e.family_group_id
        AND fgm.user_id  = e.user_id
        AND fgm.role <> 'admin'
   );

COMMIT;
