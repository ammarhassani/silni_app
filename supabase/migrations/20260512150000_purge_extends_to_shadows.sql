-- 20260512150000_purge_extends_to_shadows.sql
-- _purge_member_group_data now also deletes the departing user's personal
-- shadows that mirror relatives in the group being purged. Without this,
-- a kicked joiner keeps stale shadows (e.g. "my husband testprod") even
-- though the relationship has been severed.

CREATE OR REPLACE FUNCTION public._purge_member_group_data(
  p_group_id UUID,
  p_user_id UUID
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_their_ids UUID[];
  v_their_ids_text TEXT[];
  v_canonical_ids UUID[];   -- NEW: snapshot of canonicals in this group at start
  v_shadow_ids UUID[];
  v_shadow_ids_text TEXT[];
BEGIN
  -- 1. Collect relatives the departing user owns in this group
  SELECT COALESCE(array_agg(id), ARRAY[]::uuid[])
    INTO v_their_ids
    FROM relatives
   WHERE family_group_id = p_group_id AND user_id = p_user_id;

  v_their_ids_text := ARRAY(SELECT unnest(v_their_ids)::text);

  -- 2. NEW: snapshot canonical relative ids that live in this group.
  --    Needed because step 5 references them AFTER they're deleted.
  SELECT COALESCE(array_agg(id), ARRAY[]::uuid[])
    INTO v_canonical_ids
    FROM relatives
   WHERE family_group_id = p_group_id;

  -- 3. Delete interactions on the departing user's relatives (existing)
  DELETE FROM interactions
   WHERE relative_id = ANY(v_their_ids);

  -- 4. Delete edges in this group: either owned by user or referencing their relatives (existing)
  DELETE FROM family_edges
   WHERE family_group_id = p_group_id
     AND (
       user_id = p_user_id
       OR from_id = ANY(v_their_ids_text)
       OR to_id   = ANY(v_their_ids_text)
     );

  -- 5. Delete the departing user's relatives in this group (existing)
  DELETE FROM relatives
   WHERE family_group_id = p_group_id AND user_id = p_user_id;

  -- 6. NEW: Delete the departing user's personal shadows that mirrored
  --    relatives in this group. These shadows are now stale (the relationship
  --    has ended). Also delete their anchor edges and any interactions.
  SELECT COALESCE(array_agg(id), ARRAY[]::uuid[])
    INTO v_shadow_ids
    FROM relatives sh
   WHERE sh.user_id = p_user_id
     AND sh.family_group_id IS NULL
     AND sh.mirrors_relative_id = ANY(v_canonical_ids);

  v_shadow_ids_text := ARRAY(SELECT unnest(v_shadow_ids)::text);

  -- Interactions on shadows
  DELETE FROM interactions
   WHERE relative_id = ANY(v_shadow_ids);

  -- Personal-scope edges referencing the shadows
  DELETE FROM family_edges
   WHERE family_group_id IS NULL
     AND user_id = p_user_id
     AND (
       from_id = ANY(v_shadow_ids_text)
       OR to_id = ANY(v_shadow_ids_text)
     );

  -- The shadows themselves
  DELETE FROM relatives
   WHERE id = ANY(v_shadow_ids);
END;
$$;

REVOKE EXECUTE ON FUNCTION public._purge_member_group_data(UUID, UUID) FROM PUBLIC;
