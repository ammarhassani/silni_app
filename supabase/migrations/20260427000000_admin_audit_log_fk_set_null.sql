-- DATABASE_AUDIT C2 (final FK fix): admin_audit_log.user_id was the fifth
-- and last FK to auth.users without an ON DELETE clause. The other four
-- (family_groups.created_by, family_group_members.user_id,
-- node_invitations.invited_by, node_invitations.accepted_by) are handled
-- by the procedural teardown in delete_user_account(). admin_audit_log is
-- different: it's a historical / compliance record and should outlive the
-- user that's being deleted, with user_id becoming NULL — so SET NULL is
-- the correct semantic.
--
-- Without this fix, deleting the founder's account (who is the admin and
-- has audit-log entries from role changes) would raise 23503 and the
-- whole delete_user_account transaction would roll back.
--
-- Idempotent: drops the existing FK by name and re-adds with the new
-- semantic. Safe to re-run; the second run is a no-op because pg_constraint
-- doesn't have the old name anymore.

DO $$
DECLARE
  v_existing_constraint TEXT;
BEGIN
  -- Find the current FK constraint name on admin_audit_log.user_id.
  -- Postgres autonames it admin_audit_log_user_id_fkey by default but we
  -- look it up so we don't depend on that.
  SELECT conname INTO v_existing_constraint
  FROM pg_constraint
  WHERE conrelid = 'public.admin_audit_log'::regclass
    AND contype = 'f'
    AND conkey = ARRAY[(
      SELECT attnum FROM pg_attribute
      WHERE attrelid = 'public.admin_audit_log'::regclass
        AND attname = 'user_id'
    )::smallint];

  IF v_existing_constraint IS NOT NULL THEN
    EXECUTE format(
      'ALTER TABLE public.admin_audit_log DROP CONSTRAINT %I',
      v_existing_constraint
    );
  END IF;
END $$;

ALTER TABLE public.admin_audit_log
  ADD CONSTRAINT admin_audit_log_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;

-- Verification: read back the new constraint definition. If it doesn't
-- match the expected SET NULL semantic the migration raises and aborts.
DO $$
DECLARE
  v_definition TEXT;
BEGIN
  SELECT pg_get_constraintdef(oid) INTO v_definition
  FROM pg_constraint
  WHERE conrelid = 'public.admin_audit_log'::regclass
    AND conname = 'admin_audit_log_user_id_fkey';

  IF v_definition IS NULL THEN
    RAISE EXCEPTION 'admin_audit_log_user_id_fkey was not created';
  END IF;

  IF v_definition NOT LIKE '%ON DELETE SET NULL%' THEN
    RAISE EXCEPTION 'admin_audit_log_user_id_fkey is not ON DELETE SET NULL: %',
      v_definition;
  END IF;
END $$;
