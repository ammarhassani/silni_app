-- DATABASE WAVE 2.5 — Task 5: flip 4 historical FKs to ON DELETE CASCADE.
--
-- MCP introspection (2026-04-26) confirms all 4 FKs exist on prod with
-- no ON DELETE clause (default NO ACTION). All four reference
-- auth.users(id):
--
--   family_group_members.user_id      → auth.users(id)
--   family_groups.created_by          → auth.users(id)
--   node_invitations.accepted_by      → auth.users(id)
--   node_invitations.invited_by       → auth.users(id)
--
-- Without CASCADE, deleting an auth user fails or strands rows. The
-- delete_user_account RPC currently teardown them procedurally — that
-- procedural teardown becomes redundant after this migration and gets
-- removed in Wave 2.6 (separate session).
--
-- Pattern per FK: DROP CONSTRAINT IF EXISTS, then ADD … ON DELETE CASCADE.
-- DO blocks guard the ADDs so the migration is idempotent.

-- ============================================================================
-- 1. family_group_members.user_id → auth.users(id) ON DELETE CASCADE
-- ============================================================================
ALTER TABLE public.family_group_members
  DROP CONSTRAINT IF EXISTS family_group_members_user_id_fkey;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.family_group_members'::regclass
      AND conname = 'family_group_members_user_id_fkey'
  ) THEN
    ALTER TABLE public.family_group_members
      ADD CONSTRAINT family_group_members_user_id_fkey
      FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

-- ============================================================================
-- 2. family_groups.created_by → auth.users(id) ON DELETE CASCADE
-- ============================================================================
ALTER TABLE public.family_groups
  DROP CONSTRAINT IF EXISTS family_groups_created_by_fkey;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.family_groups'::regclass
      AND conname = 'family_groups_created_by_fkey'
  ) THEN
    ALTER TABLE public.family_groups
      ADD CONSTRAINT family_groups_created_by_fkey
      FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

-- ============================================================================
-- 3. node_invitations.invited_by → auth.users(id) ON DELETE CASCADE
-- ============================================================================
ALTER TABLE public.node_invitations
  DROP CONSTRAINT IF EXISTS node_invitations_invited_by_fkey;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.node_invitations'::regclass
      AND conname = 'node_invitations_invited_by_fkey'
  ) THEN
    ALTER TABLE public.node_invitations
      ADD CONSTRAINT node_invitations_invited_by_fkey
      FOREIGN KEY (invited_by) REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

-- ============================================================================
-- 4. node_invitations.accepted_by → auth.users(id) ON DELETE CASCADE
-- ============================================================================
ALTER TABLE public.node_invitations
  DROP CONSTRAINT IF EXISTS node_invitations_accepted_by_fkey;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.node_invitations'::regclass
      AND conname = 'node_invitations_accepted_by_fkey'
  ) THEN
    ALTER TABLE public.node_invitations
      ADD CONSTRAINT node_invitations_accepted_by_fkey
      FOREIGN KEY (accepted_by) REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

-- ============================================================================
-- Self-verification — every FK has ON DELETE CASCADE.
-- ============================================================================
DO $$
DECLARE
  v_def TEXT;
  v_pair RECORD;
BEGIN
  FOR v_pair IN
    SELECT t::regclass AS conrelid, c AS conname
    FROM (VALUES
      ('public.family_group_members'::text, 'family_group_members_user_id_fkey'),
      ('public.family_groups'::text,        'family_groups_created_by_fkey'),
      ('public.node_invitations'::text,     'node_invitations_invited_by_fkey'),
      ('public.node_invitations'::text,     'node_invitations_accepted_by_fkey')
    ) AS x(t, c)
  LOOP
    SELECT pg_get_constraintdef(oid) INTO v_def
    FROM pg_constraint
    WHERE conrelid = v_pair.conrelid
      AND conname = v_pair.conname
      AND contype = 'f';

    IF v_def IS NULL THEN
      RAISE EXCEPTION 'FK %.% missing after migration', v_pair.conrelid, v_pair.conname;
    END IF;

    IF v_def NOT LIKE '%ON DELETE CASCADE%' THEN
      RAISE EXCEPTION
        'FK %.% does not have ON DELETE CASCADE: %',
        v_pair.conrelid, v_pair.conname, v_def;
    END IF;
  END LOOP;
END $$;
