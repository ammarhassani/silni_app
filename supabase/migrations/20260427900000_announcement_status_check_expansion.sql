-- Phase 4 — Task 3: expand admin_announcements.status CHECK to support
-- partial-failure tracking.
--
-- Discovery audit Cat 2 finding (and a latent bug): both
-- send-announcement and send-scheduled-announcements would mark a delivery
-- "sent" even when most recipients failed FCM. CTO decision: track three
-- terminal statuses driven by success_count / total_count.
--
--   success_count == total_count > 0  → 'sent'
--   0 < success_count < total_count   → 'partial'
--   success_count == 0                → 'failed'
--
-- The columns total_recipients, successful_sends, failed_sends already
-- exist on the table (introspected via MCP 2026-04-26). The CHECK
-- constraint, however, only allows ('draft', 'scheduled', 'sent') — so
-- send-announcement's current 'failed' write would fail the constraint
-- if every FCM call rejected. This is a latent bug as well as the
-- CTO-requested expansion.
--
-- Changes:
--   1. DROP the existing CHECK.
--   2. ADD a new CHECK allowing the five terminal/in-flight statuses
--      ('draft', 'scheduled', 'sent', 'partial', 'failed'). Note:
--      'sending' was used by silni-admin's TypeScript type for a UI
--      transient — it's not persisted by any edge function, so it is
--      NOT in the new CHECK. If a future feature needs persisted
--      'sending', it gets its own migration.
--   3. Self-verify via pg_get_constraintdef.

ALTER TABLE public.admin_announcements
  DROP CONSTRAINT IF EXISTS admin_announcements_status_check;

ALTER TABLE public.admin_announcements
  ADD CONSTRAINT admin_announcements_status_check
  CHECK (status IN ('draft', 'scheduled', 'sent', 'partial', 'failed'));

DO $$
DECLARE
  v_def TEXT;
BEGIN
  SELECT pg_get_constraintdef(oid) INTO v_def
  FROM pg_constraint
  WHERE conrelid = 'public.admin_announcements'::regclass
    AND conname = 'admin_announcements_status_check';

  IF v_def IS NULL THEN
    RAISE EXCEPTION 'admin_announcements_status_check is missing';
  END IF;

  IF v_def NOT LIKE '%''partial''%' OR v_def NOT LIKE '%''failed''%' THEN
    RAISE EXCEPTION
      'admin_announcements_status_check missing partial/failed: %', v_def;
  END IF;
END $$;
