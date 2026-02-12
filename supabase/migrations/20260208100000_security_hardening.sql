-- ============================================================================
-- Security Hardening Migration (QA Audit)
-- 2026-02-08
--
-- Fixes critical security and data integrity bugs found during QA audit:
--   1. Column immutability triggers (membership, edges, relatives)
--   2. Unique constraints to prevent race-condition duplicates
--   3. Last admin prevention (leave / demote)
--   4. RLS policy fixes (family_groups, nudge_history, relative_id validation)
--   5. Shared edge UPDATE policy scoped to own edges
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1a. Membership immutability — prevent group_id, user_id, joined_at changes
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION enforce_membership_immutable_columns()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.group_id != OLD.group_id THEN
    RAISE EXCEPTION 'Cannot change group_id on membership';
  END IF;
  IF NEW.user_id != OLD.user_id THEN
    RAISE EXCEPTION 'Cannot change user_id on membership';
  END IF;
  IF NEW.joined_at != OLD.joined_at THEN
    RAISE EXCEPTION 'Cannot change joined_at on membership';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_membership_immutable ON family_group_members;
CREATE TRIGGER trg_enforce_membership_immutable
  BEFORE UPDATE ON family_group_members
  FOR EACH ROW
  EXECUTE FUNCTION enforce_membership_immutable_columns();

-- ----------------------------------------------------------------------------
-- 1b. family_group_id immutability on edges and relatives
--     Prevents converting shared <-> personal records
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION enforce_group_id_immutable()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF OLD.family_group_id IS DISTINCT FROM NEW.family_group_id THEN
    RAISE EXCEPTION 'Cannot change family_group_id';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_edge_group_immutable ON family_edges;
CREATE TRIGGER trg_enforce_edge_group_immutable
  BEFORE UPDATE ON family_edges
  FOR EACH ROW
  EXECUTE FUNCTION enforce_group_id_immutable();

DROP TRIGGER IF EXISTS trg_enforce_relative_group_immutable ON relatives;
CREATE TRIGGER trg_enforce_relative_group_immutable
  BEFORE UPDATE ON relatives
  FOR EACH ROW
  EXECUTE FUNCTION enforce_group_id_immutable();

-- ----------------------------------------------------------------------------
-- 2a. Unique constraint — prevent duplicate node claims within a group
-- ----------------------------------------------------------------------------
CREATE UNIQUE INDEX IF NOT EXISTS idx_family_group_members_node_claim
  ON family_group_members (group_id, relative_id_in_tree)
  WHERE relative_id_in_tree IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 2b. Unique constraint — prevent duplicate self-nodes per user per group
-- ----------------------------------------------------------------------------
CREATE UNIQUE INDEX IF NOT EXISTS idx_relatives_self_per_user_group
  ON relatives (user_id, family_group_id)
  WHERE is_self = true AND family_group_id IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 3. Last admin prevention — block leave or demotion of the only admin
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION prevent_last_admin_removal()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  -- For DELETE: prevent if this was the last admin
  IF TG_OP = 'DELETE' AND OLD.role = 'admin' THEN
    IF NOT EXISTS (
      SELECT 1 FROM family_group_members
      WHERE group_id = OLD.group_id AND role = 'admin' AND id != OLD.id
    ) THEN
      RAISE EXCEPTION 'Cannot remove last admin from group';
    END IF;
  END IF;

  -- For UPDATE: prevent demoting last admin
  IF TG_OP = 'UPDATE' AND OLD.role = 'admin' AND NEW.role != 'admin' THEN
    IF NOT EXISTS (
      SELECT 1 FROM family_group_members
      WHERE group_id = OLD.group_id AND role = 'admin' AND id != OLD.id
    ) THEN
      RAISE EXCEPTION 'Cannot demote last admin';
    END IF;
  END IF;

  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_last_admin ON family_group_members;
CREATE TRIGGER trg_prevent_last_admin
  BEFORE UPDATE OR DELETE ON family_group_members
  FOR EACH ROW
  EXECUTE FUNCTION prevent_last_admin_removal();

-- ----------------------------------------------------------------------------
-- 4a. RLS — fix family_groups DELETE/UPDATE to use admin role, not created_by
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Creator can delete their groups" ON family_groups;
DROP POLICY IF EXISTS "Admins can delete their groups" ON family_groups;
CREATE POLICY "Admins can delete their groups"
  ON family_groups FOR DELETE
  USING (id IN (
    SELECT group_id FROM family_group_members
    WHERE user_id = auth.uid() AND role = 'admin'
  ));

DROP POLICY IF EXISTS "Creator can update their groups" ON family_groups;
DROP POLICY IF EXISTS "Admins can update their groups" ON family_groups;
CREATE POLICY "Admins can update their groups"
  ON family_groups FOR UPDATE
  USING (id IN (
    SELECT group_id FROM family_group_members
    WHERE user_id = auth.uid() AND role = 'admin'
  ))
  WITH CHECK (id IN (
    SELECT group_id FROM family_group_members
    WHERE user_id = auth.uid() AND role = 'admin'
  ));

-- ----------------------------------------------------------------------------
-- 4b. Drop redundant SELECT policy — members policy already covers creators,
--     and this one leaks data to removed creators
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Creator can view their groups" ON family_groups;

-- ----------------------------------------------------------------------------
-- 4c. RLS — nudge_history: restrict to service_role writes + own-data reads
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Service role can manage nudge history" ON nudge_history;
CREATE POLICY "Service role can manage nudge history"
  ON nudge_history FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

DROP POLICY IF EXISTS "Users can view own nudge history" ON nudge_history;
CREATE POLICY "Users can view own nudge history"
  ON nudge_history FOR SELECT
  USING (user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- 4d. Validate relative_id_in_tree belongs to the same group
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION validate_relative_id_in_tree()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.relative_id_in_tree IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM relatives
      WHERE id = NEW.relative_id_in_tree
        AND family_group_id = NEW.group_id
    ) THEN
      RAISE EXCEPTION 'relative_id_in_tree must reference a relative in the same group';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_relative_in_tree ON family_group_members;
CREATE TRIGGER trg_validate_relative_in_tree
  BEFORE INSERT OR UPDATE ON family_group_members
  FOR EACH ROW
  EXECUTE FUNCTION validate_relative_id_in_tree();

-- ----------------------------------------------------------------------------
-- 4e. Prevent admins from removing other admins via direct API
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION prevent_admin_removal_by_admin()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  -- Only applies to DELETE by someone other than the member themselves
  IF TG_OP = 'DELETE' AND OLD.role = 'admin' AND OLD.user_id != auth.uid() THEN
    RAISE EXCEPTION 'Cannot remove another admin from the group';
  END IF;
  RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_admin_removal ON family_group_members;
CREATE TRIGGER trg_prevent_admin_removal
  BEFORE DELETE ON family_group_members
  FOR EACH ROW
  EXECUTE FUNCTION prevent_admin_removal_by_admin();

-- ----------------------------------------------------------------------------
-- 5. Shared edge UPDATE policy — scope to own edges only
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Group members can update shared edges" ON family_edges;
CREATE POLICY "Group members can update own shared edges"
  ON family_edges FOR UPDATE
  USING (
    family_group_id IS NOT NULL
    AND user_id = auth.uid()
    AND family_group_id IN (SELECT auth_user_group_ids())
  )
  WITH CHECK (
    family_group_id IS NOT NULL
    AND user_id = auth.uid()
    AND family_group_id IN (SELECT auth_user_group_ids())
  );
