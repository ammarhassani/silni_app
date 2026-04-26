-- DATABASE WAVE 2 — Task 1: drop orphan tables + migrate hadith content.
--
-- Decisions encoded in this migration (CTO 2026-04-26):
--   T1A: ai_memories REMOVED from drop list (load-bearing chat-tables capture).
--   T1B: drop admin_challenges, admin_memory_categories, admin_ai_memory_config.
--        Dart fetch sites cleaned up in the same commit (B2 option).
--   T1C: migrate 3 unique rows from hadith into admin_hadith, then drop hadith.
--
-- Order is fixed:
--   1) hadith content migration (idempotent INSERT … WHERE NOT EXISTS).
--   2) Drop social_* tables in dependency order (dependents first).
--   3) Drop admin_* + gamification + content tables.
--   4) Drop hadith.
--   5) Self-verification — every dropped name is gone, admin_hadith
--      grew by exactly 3.

-- ============================================================================
-- 1. Migrate the 3 unique hadith rows into admin_hadith
-- ============================================================================
-- Schema mapping (CTO 2026-04-26):
--   hadith.arabic_text         → admin_hadith.hadith_text  (wrapped per existing convention)
--   hadith.source + reference  → admin_hadith.source       (concatenated per CTO example)
--   hadith.narrator            → admin_hadith.narrator     (NULL on the source rows; left NULL)
--   admin_hadith.category      → 'silat_rahim'             (only category present in admin_hadith)
--   admin_hadith.tags          → topic-relevant Arabic tags + 'صلة الرحم' lead
--   admin_hadith.is_active     → true
--   admin_hadith.display_priority → 101, 102, 103 (max=100 introspected via MCP)
--
-- English translations are NOT migrated. They remain available in git
-- history via the original hadith table definition. Tracked for a
-- future i18n pass.
--
-- Idempotency: each INSERT guards on the source string (which is unique
-- across admin_hadith rows). Re-running this migration is a no-op.

INSERT INTO public.admin_hadith
  (hadith_text, source, narrator, grade, category, tags, is_active, display_priority)
SELECT
  E'قال رسول الله ﷺ: "من كان يؤمن بالله واليوم الآخر فليصل رحمه"',
  'Sahih Al-Bukhari 6138',
  NULL,
  'صحيح',
  'silat_rahim',
  ARRAY['صلة الرحم', 'الإيمان', 'اليوم الآخر'],
  true,
  101
WHERE NOT EXISTS (
  SELECT 1 FROM public.admin_hadith WHERE source = 'Sahih Al-Bukhari 6138'
);

INSERT INTO public.admin_hadith
  (hadith_text, source, narrator, grade, category, tags, is_active, display_priority)
SELECT
  E'قال رسول الله ﷺ: "صلة الرحم محبة في الأهل، مثراة في المال، منسأة في الأثر"',
  'Musnad Ahmad 7563',
  NULL,
  'حسن',
  'silat_rahim',
  ARRAY['صلة الرحم', 'المحبة', 'الرزق', 'العمر'],
  true,
  102
WHERE NOT EXISTS (
  SELECT 1 FROM public.admin_hadith WHERE source = 'Musnad Ahmad 7563'
);

INSERT INTO public.admin_hadith
  (hadith_text, source, narrator, grade, category, tags, is_active, display_priority)
SELECT
  E'قال رسول الله ﷺ: "إن أعجل الطاعة ثواباً صلة الرحم"',
  'Musnad Ahmad 16033',
  NULL,
  'حسن',
  'silat_rahim',
  ARRAY['صلة الرحم', 'الطاعة', 'الثواب'],
  true,
  103
WHERE NOT EXISTS (
  SELECT 1 FROM public.admin_hadith WHERE source = 'Musnad Ahmad 16033'
);

-- ============================================================================
-- 2. Drop the 7 social_* tables in dependency order
-- ============================================================================
-- Dependents first (social_click_log → social_analytics → social_posts) so
-- CASCADE only fires for dangling FKs where it's expected. Each DROP is
-- IF EXISTS so the migration is idempotent on prod and on fresh deploys.

