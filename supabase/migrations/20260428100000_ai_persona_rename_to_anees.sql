-- Phase 6.1 — Task 2: AI persona rename واصل → أنيس on prod admin rows.
--
-- Decision (CTO + founder, 2026-04-27): the AI persona is renamed from
-- `واصل` to `أنيس` (companion in solitude) to remove the collision with
-- the gamification noun. `واصل` continues to mean "one who maintains
-- ties" in badges, level titles, and wrapped labels — that's the
-- gamification concept and is intentionally preserved. See BRAND.md.
--
-- Prod state at migration time:
--   - admin_ai_identity:  0 rows. Client falls back to the in-code
--                         AIIdentityConfig.fallback() which now returns
--                         aiName='أنيس'. No update needed for an empty
--                         table; INSERT-as-defensive-seed is also avoided
--                         (the table being empty is intentional — the
--                         fallback is the source of truth in v1).
--   - admin_ai_personality: 1 row with content_ar starting "أنت واصل،…".
--                           Updates that row to "أنت أنيس،…".
--   - admin_counseling_modes / admin_suggested_prompts: 0 rows match the
--                           standalone واصل pattern. Nothing to update.
--
-- Defensive: matches by id (single-row update), idempotent on re-run.
-- The REPLACE only flips the standalone "أنت واصل" prefix, not any
-- substring like "تواصل" elsewhere in the same field.

UPDATE public.admin_ai_personality
SET content_ar = REPLACE(content_ar, 'أنت واصل،', E'أنت أنيس،')
WHERE id = '3d9d0355-9e05-4c48-972a-4389202e1e76'
  AND content_ar LIKE 'أنت واصل،%';

-- Self-verification — the row no longer starts with "أنت واصل،" and
-- now starts with "أنت أنيس،".
DO $$
DECLARE
  v_text TEXT;
BEGIN
  SELECT content_ar INTO v_text
  FROM public.admin_ai_personality
  WHERE id = '3d9d0355-9e05-4c48-972a-4389202e1e76';

  IF v_text IS NULL THEN
    RAISE NOTICE 'admin_ai_personality row 3d9d0355-... not found; skipping verify';
    RETURN;
  END IF;

  IF v_text LIKE 'أنت واصل،%' THEN
    RAISE EXCEPTION
      'admin_ai_personality 3d9d0355-... still starts with "أنت واصل،"';
  END IF;

  IF v_text NOT LIKE 'أنت أنيس،%' THEN
    RAISE EXCEPTION
      'admin_ai_personality 3d9d0355-... did not flip to "أنت أنيس،" (current: %)',
      LEFT(v_text, 40);
  END IF;
END $$;
