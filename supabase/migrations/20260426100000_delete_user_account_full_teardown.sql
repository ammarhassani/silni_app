-- Delete-account hot-fix #2: comprehensive teardown.
--
-- Bug observed in TestFlight after migration 20260425100000:
--   delete_user_account() did
--     DELETE FROM users  WHERE id = auth.uid();
--     DELETE FROM auth.users WHERE id = v_user_id;
--   but several tables FK to auth.users(id) WITHOUT ON DELETE CASCADE:
--     - family_groups.created_by    (NOT NULL, NO ACTION)
--     - family_group_members.user_id (NOT NULL, NO ACTION)
--     - node_invitations.invited_by  (NOT NULL, NO ACTION)
--     - node_invitations.accepted_by (nullable, NO ACTION)
--   If the user had ever created a group, joined a group, sent or
--   accepted an invitation, the auth.users delete raised 23503 and the
--   whole transaction rolled back. The user-visible symptom was a
--   "cannot delete: related data exists" error and the account staying
--   alive with all its data.
--
-- This migration does the teardown in dependency order before touching
-- auth.users. Group membership is unwound through leave_group_atomic so
-- admin transfer + ghost-group cleanup stay consistent with the
-- "Leave group" UI flow.

CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_group_id UUID;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- 1. Leave every group the user is in.
  --    leave_group_atomic handles: admin transfer if last admin, self-node
  --    cleanup, member row removal, and ghost-group deletion if the user
  --    was the last member. Idempotent if not a member.
  FOR v_group_id IN
    SELECT group_id
    FROM family_group_members
    WHERE user_id = v_user_id
  LOOP
    PERFORM leave_group_atomic(v_group_id, v_user_id);
  END LOOP;

  -- 2. Drop sent invitations outright (recipient gets to keep nothing
  --    actionable from a deleted inviter).
  DELETE FROM node_invitations WHERE invited_by = v_user_id;

  -- 3. Unlink accepted invitations (preserve the historical row so the
  --    other side's audit trail stays intact, just lose the FK to us).
  UPDATE node_invitations
  SET accepted_by = NULL
  WHERE accepted_by = v_user_id;

  -- 4. Drop public.users — cascades relatives, interactions,
  --    reminder_schedules, fcm_tokens, streak_freezes, relative_streaks,
  --    subscription_state, premium_onboarding, smart_nudges, etc. (all
  --    public-side tables FK to public.users with ON DELETE CASCADE).
  DELETE FROM users WHERE id = v_user_id;

  -- 5. Drop auth.users so re-login with the same provider creates a
  --    genuinely new account. Anything still FK'd to auth.users at this
  --    point would surface as 23503 — which means there's a missed
  --    cleanup step above, and the transaction rolling back is the
  --    correct safety net.
  DELETE FROM auth.users WHERE id = v_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION delete_user_account() TO authenticated;
