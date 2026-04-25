-- Phase 3 hot-fix: keep public.users row in sync with auth.users on every sign-in,
-- and make delete_user_account a complete teardown.
--
-- Bug observed in TestFlight:
--   1. User signs up, public.users row created via handle_new_user trigger.
--   2. User calls delete_user_account → public.users row removed (cascade).
--   3. User re-logs in via Google OAuth → auth.users row REUSED (Google links by sub),
--      no INSERT to auth.users, so handle_new_user does NOT fire.
--   4. public.users is now empty for this auth.uid().
--   5. Any operation needing the FK (relatives.user_id, family_edges.user_id, etc.)
--      raises 23503 "Key is not present in table 'users'".
--
-- The user-visible symptom was a PostgrestException on family-group creation:
--   `relatives_user_id_fkey violates foreign key constraint`.

-- ============================================================================
-- 1. ensure_user_record() — idempotent client-callable upsert
-- ============================================================================
--
-- Called from the Flutter app on every signedIn / initialSession event in
-- the onAuthStateChange listener (main.dart). Cheap to call (~one upsert),
-- safe to call repeatedly. Reads from auth.users via the DEFINER's elevated
-- access and upserts into both public.users and public.profiles.

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

  -- public.users — main app FK target. ON CONFLICT touches last_login_at so
  -- analytics / engagement queries see the most recent login.
  INSERT INTO users (id, email, full_name, created_at, last_login_at)
  VALUES (v_user_id, v_email, v_name, NOW(), NOW())
  ON CONFLICT (id) DO UPDATE
    SET last_login_at = NOW();

  -- public.profiles — admin panel mirror. Keep in sync so the admin tools
  -- show this user even on first re-login after account deletion.
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

-- ============================================================================
-- 2. delete_user_account() — also delete the auth.users row
-- ============================================================================
--
-- Old behavior (migration 20260425000000):
--   DELETE FROM users WHERE id = auth.uid()
--   The auth.users row was left intact, which means re-login with the same
--   provider (Google OAuth, Apple) reused it without firing handle_new_user.
--
-- New behavior:
--   Delete public.users (cascades the user's data) AND auth.users (so the
--   next sign-in is a true new account). This requires the function to be
--   owned by `postgres` role; SECURITY DEFINER + the GRANT EXECUTE pattern
--   gives an authenticated caller permission to invoke without owning auth.

CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- 1. Drop the public mirror first; ON DELETE CASCADE on relatives,
  --    interactions, reminder_schedules, family_group_members, etc. fans out.
  DELETE FROM users WHERE id = v_user_id;

  -- 2. Drop the auth row so next sign-in is a real new account.
  --    Supabase Auth requires service_role for auth.admin.deleteUser; this
  --    SECURITY DEFINER function reaches the same effect because it runs
  --    as the function owner.
  DELETE FROM auth.users WHERE id = v_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION delete_user_account() TO authenticated;
