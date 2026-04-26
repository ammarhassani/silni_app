-- DATABASE WAVE 2 — Task 2: drop debug_* RPCs.
--
-- The audit flagged 4 debug RPCs. MCP introspection (2026-04-26) shows
-- only debug_admin_stats() actually exists on prod; the other three
-- (debug_with_gamification_test, debug_subscription_status,
-- debug_add_interactions) do not exist. They were either dropped
-- previously without a migration or never made it past the audit's
-- listing source. DROP FUNCTION IF EXISTS handles both cases.
--
-- All four are zero-reference in lib/ (re-verified 2026-04-26 via grep).

DROP FUNCTION IF EXISTS public.debug_admin_stats() CASCADE;
DROP FUNCTION IF EXISTS public.debug_with_gamification_test() CASCADE;
DROP FUNCTION IF EXISTS public.debug_subscription_status() CASCADE;
DROP FUNCTION IF EXISTS public.debug_add_interactions() CASCADE;

-- Self-verification — no public.debug_* function survives.
DO $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proname IN (
      'debug_admin_stats',
      'debug_with_gamification_test',
      'debug_subscription_status',
      'debug_add_interactions'
    );

  IF v_count <> 0 THEN
    RAISE EXCEPTION 'Expected 0 debug_* functions in public; found %', v_count;
  END IF;
END $$;
