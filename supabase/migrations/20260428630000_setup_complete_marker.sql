-- ============================================================================
-- Phase 9.X.D Track A6 — Setup-complete wizard marker.
-- ============================================================================
--
-- The Track B wizard needs a way to know which users have completed it.
-- Co-tenants users.onboarding_metadata (JSONB; already used by the premium
-- walkthrough) under a separate `setupComplete` JSON path.
--
-- Critical: every existing user must be marked complete BEFORE the wizard
-- ships. Otherwise existing users would suddenly see a half-built wizard
-- on their next launch.
--
-- onboarding_metadata exists on users today (added by 20251229_premium_onboarding
-- and re-added defensively by 20260111000000_sync_schema_to_staging). Default
-- is '{}'::jsonb. This migration:
--
--   1. Defensively ensures the column exists with NOT NULL DEFAULT '{}'::jsonb.
--   2. Backfills setupComplete=true for every existing user. Uses jsonb_set
--      with create_missing=true so it works for empty objects too.
--   3. Self-verifies zero users are missing the marker.
--
-- The trigger handle_new_user does NOT need an update — new users get the
-- DEFAULT '{}'::jsonb (no setupComplete key), and the wizard router redirect
-- will catch them on first launch.
-- ============================================================================

-- 1. Ensure column shape is right (defensive — should already be correct).
ALTER TABLE public.users
  ALTER COLUMN onboarding_metadata SET DEFAULT '{}'::jsonb;

-- For users where the column is NULL (early adopters from before the column's
-- default was set), backfill to '{}'::jsonb first so jsonb_set works.
UPDATE public.users
   SET onboarding_metadata = '{}'::jsonb
 WHERE onboarding_metadata IS NULL;

-- Then make it NOT NULL going forward.
ALTER TABLE public.users
  ALTER COLUMN onboarding_metadata SET NOT NULL;

-- 2. Backfill: mark every existing user as setup-complete. New users (post-
-- migration) start with setupComplete absent → wizard router redirect catches
-- them on first launch.
UPDATE public.users
   SET onboarding_metadata = jsonb_set(
     onboarding_metadata,
     '{setupComplete}',
     'true'::jsonb,
     true
   )
 WHERE onboarding_metadata->>'setupComplete' IS DISTINCT FROM 'true';

-- 3. Self-verification.
DO $$
DECLARE
  v_unmarked INT;
BEGIN
  SELECT COUNT(*) INTO v_unmarked
  FROM public.users
  WHERE onboarding_metadata->>'setupComplete' IS DISTINCT FROM 'true';

  IF v_unmarked > 0 THEN
    RAISE EXCEPTION
      'Phase 9.X.D.A6: % users still lack onboarding_metadata->>setupComplete=true post-backfill',
      v_unmarked;
  END IF;
END $$;
