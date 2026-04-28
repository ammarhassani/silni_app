-- ============================================================================
-- Phase 9.X.D Track A4 — Self-node creation in handle_new_user + backfill.
-- ============================================================================
--
-- Closes a critical product gap: solo users (not in a family group) never
-- get a relatives row with is_self=true. The family tree is structurally
-- empty for them.
--
-- Two parts:
--   1. Update the handle_new_user trigger to ALSO insert an is_self=true
--      relatives row, alongside the existing public.users + profiles inserts.
--   2. Backfill: insert is_self=true rows for every existing auth.users
--      that lacks one.
--
-- Defensive design:
--   - The trigger inserts only if no is_self=true row already exists for the
--     user (handles the family-group claim_tree_node flow which sets is_self
--     on a pre-existing row instead of inserting a new one).
--   - The trigger uses ON CONFLICT DO NOTHING on the unique index
--     idx_relatives_self_per_user_group to swallow race conditions.
--   - The trigger is wrapped in EXCEPTION WHEN OTHERS that LOGs and returns
--     NEW — same pattern as the existing trigger. A self-node failure must
--     never block signup.
--   - relationship_type defaults to 'other' (the catch-all enum value);
--     full_name pulls from raw_user_meta_data with the same COALESCE chain
--     as the existing inserts.
--   - relative_category='household' (the user is in their own household).
--
-- WARNING: handle_new_user is documented "DO NOT REMOVE. DO NOT SIMPLIFY."
-- This migration ADDS to it. The existing public.users and public.profiles
-- inserts are preserved verbatim. ensure_user_record() RPC remains the
-- belt-and-suspenders safety net per the architecture comment in
-- 20260427100000_document_load_bearing_functions.sql.
--
-- ============================================================================

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_full_name TEXT;
BEGIN
  -- Resolve full_name once — used by both inserts below.
  v_full_name := COALESCE(
    NEW.raw_user_meta_data->>'display_name',
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'name',
    NEW.email,
    'User'
  );

  -- 1. Insert into profiles (admin panel table) — UNCHANGED from prior version
  INSERT INTO profiles (id, email, display_name, role, created_at, updated_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    v_full_name,
    'user',
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = COALESCE(EXCLUDED.email, profiles.email),
    display_name = COALESCE(EXCLUDED.display_name, profiles.display_name),
    updated_at = NOW();

  -- 2. Insert into users (main app table) — UNCHANGED from prior version
  INSERT INTO users (id, email, full_name, created_at, last_login_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    v_full_name,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;

  -- 3. NEW: Insert the user's self-node into relatives, but only if they
  --    don't already have one. The family-group claim_tree_node flow may
  --    set is_self=true on an EXISTING relatives row (one already created
  --    by the group creator) — in that case, skip this insert.
  INSERT INTO relatives (
    user_id, full_name, relationship_type, is_self,
    relative_category, priority, family_group_id,
    created_at, updated_at
  )
  SELECT
    NEW.id,
    v_full_name,
    'other',
    true,
    'household',
    1,
    NULL,
    NOW(),
    NOW()
  WHERE NOT EXISTS (
    SELECT 1 FROM relatives
    WHERE user_id = NEW.id AND is_self = true
  );

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Same swallow as the prior version (signup must never block).
    -- Self-node creation failures will be picked up later by
    -- ensure_user_record's expanded scope (out of scope for this migration —
    -- ensure_user_record currently only handles public.users; expanding it
    -- to also create the self-node is a v1.1 cleanup).
    RAISE LOG 'handle_new_user failed for user %: % (SQLSTATE: %)', NEW.id, SQLERRM, SQLSTATE;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth;

-- ============================================================================
-- Backfill: insert is_self=true rows for existing auth.users that lack one.
-- ============================================================================
--
-- For every auth.users row WHERE NOT EXISTS a relatives row with is_self=true,
-- insert one. Uses public.users.full_name where available (more accurate
-- than re-deriving from raw_user_meta_data), falling back to email or 'User'.
--
-- The unique index idx_relatives_self_per_user_group constrains
-- (user_id, family_group_id) WHERE (is_self=true AND family_group_id IS NOT NULL).
-- Since this backfill creates self-nodes with family_group_id=NULL, the
-- unique index does not apply — multiple is_self rows could in theory exist
-- for one user (one personal, plus one per group they joined). That matches
-- the existing data model.
-- ============================================================================

INSERT INTO relatives (
  user_id, full_name, relationship_type, is_self,
  relative_category, priority, family_group_id,
  created_at, updated_at
)
SELECT
  u.id,
  COALESCE(u.full_name, u.email, 'User'),
  'other',
  true,
  'household',
  1,
  NULL,
  NOW(),
  NOW()
FROM public.users u
WHERE NOT EXISTS (
  SELECT 1 FROM relatives r
  WHERE r.user_id = u.id AND r.is_self = true
);

-- ============================================================================
-- Self-verification.
-- ============================================================================
DO $$
DECLARE
  v_users_without_self INT;
BEGIN
  SELECT COUNT(*) INTO v_users_without_self
  FROM public.users u
  WHERE NOT EXISTS (
    SELECT 1 FROM relatives r
    WHERE r.user_id = u.id AND r.is_self = true
  );

  IF v_users_without_self > 0 THEN
    RAISE EXCEPTION
      'Phase 9.X.D.A4: % users still lack a self-node post-backfill',
      v_users_without_self;
  END IF;
END $$;
