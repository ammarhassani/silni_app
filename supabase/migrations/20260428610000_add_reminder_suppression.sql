-- ============================================================================
-- Phase 9.X.D Track A3 — Reminder suppression flag.
-- ============================================================================
--
-- Adds users.suppress_reminders_after_recent_contact BOOLEAN DEFAULT true.
-- Closes the "remind me to call dad after lunch" production bug. The cron
-- send-scheduled-reminders fires user-configured schedules without checking
-- last_contact_date; this flag opts the server-side check on by default.
--
-- The companion change in supabase/functions/send-scheduled-reminders/index.ts
-- consults this flag + each relative's last_contact_date to decide whether
-- to skip a reminder.
--
-- Default true: every existing user gets sane reminder behavior immediately.
-- Founder + CTO confirmed default-on rather than opt-in (no wizard step
-- needed for v1).
-- ============================================================================

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS suppress_reminders_after_recent_contact BOOLEAN NOT NULL DEFAULT true;

-- Backfill: existing rows are guaranteed to have the new column with default
-- TRUE because of the NOT NULL DEFAULT. No explicit UPDATE needed; Postgres
-- materializes the default for existing rows on column add.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='users'
      AND column_name='suppress_reminders_after_recent_contact'
  ) THEN
    RAISE EXCEPTION 'Phase 9.X.D.A3: column add failed';
  END IF;

  -- Defensive: every existing user row must have the new column set to true
  IF EXISTS (
    SELECT 1 FROM public.users
    WHERE suppress_reminders_after_recent_contact IS DISTINCT FROM true
  ) THEN
    RAISE EXCEPTION 'Phase 9.X.D.A3: some users have non-true value for suppress_reminders_after_recent_contact';
  END IF;
END $$;
