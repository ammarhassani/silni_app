-- ============================================================================
-- Phase 9.1.B-db — Drop the gamification stack from prod.
-- ============================================================================
--
-- Closes the cleanup that started with 20260427400000 (which dropped 3 challenge
-- tables only). The Flutter side was left fully wired against admin_badges +
-- users.{badges,points,level} until Phase 9.1's Dart cut (commit c4f7af6).
-- This migration drops every gamification artifact still standing:
--
--   • view: gamification_stats (depended on users.badges — drop FIRST)
--   • tables: admin_badges, admin_levels, admin_points_config
--   • users columns: badges (TEXT[]), points (INTEGER), level (INTEGER)
--   • RPCs: award_points(uuid, integer), get_leaderboard(integer),
--     get_leaderboard(text, integer)
--
-- Streak mechanism is preserved — these columns/tables/functions stay:
--   • users.{current_streak, longest_streak, streak_freezes}
--   • streak_freezes, freeze_usage_history, relative_streaks
--   • admin_streak_config
--
-- Founder + CTO approved 2026-04-28 (Phase 9.1 brief).
--
-- The drops are guarded with IF EXISTS for idempotency. The DO block at the
-- bottom RAISEs if any artifact still exists post-drop, so a partial apply
-- aborts the transaction. It also asserts streak-side artifacts are still
-- present so a botched run can't silently damage the streak system.
-- ============================================================================

-- 1. Drop the view first — it depended on users.badges, so dropping the
--    column before the view would fail with: "cannot drop column badges of
--    table users because other objects depend on it". CASCADE for safety.
DROP VIEW IF EXISTS public.gamification_stats CASCADE;

-- 2. Drop the gamification admin tables.
DROP TABLE IF EXISTS public.admin_badges CASCADE;
DROP TABLE IF EXISTS public.admin_levels CASCADE;
DROP TABLE IF EXISTS public.admin_points_config CASCADE;

-- 3. Drop user gamification columns (TEXT[] badges + INTEGER points + INTEGER level).
ALTER TABLE public.users DROP COLUMN IF EXISTS badges;
ALTER TABLE public.users DROP COLUMN IF EXISTS points;
ALTER TABLE public.users DROP COLUMN IF EXISTS level;

-- 4. Drop the gamification RPCs (both get_leaderboard overloads existed in prod).
DROP FUNCTION IF EXISTS public.award_points(uuid, integer);
DROP FUNCTION IF EXISTS public.get_leaderboard(integer);
DROP FUNCTION IF EXISTS public.get_leaderboard(text, integer);

-- ============================================================================
-- Self-verification — abort the transaction if anything survives or if a
-- streak-side artifact is unexpectedly missing.
-- ============================================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='users' AND column_name='badges') THEN
    RAISE EXCEPTION 'Phase 9.1.B-db: users.badges column still exists';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='users' AND column_name='points') THEN
    RAISE EXCEPTION 'Phase 9.1.B-db: users.points column still exists';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='users' AND column_name='level') THEN
    RAISE EXCEPTION 'Phase 9.1.B-db: users.level column still exists';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='admin_badges') THEN
    RAISE EXCEPTION 'Phase 9.1.B-db: admin_badges table still exists';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='admin_levels') THEN
    RAISE EXCEPTION 'Phase 9.1.B-db: admin_levels table still exists';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='admin_points_config') THEN
    RAISE EXCEPTION 'Phase 9.1.B-db: admin_points_config table still exists';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_class WHERE relkind='v' AND relname='gamification_stats' AND relnamespace=(SELECT oid FROM pg_namespace WHERE nspname='public')) THEN
    RAISE EXCEPTION 'Phase 9.1.B-db: gamification_stats view still exists';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname='public' AND p.proname='award_points') THEN
    RAISE EXCEPTION 'Phase 9.1.B-db: award_points function still exists';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname='public' AND p.proname='get_leaderboard') THEN
    RAISE EXCEPTION 'Phase 9.1.B-db: get_leaderboard function still exists';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='users' AND column_name='current_streak') THEN
    RAISE EXCEPTION 'Phase 9.1.B-db: users.current_streak unexpectedly missing — streak mechanism damaged';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='admin_streak_config') THEN
    RAISE EXCEPTION 'Phase 9.1.B-db: admin_streak_config unexpectedly missing — streak mechanism damaged';
  END IF;
END $$;