DROP TABLE IF EXISTS public.social_click_log    CASCADE;
DROP TABLE IF EXISTS public.social_analytics    CASCADE;
DROP TABLE IF EXISTS public.social_posts        CASCADE;
DROP TABLE IF EXISTS public.social_templates    CASCADE;
DROP TABLE IF EXISTS public.social_campaigns    CASCADE;
DROP TABLE IF EXISTS public.social_brand_voice  CASCADE;
DROP TABLE IF EXISTS public.social_accounts     CASCADE;

-- ============================================================================
-- 3. Drop admin_* + gamification + content tables
-- ============================================================================
-- All three admin_* tables read inside try/catch + silent-fail in
-- gamification_config_service.dart and ai_config_service.dart. Dart fetch
-- code is removed in this same commit (Task 1.5). Hardcoded fallbacks
-- (ChallengeConfig.fallbackChallenges, AIMemorySystemConfig.fallback,
-- AIMemoryCategoryConfig.fallbackCategories) become the only path.
DROP TABLE IF EXISTS public.admin_challenges        CASCADE;
DROP TABLE IF EXISTS public.admin_memory_categories CASCADE;
DROP TABLE IF EXISTS public.admin_ai_memory_config  CASCADE;

-- challenge_streaks / daily_challenges: legacy gamification, never wired
-- to the current relative_streaks / streak system.
DROP TABLE IF EXISTS public.challenge_streaks CASCADE;
DROP TABLE IF EXISTS public.daily_challenges  CASCADE;

-- gifts / wisdom_entries / occasions: never-shipped feature stubs.
DROP TABLE IF EXISTS public.gifts          CASCADE;
DROP TABLE IF EXISTS public.wisdom_entries CASCADE;
DROP TABLE IF EXISTS public.occasions      CASCADE;

-- fcm_tokens: 0 rows, FCM-rename relic. notification_tokens is the live table.
DROP TABLE IF EXISTS public.fcm_tokens CASCADE;

-- ============================================================================
-- 4. Drop hadith (after content migration above)
-- ============================================================================
DROP TABLE IF EXISTS public.hadith CASCADE;

-- ============================================================================
-- 5. Self-verification
-- ============================================================================
-- Asserts:
--   - admin_hadith now contains the 3 migrated source values.
--   - admin_hadith row count >= 10 (was 7; +3 = 10 minimum, idempotency-safe).
--   - all 17 dropped tables are absent from pg_class.
-- Aborts cleanly via RAISE EXCEPTION on any mismatch — prod stays in a
-- consistent state (the prior CHECKs and DROPs are all in this transaction).

DO $$
DECLARE
  v_table TEXT;
  v_count INTEGER;
  v_dropped TEXT[] := ARRAY[
    'social_click_log',
    'social_analytics',
    'social_posts',
    'social_templates',
    'social_campaigns',
    'social_brand_voice',
    'social_accounts',
    'admin_challenges',
    'admin_memory_categories',
    'admin_ai_memory_config',
    'challenge_streaks',
    'daily_challenges',
    'gifts',
    'wisdom_entries',
    'occasions',
    'fcm_tokens',
    'hadith'
  ];
BEGIN
  -- Verify the 3 migrated hadiths landed.
  FOR v_table IN SELECT unnest(ARRAY[
    'Sahih Al-Bukhari 6138',
    'Musnad Ahmad 7563',
    'Musnad Ahmad 16033'
  ])
  LOOP
    SELECT COUNT(*) INTO v_count
    FROM public.admin_hadith WHERE source = v_table;
    IF v_count <> 1 THEN
      RAISE EXCEPTION
        'admin_hadith migration missing or duplicated for source=%; got % rows (expected 1)',
        v_table, v_count;
    END IF;
  END LOOP;

  -- Verify admin_hadith total >= 10 (was 7 + 3 migrated).
  SELECT COUNT(*) INTO v_count FROM public.admin_hadith;
  IF v_count < 10 THEN
    RAISE EXCEPTION
      'admin_hadith has % rows (expected at least 10 after migration)', v_count;
  END IF;

  -- Verify every dropped table is gone.
  FOREACH v_table IN ARRAY v_dropped LOOP
    IF EXISTS (
      SELECT 1 FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public' AND c.relname = v_table AND c.relkind = 'r'
    ) THEN
      RAISE EXCEPTION 'Table public.% still exists after DROP', v_table;
    END IF;
  END LOOP;
END $$;
