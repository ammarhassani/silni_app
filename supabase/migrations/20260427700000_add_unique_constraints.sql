-- DATABASE WAVE 2 — Task 4: ensure unique constraints exist.
--
-- The audit's H1 finding said these constraints were missing. MCP
-- introspection (2026-04-26) shows they already exist on prod:
--
--   family_group_members_group_id_user_id_key (UNIQUE constraint)
--     UNIQUE (group_id, user_id)
--
--   idx_node_invitations_unique_pending (partial unique INDEX)
--     CREATE UNIQUE INDEX ... ON node_invitations (group_id, relative_id)
--     WHERE (status = 'pending')
--
-- Wave 1.5 confirmed zero duplicate rows on either, so the constraints
-- enforce the right invariant. The audit was either wrong, or the
-- constraints were added since the audit was written without a migration.
--
-- This migration captures both into history so fresh deploys get them.
-- Idempotent on prod (no-op when both already exist).

-- 1. UNIQUE constraint on family_group_members(group_id, user_id).
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.family_group_members'::regclass
      AND conname = 'family_group_members_group_id_user_id_key'
      AND contype = 'u'
  ) THEN
    ALTER TABLE public.family_group_members
      ADD CONSTRAINT family_group_members_group_id_user_id_key
      UNIQUE (group_id, user_id);
  END IF;
END $$;

-- 2. Partial unique index on node_invitations(group_id, relative_id)
--    WHERE status = 'pending'.
CREATE UNIQUE INDEX IF NOT EXISTS idx_node_invitations_unique_pending
  ON public.node_invitations (group_id, relative_id)
  WHERE status = 'pending';

-- Self-verification.
DO $$
DECLARE
  v_has_constraint BOOLEAN;
  v_has_index BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.family_group_members'::regclass
      AND conname = 'family_group_members_group_id_user_id_key'
      AND contype = 'u'
  ) INTO v_has_constraint;

  IF NOT v_has_constraint THEN
    RAISE EXCEPTION
      'family_group_members_group_id_user_id_key UNIQUE constraint missing';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'node_invitations'
      AND indexname = 'idx_node_invitations_unique_pending'
  ) INTO v_has_index;

  IF NOT v_has_index THEN
    RAISE EXCEPTION
      'idx_node_invitations_unique_pending partial unique index missing';
  END IF;
END $$;
