-- DATABASE WAVE 2 — Task 3: fix users.subscription_status CHECK.
--
-- Current CHECK on prod (verified 2026-04-26 via pg_get_constraintdef):
--   CHECK (subscription_status = ANY (ARRAY['free', 'premium', 'pro']))
--
-- The app uses 'free' and 'max' (post-rebrand). The CHECK was never
-- updated. 5 prod rows have subscription_status='premium'; 0 rows have
-- 'pro'. Migrate the 5 'premium' users to 'max', then replace the CHECK
-- with the current allowed set.
--
-- Order is fixed:
--   1) UPDATE rows to satisfy the new CHECK before applying it.
--   2) DROP the old CHECK.
--   3) ADD the new CHECK ('free', 'max').
--   4) Self-verify: pg_get_constraintdef returns the correct definition,
--      and zero rows violate the new CHECK.
--
-- post-rebrand fix; existing 'premium' tier users migrated to 'max' tier
-- identifier.

-- Step 1: migrate the legacy tier names.
UPDATE public.users
SET subscription_status = 'max'
WHERE subscription_status NOT IN ('free', 'max');

-- Step 2: drop the old CHECK.
ALTER TABLE public.users
  DROP CONSTRAINT IF EXISTS users_subscription_status_check;

-- Step 3: add the new CHECK.
ALTER TABLE public.users
  ADD CONSTRAINT users_subscription_status_check
  CHECK (subscription_status IN ('free', 'max'));

-- Step 4: self-verification.
DO $$
DECLARE
  v_def TEXT;
  v_violators INTEGER;
BEGIN
  SELECT pg_get_constraintdef(oid) INTO v_def
  FROM pg_constraint
  WHERE conrelid = 'public.users'::regclass
    AND conname = 'users_subscription_status_check';

  IF v_def IS NULL THEN
    RAISE EXCEPTION 'users_subscription_status_check does not exist after ADD';
  END IF;

  -- Postgres normalises ANY (ARRAY[...]) — accept either rendering.
  IF v_def NOT LIKE '%''free''%' OR v_def NOT LIKE '%''max''%' THEN
    RAISE EXCEPTION
      'users_subscription_status_check has unexpected definition: %', v_def;
  END IF;

  IF v_def LIKE '%''premium''%' OR v_def LIKE '%''pro''%' THEN
    RAISE EXCEPTION
      'users_subscription_status_check still allows legacy values: %', v_def;
  END IF;

  -- No rows should violate the new CHECK.
  SELECT COUNT(*) INTO v_violators
  FROM public.users
  WHERE subscription_status NOT IN ('free', 'max');

  IF v_violators <> 0 THEN
    RAISE EXCEPTION
      '% users still have a non-(free|max) subscription_status', v_violators;
  END IF;
END $$;
