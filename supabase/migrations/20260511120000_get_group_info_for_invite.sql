-- 20260511120000_get_group_info_for_invite.sql
-- Single bootstrap call for the identity-claim wizard's pre-member phase.
--
-- The wizard needs the group name, admin's display name/avatar (for the
-- "you're joining X's family" banner), and the list of relatives in the
-- group (to seed the anchor picker) BEFORE the caller is a member.
-- Each of those queries would otherwise be blocked by membership-gated RLS.
-- This SECURITY DEFINER RPC bundles them into one round-trip, authed by
-- the invite code itself.
--
-- Column-name notes (verified against live DB on 2026-05-11):
--   profiles uses display_name (not full_name) — returned as admin_name.
--   profiles.avatar_url is present.
--   relatives has family_group_id, is_self, relationship_type, gender, full_name.

CREATE OR REPLACE FUNCTION public.get_group_info_for_invite(
  p_invite_code TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_group RECORD;
  v_admin RECORD;
  v_relatives JSONB;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT id, name, invite_code, created_by, created_at
    INTO v_group
    FROM family_groups
   WHERE invite_code = p_invite_code;

  IF v_group.id IS NULL THEN
    RAISE EXCEPTION 'رمز الدعوة غير صالح';
  END IF;

  -- Admin profile (for the "you're joining X's family" banner).
  SELECT p.display_name, p.avatar_url
    INTO v_admin
    FROM profiles p
   WHERE p.id = v_group.created_by;

  -- Tree members visible from the wizard's anchor picker.
  -- Returns minimal fields — wizard doesn't need full relative records yet.
  -- COALESCE so empty groups return [] (not null) for client convenience.
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
           'id', r.id,
           'full_name', r.full_name,
           'gender', r.gender,
           'is_self', r.is_self,
           'admin_label', r.relationship_type
         )), '[]'::jsonb)
    INTO v_relatives
    FROM relatives r
   WHERE r.family_group_id = v_group.id;

  RETURN jsonb_build_object(
    'group_id', v_group.id,
    'group_name', v_group.name,
    'admin_name', v_admin.display_name,
    'admin_avatar_url', v_admin.avatar_url,
    'relatives', v_relatives
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_group_info_for_invite(TEXT) TO authenticated;
