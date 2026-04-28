-- ============================================================================
-- Phase 9.X.D Track A8 — seed_onboarding_ai_memory RPC.
-- ============================================================================
--
-- Track B's wizard will call this RPC at completion to seed the AI's first-
-- chat context with structured facts about the user. Without this seed the
-- AI's first response is generic boilerplate; with it, the AI can greet
-- the user by name and reference their household composition.
--
-- The RPC inserts a single ai_memories row with:
--   - category='onboarding_seed'
--   - importance=5 (max — surfaced first by ai_context_engine.dart sort)
--   - content = structured fact-set from wizard inputs
--
-- SECURITY DEFINER + explicit search_path per Wave 2 patterns.
--
-- If the wizard fails mid-flow OR the user skips the wizard, this RPC is
-- not called. The AI degrades gracefully to "no memories" — same as today.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.seed_onboarding_ai_memory(
  p_user_id UUID,
  p_full_name TEXT,
  p_household_count INT,
  p_extended_count INT,
  p_reminder_preference TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_memory_id UUID;
  v_content TEXT;
BEGIN
  -- Defensive: caller must match auth.uid() (preventing cross-user seeding)
  IF auth.uid() IS NULL OR auth.uid() <> p_user_id THEN
    RAISE EXCEPTION 'seed_onboarding_ai_memory: caller mismatch';
  END IF;

  -- Defensive: only one onboarding_seed memory per user. If one exists,
  -- update it instead of creating a duplicate.
  SELECT id INTO v_memory_id
  FROM ai_memories
  WHERE user_id = p_user_id AND category = 'onboarding_seed'
  LIMIT 1;

  v_content := format(
    'User: %s. Household: %s relatives. Extended family: %s relatives. Reminder preference: %s.',
    COALESCE(NULLIF(p_full_name, ''), 'unnamed'),
    p_household_count,
    p_extended_count,
    COALESCE(NULLIF(p_reminder_preference, ''), 'default')
  );

  IF v_memory_id IS NULL THEN
    INSERT INTO ai_memories (
      user_id, category, content, importance, is_active, created_at, updated_at
    ) VALUES (
      p_user_id,
      'onboarding_seed',
      v_content,
      5,
      true,
      NOW(),
      NOW()
    )
    RETURNING id INTO v_memory_id;
  ELSE
    UPDATE ai_memories
       SET content = v_content,
           importance = 5,
           is_active = true,
           updated_at = NOW()
     WHERE id = v_memory_id;
  END IF;

  RETURN v_memory_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.seed_onboarding_ai_memory(UUID, TEXT, INT, INT, TEXT) TO authenticated;

-- Self-verification.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname='public' AND p.proname='seed_onboarding_ai_memory'
  ) THEN
    RAISE EXCEPTION 'Phase 9.X.D.A8: seed_onboarding_ai_memory function not created';
  END IF;
END $$;
