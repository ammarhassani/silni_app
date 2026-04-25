-- DATABASE_AUDIT C3 + H4: documentation-only migration that re-defines
-- four load-bearing functions with prepended architecture comment
-- blocks. Bodies are byte-identical to the latest authoritative
-- definitions. The point is to make the next contributor STOP before
-- "simplifying" or removing them.
--
-- Re-creating the functions (rather than editing earlier migrations) is
-- the discipline declared in CONTRIBUTING.md: migrations are append-only.
--
-- Functions documented here:
--   1. handle_new_user                — trigger on auth.users INSERT
--   2. ensure_user_record             — client-callable login self-heal
--   3. auth_user_group_ids            — RLS recursion-breaker (members)
--   4. auth_user_admin_group_ids      — RLS recursion-breaker (admins)

-- ============================================================================
-- 1. handle_new_user — trigger on auth.users INSERT
-- ============================================================================
-- DO NOT REMOVE.  DO NOT SIMPLIFY.
--
-- This trigger has been remediated 5+ times across migrations:
--   - 20250128100000_fix_profiles_sync_production.sql
--   - 20251230100002_admin_profiles.sql
--   - 20260103100000_sync_auth_users_to_profiles.sql
--   - 20260109100000_fix_signup_trigger.sql
--   - 20260129100000_fix_all_user_sync.sql   ← previous authoritative
--   - 20260129110000_fix_trigger_search_path.sql
--   - 20260208140003_trigger_and_policy_fixes.sql
--
-- Every time someone tried to "clean it up" something silent broke. The
-- current shape is: insert into BOTH public.profiles (admin panel) and
-- public.users (main app) on every new auth.users row, with
-- ON CONFLICT recovery, and an EXCEPTION WHEN OTHERS swallow so a
-- per-user trigger failure NEVER blocks signup.
--
-- The catch is that the EXCEPTION swallow turns trigger bugs into silent
-- orphan-row bugs: a user can sign up, the trigger logs an error, the
-- user has no public.users row, and every subsequent operation that
-- needs the FK fails with 23503.
--
-- The Phase-3 hot-fix (20260425100000_ensure_user_record...) made
-- ensure_user_record() the durable safety net — the Flutter client
-- calls it on every signedIn / initialSession event, so even if the
-- trigger silently fails the public.users row gets re-created on the
-- next login. The trigger and the RPC are belt + suspenders.
--
-- DO NOT remove either one.
-- DO NOT merge them ("the RPC supersedes the trigger" is wrong — the
--   trigger fires for every flow, including ones where the client never
--   gets a chance to call the RPC, like edge-function-initiated user
--   provisioning).
-- DO NOT change the EXCEPTION swallow without auditing every call site
--   that depends on signup never blocking.

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert into profiles (admin panel table)
  INSERT INTO profiles (id, email, display_name, role, created_at, updated_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    COALESCE(
      NEW.raw_user_meta_data->>'display_name',
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      NEW.email,
      'User'
    ),
    'user',
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = COALESCE(EXCLUDED.email, profiles.email),
    display_name = COALESCE(EXCLUDED.display_name, profiles.display_name),
    updated_at = NOW();

  -- Insert into users (main app table)
  INSERT INTO users (id, email, full_name, created_at, last_login_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    COALESCE(
      NEW.raw_user_meta_data->>'display_name',
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      NEW.email,
      'User'
    ),
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- See the architecture comment above. This swallow is INTENTIONAL.
    -- ensure_user_record() picks up the slack on the next login.
    RAISE LOG 'handle_new_user failed for user %: % (SQLSTATE: %)', NEW.id, SQLERRM, SQLSTATE;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth;

COMMENT ON FUNCTION handle_new_user() IS
'Trigger function on auth.users INSERT. Mirrors new auth users into '
'public.users and public.profiles. Belt-and-suspenders with '
'ensure_user_record() — see migration 20260427100000 for the full '
'architecture rationale and the list of prior remediation attempts.';

-- ============================================================================
-- 2. ensure_user_record — client-callable login self-heal
-- ============================================================================
-- DO NOT REMOVE.  DO NOT MERGE WITH handle_new_user().
--
-- Phase-3 added this RPC (20260425100000) because handle_new_user fires
-- only on auth.users INSERT. After delete_user_account, re-login via the
-- same OAuth provider reuses the existing auth.users row → no INSERT →
-- no trigger → public.users never gets re-created → FK violations on
-- everything that references public.users(id).
--
-- The Flutter client calls this RPC on every signedIn / initialSession
-- event in main.dart's onAuthStateChange listener. Cheap (~one upsert),
-- safe to call repeatedly, idempotent. Reads from auth.users via DEFINER
-- and upserts into both public.users and public.profiles.
--
-- This is paired with the trigger above — both must exist.
-- The EXCEPTION swallow at the bottom mirrors the trigger's behavior
-- so a failed self-heal never blocks the user from using the app.

CREATE OR REPLACE FUNCTION ensure_user_record()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_email TEXT;
  v_name TEXT;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN;
  END IF;

  SELECT
    email,
    COALESCE(
      raw_user_meta_data->>'display_name',
      raw_user_meta_data->>'full_name',
      raw_user_meta_data->>'name',
      email,
      'User'
    )
  INTO v_email, v_name
  FROM auth.users
  WHERE id = v_user_id;

  IF v_email IS NULL THEN
    -- auth.users row vanished mid-flight; nothing to mirror.
    RETURN;
  END IF;

  INSERT INTO users (id, email, full_name, created_at, last_login_at)
  VALUES (v_user_id, v_email, v_name, NOW(), NOW())
  ON CONFLICT (id) DO UPDATE
    SET last_login_at = NOW();

  INSERT INTO profiles (id, email, display_name, role, created_at, updated_at)
  VALUES (v_user_id, v_email, v_name, 'user', NOW(), NOW())
  ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email,
        display_name = EXCLUDED.display_name,
        updated_at = NOW();
EXCEPTION
  WHEN OTHERS THEN
    -- Never block the client. The next sign-in will retry.
    RAISE LOG 'ensure_user_record failed for user %: % (SQLSTATE: %)',
      v_user_id, SQLERRM, SQLSTATE;
END;
$$;

GRANT EXECUTE ON FUNCTION ensure_user_record() TO authenticated;

COMMENT ON FUNCTION ensure_user_record() IS
'Client-callable login self-heal. Idempotently upserts the public.users '
'and public.profiles rows for the current auth.uid() from auth.users. '
'Belt-and-suspenders with the handle_new_user trigger — see migration '
'20260427100000 for the full architecture rationale.';

-- ============================================================================
-- 3. auth_user_group_ids — RLS recursion-breaker (members)
-- ============================================================================
-- DO NOT REMOVE.  DO NOT BYPASS.  DO NOT INLINE.
--
-- Recursion incident: the SELECT policy on family_group_members
-- referenced itself in a subquery, causing PostgreSQL error 42P17
-- (infinite recursion) whenever any query touched family_group_members —
-- including relatives queries whose RLS policies also reference
-- family_group_members. See migration 20260204100000 for the original
-- incident and fix.
--
-- This SECURITY DEFINER function bypasses RLS to return the current
-- user's group IDs without triggering the recursive policy chain.
--
-- Every RLS policy that needs to express "is the current user a member
-- of this group" MUST go through this function instead of writing a
-- direct subquery against family_group_members. Currently used by at
-- least 6 policies across family_group_members, family_groups,
-- relatives, family_edges, and others.
--
-- If you find yourself writing a new RLS policy with a subquery against
-- family_group_members.user_id = auth.uid(), STOP. Use this function.

CREATE OR REPLACE FUNCTION auth_user_group_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT group_id FROM family_group_members WHERE user_id = auth.uid();
$$;

COMMENT ON FUNCTION auth_user_group_ids() IS
'RLS recursion-breaker. Returns the current user''s group IDs without '
'triggering family_group_members SELECT policy. Required by every RLS '
'policy that needs "current user is a member of group" semantics. See '
'migration 20260427100000 for architecture and 20260204100000 for the '
'original recursion incident.';

-- ============================================================================
-- 4. auth_user_admin_group_ids — RLS recursion-breaker (admins)
-- ============================================================================
-- DO NOT REMOVE.  DO NOT BYPASS.  DO NOT INLINE.
--
-- Same recursion-breaker pattern as auth_user_group_ids() above, but
-- filtered to groups where the caller has role = 'admin'. Used by
-- DELETE / UPDATE policies that should only apply when the current user
-- is an admin of the target group.

CREATE OR REPLACE FUNCTION auth_user_admin_group_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT group_id FROM family_group_members
  WHERE user_id = auth.uid() AND role = 'admin';
$$;

COMMENT ON FUNCTION auth_user_admin_group_ids() IS
'RLS recursion-breaker for admin-only policies. Returns group IDs where '
'the current user has role = admin. See migration 20260427100000 for '
'architecture and 20260204100000 for the original recursion incident.';
