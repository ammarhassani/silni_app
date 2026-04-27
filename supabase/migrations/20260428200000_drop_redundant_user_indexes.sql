-- Phase 7 — Task 4: drop redundant indexes on public.users.
--
-- Background: PERFORMANCE_AUDIT.md Cat 1 reported every users index
-- as "duplicated" — that was an MCP join artifact (pg_indexes ⋈
-- pg_class returned each row twice for the users table). The actual
-- prod state on 2026-04-27 (re-verified via MCP at the start of this
-- task) has 7 distinct indexes:
--
--   users_pkey                       PRIMARY KEY (id)
--   users_email_key                  UNIQUE (email)        -- constraint-backed
--   idx_users_email                  btree  (email)        -- redundant ←
--   idx_users_created_at             btree  (created_at DESC)
--   idx_users_last_interaction       btree  (last_interaction_at DESC NULLS LAST)
--   idx_users_streak_deadline        btree  (streak_deadline)
--   idx_users_subscription_status    btree  (subscription_status)
--
-- The only genuine redundancy is `idx_users_email` — Postgres can
-- always use the UNIQUE index `users_email_key` for any equality or
-- range query on email. Keeping both costs an extra btree on every
-- INSERT/UPDATE to users (the busiest write path on every sign-in via
-- ensure_user_record).
--
-- Drop only `idx_users_email`. Self-verify that `users_email_key`
-- still covers email lookups before declaring success.

DROP INDEX IF EXISTS public.idx_users_email;

DO $$
DECLARE
  v_email_unique BOOLEAN;
  v_email_redundant BOOLEAN;
BEGIN
  -- The UNIQUE backing index for email must survive.
  SELECT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'users'
      AND indexname = 'users_email_key'
  ) INTO v_email_unique;

  IF NOT v_email_unique THEN
    RAISE EXCEPTION
      'users_email_key UNIQUE index missing — refusing to leave email unindexed';
  END IF;

  -- The redundant non-unique index must be gone.
  SELECT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'users'
      AND indexname = 'idx_users_email'
  ) INTO v_email_redundant;

  IF v_email_redundant THEN
    RAISE EXCEPTION 'idx_users_email still exists after DROP';
  END IF;
END $$;
