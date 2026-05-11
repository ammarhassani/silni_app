-- ============================================================================
-- 20260512110000_personal_self_node_guarantee.sql
-- ============================================================================
-- Backfill personal NULL-scope self-nodes for users who don't have one.
--
-- Why this is needed:
--   When admin approves a "claim me" request, we project a personal-scope
--   shadow of the admin into the claimant's personal scope. The shadow row
--   needs to anchor (via family_edges) to the claimant's PERSONAL NULL-scope
--   self-node. If the claimant has no NULL-scope self-node (only group-scoped
--   ones), the shadow has no anchor and the cross-group projection breaks.
--
-- The self_node_on_signup trigger (20260428620000) auto-creates a personal
-- self-node for new users, but its WHERE clause checks for ANY is_self row
-- (any scope). So users who later had their personal self-node deleted (e.g.
-- testprodjoiner after the kick-purge cleanup) but still have a group-scoped
-- is_self row don't get re-created.
--
-- Probe (run 2026-05-11): 4 users missing — testprod, azahrani337 (Ammar),
-- testprodjoiner, testfaminviter. All have group-scoped self-nodes but no
-- NULL-scope personal one. Manageable; no abort needed.
--
-- INSERT shape mirrors the trigger in 20260428620000_self_node_on_signup.sql
-- for consistency: relationship_type='other', relative_category='household',
-- priority=1, family_group_id=NULL, plus timestamps. full_name resolved from
-- public.users (more accurate than re-deriving from raw_user_meta_data) with
-- the same fallback chain as the trigger's backfill section.
-- ============================================================================

BEGIN;

DO $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM auth.users u
  WHERE NOT EXISTS (
    SELECT 1 FROM public.relatives r
    WHERE r.user_id = u.id
      AND r.is_self = true
      AND r.family_group_id IS NULL
  );
  RAISE NOTICE 'Backfilling % personal NULL-scope self-nodes', v_count;
END $$;

INSERT INTO public.relatives (
  user_id, full_name, relationship_type, is_self,
  relative_category, priority, family_group_id,
  created_at, updated_at
)
SELECT
  u.id,
  COALESCE(pu.full_name, u.email, 'User'),
  'other',
  true,
  'household',
  1,
  NULL,
  NOW(),
  NOW()
FROM auth.users u
LEFT JOIN public.users pu ON pu.id = u.id
WHERE NOT EXISTS (
  SELECT 1 FROM public.relatives r
  WHERE r.user_id = u.id
    AND r.is_self = true
    AND r.family_group_id IS NULL
);

-- ============================================================================
-- Self-verification.
-- ============================================================================
DO $$
DECLARE
  v_still_missing INT;
  v_duplicates INT;
BEGIN
  SELECT COUNT(*) INTO v_still_missing
  FROM auth.users u
  WHERE NOT EXISTS (
    SELECT 1 FROM public.relatives r
    WHERE r.user_id = u.id
      AND r.is_self = true
      AND r.family_group_id IS NULL
  );

  IF v_still_missing > 0 THEN
    RAISE EXCEPTION
      'personal_self_node_guarantee: % users still lack a NULL-scope self-node post-backfill',
      v_still_missing;
  END IF;

  SELECT COUNT(*) INTO v_duplicates
  FROM (
    SELECT user_id
    FROM public.relatives
    WHERE is_self = true AND family_group_id IS NULL
    GROUP BY user_id
    HAVING COUNT(*) > 1
  ) dups;

  IF v_duplicates > 0 THEN
    RAISE EXCEPTION
      'personal_self_node_guarantee: % users have multiple NULL-scope self-nodes',
      v_duplicates;
  END IF;
END $$;

COMMIT;
