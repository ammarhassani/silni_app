-- ============================================================================
-- Fix: Infinite recursion in family_group_members RLS policies
-- ============================================================================
-- The SELECT policy on family_group_members referenced itself in a subquery,
-- causing PostgreSQL error 42P17 (infinite recursion) whenever any query
-- touched family_group_members — including relatives queries whose policies
-- also reference family_group_members.
--
-- Fix: Create a SECURITY DEFINER function that returns the current user's
-- group IDs without triggering RLS, then use it in all affected policies.
-- ============================================================================

-- 1. Create helper function (bypasses RLS to avoid recursion)
CREATE OR REPLACE FUNCTION auth_user_group_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT group_id FROM family_group_members WHERE user_id = auth.uid();
$$;

-- 2. Create helper function for admin group IDs
CREATE OR REPLACE FUNCTION auth_user_admin_group_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT group_id FROM family_group_members
  WHERE user_id = auth.uid() AND role = 'admin';
$$;

-- ============================================================================
-- 3. Fix family_group_members policies
-- ============================================================================

DROP POLICY IF EXISTS "Members can view group members" ON family_group_members;
CREATE POLICY "Members can view group members"
  ON family_group_members FOR SELECT
  USING (group_id IN (SELECT auth_user_group_ids()));

DROP POLICY IF EXISTS "Admins can remove other members" ON family_group_members;
CREATE POLICY "Admins can remove other members"
  ON family_group_members FOR DELETE
  USING (group_id IN (SELECT auth_user_admin_group_ids()));

-- ============================================================================
-- 4. Fix family_groups policies
-- ============================================================================

DROP POLICY IF EXISTS "Members can view their groups" ON family_groups;
CREATE POLICY "Members can view their groups"
  ON family_groups FOR SELECT
  USING (id IN (SELECT auth_user_group_ids()));

-- ============================================================================
-- 5. Fix relatives policies
-- ============================================================================

DROP POLICY IF EXISTS "Users can view own and shared relatives" ON relatives;
CREATE POLICY "Users can view own and shared relatives"
  ON relatives FOR SELECT
  USING (
    (family_group_id IS NULL AND user_id = auth.uid())
    OR
    (family_group_id IS NOT NULL AND family_group_id IN (SELECT auth_user_group_ids()))
  );

DROP POLICY IF EXISTS "Users or group members can insert relatives" ON relatives;
CREATE POLICY "Users or group members can insert relatives"
  ON relatives FOR INSERT
  WITH CHECK (
    (family_group_id IS NULL AND user_id = auth.uid())
    OR
    (family_group_id IS NOT NULL AND user_id = auth.uid()
     AND family_group_id IN (SELECT auth_user_group_ids()))
  );

DROP POLICY IF EXISTS "Owner or group members can update relatives" ON relatives;
CREATE POLICY "Owner or group members can update relatives"
  ON relatives FOR UPDATE
  USING (
    user_id = auth.uid()
    OR
    (family_group_id IS NOT NULL AND family_group_id IN (SELECT auth_user_group_ids()))
  )
  WITH CHECK (
    user_id = auth.uid()
    OR
    (family_group_id IS NOT NULL AND family_group_id IN (SELECT auth_user_group_ids()))
  );

DROP POLICY IF EXISTS "Owner or adder or admin can delete relatives" ON relatives;
CREATE POLICY "Owner or adder or admin can delete relatives"
  ON relatives FOR DELETE
  USING (
    user_id = auth.uid()
    OR
    (family_group_id IS NOT NULL AND added_by = auth.uid())
    OR
    (family_group_id IS NOT NULL AND family_group_id IN (SELECT auth_user_admin_group_ids()))
  );
