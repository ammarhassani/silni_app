-- ============================================================================
-- Final Audit Fixes — Part 4: Trigger + RLS policy fixes
-- ============================================================================

-- Fix trg_prevent_last_admin — allow deletion when it's the LAST member
CREATE OR REPLACE FUNCTION prevent_last_admin_removal()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_other_members_exist BOOLEAN;
BEGIN
  IF TG_OP = 'DELETE' AND OLD.role = 'admin' THEN
    SELECT EXISTS(
      SELECT 1 FROM family_group_members
      WHERE group_id = OLD.group_id AND id != OLD.id
    ) INTO v_other_members_exist;

    IF v_other_members_exist AND NOT EXISTS (
      SELECT 1 FROM family_group_members
      WHERE group_id = OLD.group_id AND role = 'admin' AND id != OLD.id
    ) THEN
      RAISE EXCEPTION 'Cannot remove last admin from group while other members exist';
    END IF;
  END IF;

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

-- Restrict shared edge DELETE to edge creator or group admin
DROP POLICY IF EXISTS "Group members can delete shared edges" ON family_edges;
DROP POLICY IF EXISTS "Group members can delete own shared edges or admin" ON family_edges;
CREATE POLICY "Group members can delete own shared edges or admin"
  ON family_edges FOR DELETE
  USING (
    family_group_id IS NOT NULL
    AND family_group_id IN (SELECT auth_user_group_ids())
    AND (
      user_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM family_group_members
        WHERE group_id = family_edges.family_group_id
          AND user_id = auth.uid()
          AND role = 'admin'
      )
    )
  );

-- Restrict shared relative UPDATE to creator/adder or group admin
DROP POLICY IF EXISTS "Owner or group members can update relatives" ON relatives;
DROP POLICY IF EXISTS "Owner or adder or admin can update relatives" ON relatives;
CREATE POLICY "Owner or adder or admin can update relatives"
  ON relatives FOR UPDATE
  USING (
    (family_group_id IS NULL AND user_id = auth.uid())
    OR
    (family_group_id IS NOT NULL
     AND family_group_id IN (SELECT auth_user_group_ids())
     AND (
       user_id = auth.uid()
       OR added_by = auth.uid()
       OR EXISTS (
         SELECT 1 FROM family_group_members
         WHERE group_id = relatives.family_group_id
           AND user_id = auth.uid()
           AND role = 'admin'
       )
     )
    )
  )
  WITH CHECK (
    (family_group_id IS NULL AND user_id = auth.uid())
    OR
    (family_group_id IS NOT NULL
     AND family_group_id IN (SELECT auth_user_group_ids())
     AND (
       user_id = auth.uid()
       OR added_by = auth.uid()
       OR EXISTS (
         SELECT 1 FROM family_group_members
         WHERE group_id = relatives.family_group_id
           AND user_id = auth.uid()
           AND role = 'admin'
       )
     )
    )
  );
