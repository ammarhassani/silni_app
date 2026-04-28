-- ============================================================================
-- Phase 9.X.D Track A1 — Drop verified-dead users columns.
-- ============================================================================
--
-- Pre-check (engineer, 2026-04-28): grep across lib/ + supabase/functions/
-- for each column. Verdicts:
--
--   DROP (no live consumers):
--     - language               (UI is hardcoded TextDirection.rtl in main.dart)
--     - notifications_enabled  (only an analytics user-property string constant)
--     - reminder_time          (cron uses reminder_schedules.time, not user-level)
--     - theme                  (theme lives in SharedPreferences `app_theme`)
--     - phone_number           (only relatives.phone_number is consumed)
--     - account_deletion_requested (delete is direct via delete_user_account RPC)
--     - last_streak_date       (already removed earlier — this drop is a no-op
--                               via IF EXISTS but kept for fail-safety)
--
--   PRESERVED (LIVE — DO NOT DROP, audit was wrong):
--     - trial_started_at       (sync-subscription/index.ts:100 writes it)
--     - trial_used             (sync-subscription/index.ts:101 writes it)
--
-- Original audit listed 9 user columns as dead; pre-check verified only 7.
-- Halted on the trial_* pair per CTO standing order: "If any column flips
-- from dead to live during pre-check, halt and report. Don't force a drop."
--
-- Self-verification block raises if any of the 7 dropped columns survive
-- post-migration, AND if either preserved trial_* column unexpectedly
-- disappears (defensive — the audit said nothing should drop them).
-- ============================================================================

ALTER TABLE public.users DROP COLUMN IF EXISTS language;
ALTER TABLE public.users DROP COLUMN IF EXISTS notifications_enabled;
ALTER TABLE public.users DROP COLUMN IF EXISTS reminder_time;
ALTER TABLE public.users DROP COLUMN IF EXISTS theme;
ALTER TABLE public.users DROP COLUMN IF EXISTS phone_number;
ALTER TABLE public.users DROP COLUMN IF EXISTS account_deletion_requested;
ALTER TABLE public.users DROP COLUMN IF EXISTS last_streak_date;

DO $$
DECLARE
  c TEXT;
BEGIN
  FOR c IN SELECT unnest(ARRAY[
    'language',
    'notifications_enabled',
    'reminder_time',
    'theme',
    'phone_number',
    'account_deletion_requested',
    'last_streak_date'
  ]) LOOP
    IF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema='public' AND table_name='users' AND column_name=c
    ) THEN
      RAISE EXCEPTION 'Phase 9.X.D.A1: users.% still exists post-drop', c;
    END IF;
  END LOOP;

  -- Defensive: trial fields MUST still exist (they are LIVE)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='users' AND column_name='trial_started_at'
  ) THEN
    RAISE EXCEPTION 'Phase 9.X.D.A1: users.trial_started_at unexpectedly missing — sync-subscription edge function depends on it';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='users' AND column_name='trial_used'
  ) THEN
    RAISE EXCEPTION 'Phase 9.X.D.A1: users.trial_used unexpectedly missing — sync-subscription edge function depends on it';
  END IF;
END $$;
