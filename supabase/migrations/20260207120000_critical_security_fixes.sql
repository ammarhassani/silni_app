-- ============================================================================
-- Critical Security Fixes for Family Sharing
-- ============================================================================
-- 1. FIX: Any user can join any group without invite code (INSERT policy too permissive)
-- 2. FIX: Members can self-promote to admin (UPDATE policy unrestricted)
-- 3. FIX: Shared edge INSERT doesn't enforce user_id = auth.uid()
-- 4. FIX: relatives.family_group_id ON DELETE SET NULL → CASCADE
-- 5. ADD: join_group_by_invite_code() SECURITY DEFINER RPC
-- ============================================================================

-- ============================================================================
-- 1. Lock down family_group_members INSERT policy
-- ============================================================================
-- Old policy: any auth user can insert themselves into ANY group.
-- New policy: only the group creator can insert directly (for createGroup flow).
-- All other joins go through join_group_by_invite_code() RPC.
-- ============================================================================

DROP POLICY IF EXISTS "Users can insert themselves as members" ON family_group_members;

CREATE POLICY "Creator can add initial membership"
  ON family_group_members FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND group_id IN (SELECT id FROM family_groups WHERE created_by = auth.uid())
  );

-- ============================================================================
-- 2. Prevent role self-escalation via trigger
-- ============================================================================
-- The UPDATE policy (from 20260206120000) allows members to update their own row,
-- which is needed for setting relative_id_in_tree. But it also allows changing
-- the role column. A trigger is the cleanest fix since RLS can't restrict columns.
-- ============================================================================

CREATE OR REPLACE FUNCTION prevent_role_self_escalation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- If role is not changing, allow the update (e.g. relative_id_in_tree change)
  IF NEW.role = OLD.role THEN
    RETURN NEW;
  END IF;

  -- Role is changing — only allow if caller is an admin of this group
  IF NOT EXISTS (
    SELECT 1 FROM family_group_members
    WHERE group_id = NEW.group_id
      AND user_id = auth.uid()
      AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only group admins can change member roles';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_role_self_escalation ON family_group_members;
CREATE TRIGGER trg_prevent_role_self_escalation
  BEFORE UPDATE ON family_group_members
  FOR EACH ROW
  EXECUTE FUNCTION prevent_role_self_escalation();

-- ============================================================================
-- 3. Add user_id = auth.uid() to shared edge INSERT policy
-- ============================================================================
-- Without this, any group member can insert edges as another user.
-- ============================================================================

DROP POLICY IF EXISTS "Group members can insert shared edges" ON family_edges;

CREATE POLICY "Group members can insert shared edges"
  ON family_edges FOR INSERT
  WITH CHECK (
    family_group_id IS NOT NULL
    AND user_id = auth.uid()
    AND family_group_id IN (SELECT auth_user_group_ids())
  );

-- ============================================================================
-- 4. Fix relatives.family_group_id from ON DELETE SET NULL to CASCADE
-- ============================================================================
-- When a group is deleted, shared relatives should be deleted too,
-- not orphaned with a NULL family_group_id (which makes them appear
-- as personal relatives in users' lists).
-- ============================================================================

DO $$
DECLARE
  fk_name TEXT;
BEGIN
  SELECT tc.constraint_name INTO fk_name
  FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
  WHERE tc.table_name = 'relatives'
    AND kcu.column_name = 'family_group_id'
    AND tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public';

  IF fk_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE relatives DROP CONSTRAINT %I', fk_name);
  END IF;
END $$;

ALTER TABLE relatives
  ADD CONSTRAINT relatives_family_group_id_fkey
    FOREIGN KEY (family_group_id) REFERENCES family_groups(id) ON DELETE CASCADE;

-- ============================================================================
-- 5. Secure join RPC (validates invite code before inserting membership)
-- ============================================================================
-- This replaces the client-side INSERT for joining.
-- Returns the group row on success (same shape as lookup_group_by_invite_code).
-- If already a member, returns the group without re-inserting.
-- ============================================================================

CREATE OR REPLACE FUNCTION join_group_by_invite_code(
  code TEXT,
  rid UUID DEFAULT NULL
)
RETURNS SETOF family_groups
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  target_group family_groups%ROWTYPE;
BEGIN
  -- Validate invite code
  SELECT * INTO target_group FROM family_groups WHERE invite_code = code;
  IF target_group.id IS NULL THEN
    RAISE EXCEPTION 'Invalid invite code';
  END IF;

  -- Skip if already a member
  IF EXISTS (
    SELECT 1 FROM family_group_members
    WHERE group_id = target_group.id AND user_id = auth.uid()
  ) THEN
    RETURN NEXT target_group;
    RETURN;
  END IF;

  -- Insert membership (no tree node yet — client will resolve and UPDATE)
  INSERT INTO family_group_members (group_id, user_id, role)
  VALUES (target_group.id, auth.uid(), 'member');

  RETURN NEXT target_group;
END;
$$;
