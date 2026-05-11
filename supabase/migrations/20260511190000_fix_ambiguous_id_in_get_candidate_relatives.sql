-- 20260511190000_fix_ambiguous_id_in_get_candidate_relatives.sql
-- Fix: column reference "id" is ambiguous (code 42702).
--
-- get_candidate_relatives RETURNS TABLE(id uuid, ...). Postgres treats
-- `id` as a local OUT-parameter variable inside the function body. The
-- invite-code auth check did `WHERE id = p_group_id` against
-- `family_groups`, and PG couldn't tell whether `id` referred to the
-- OUT param or the column. Member path didn't hit this query so the
-- bug only manifested when a non-member submitted via the invite path.
--
-- Fix: fully-qualify `family_groups.id`. (Every other `id` reference
-- in the function body is already aliased.)

CREATE OR REPLACE FUNCTION public.get_candidate_relatives(
  p_group_id UUID,
  p_anchor_relative_id UUID,
  p_edge_path TEXT,
  p_parent_side TEXT,
  p_gender TEXT,
  p_invite_code TEXT DEFAULT NULL
)
RETURNS TABLE(
  id UUID,
  full_name TEXT,
  gender TEXT,
  date_of_birth TIMESTAMP WITH TIME ZONE,
  parent_full_name TEXT,
  is_self BOOLEAN,
  is_already_claimed BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_is_member BOOLEAN;
  v_code_valid BOOLEAN;
  v_target_parent_gender TEXT;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT EXISTS(
    SELECT 1 FROM family_group_members
    WHERE group_id = p_group_id AND user_id = v_caller
  ) INTO v_is_member;

  IF NOT v_is_member THEN
    IF p_invite_code IS NULL THEN
      RAISE EXCEPTION 'Caller is not a member of this group';
    END IF;
    -- Qualify family_groups.id to disambiguate from the OUT parameter `id`.
    SELECT EXISTS(
      SELECT 1 FROM family_groups fg
       WHERE fg.id = p_group_id AND fg.invite_code = p_invite_code
    ) INTO v_code_valid;
    IF NOT v_code_valid THEN
      RAISE EXCEPTION 'Invalid invite code';
    END IF;
  END IF;

  IF p_edge_path NOT IN ('parent', 'child', 'spouse', 'sibling',
                         'grandparent', 'grandchild',
                         'uncle_aunt', 'nephew_niece', 'cousin') THEN
    RAISE EXCEPTION 'Invalid edge_path: %', p_edge_path;
  END IF;

  IF p_gender NOT IN ('male', 'female') THEN
    RAISE EXCEPTION 'Invalid gender: %', p_gender;
  END IF;

  IF p_parent_side IS NOT NULL AND p_parent_side NOT IN ('paternal', 'maternal') THEN
    RAISE EXCEPTION 'Invalid parent_side: %', p_parent_side;
  END IF;

  v_target_parent_gender := CASE p_parent_side
    WHEN 'paternal' THEN 'male'
    WHEN 'maternal' THEN 'female'
    ELSE NULL
  END;

  IF p_edge_path = 'parent' THEN
    RETURN QUERY
    SELECT r.id, r.full_name, r.gender, r.date_of_birth,
           NULL::TEXT AS parent_full_name,
           r.is_self,
           EXISTS (SELECT 1 FROM family_group_members fgm
                    WHERE fgm.group_id = p_group_id
                      AND fgm.relative_id_in_tree = r.id) AS is_already_claimed
    FROM family_edges e
    JOIN relatives r ON r.id::text = e.from_id
    WHERE e.to_id = p_anchor_relative_id::text
      AND e.edge_type = 'parent_of'
      AND e.family_group_id = p_group_id
      AND r.gender = p_gender
      AND r.is_self = false;

  ELSIF p_edge_path = 'child' THEN
    RETURN QUERY
    SELECT r.id, r.full_name, r.gender, r.date_of_birth,
           NULL::TEXT AS parent_full_name,
           r.is_self,
           EXISTS (SELECT 1 FROM family_group_members fgm
                    WHERE fgm.group_id = p_group_id
                      AND fgm.relative_id_in_tree = r.id) AS is_already_claimed
    FROM family_edges e
    JOIN relatives r ON r.id::text = e.to_id
    WHERE e.from_id = p_anchor_relative_id::text
      AND e.edge_type = 'parent_of'
      AND e.family_group_id = p_group_id
      AND r.gender = p_gender
      AND r.is_self = false;

  ELSIF p_edge_path = 'sibling' THEN
    RETURN QUERY
    SELECT DISTINCT r.id, r.full_name, r.gender, r.date_of_birth,
           NULL::TEXT AS parent_full_name,
           r.is_self,
           EXISTS (SELECT 1 FROM family_group_members fgm
                    WHERE fgm.group_id = p_group_id
                      AND fgm.relative_id_in_tree = r.id) AS is_already_claimed
    FROM family_edges e
    JOIN relatives r ON (r.id::text = e.from_id OR r.id::text = e.to_id)
                     AND r.id != p_anchor_relative_id
    WHERE (e.from_id = p_anchor_relative_id::text OR e.to_id = p_anchor_relative_id::text)
      AND e.edge_type = 'sibling_of'
      AND e.family_group_id = p_group_id
      AND r.gender = p_gender
      AND r.is_self = false;

  ELSIF p_edge_path = 'spouse' THEN
    RETURN QUERY
    SELECT DISTINCT r.id, r.full_name, r.gender, r.date_of_birth,
           NULL::TEXT AS parent_full_name,
           r.is_self,
           EXISTS (SELECT 1 FROM family_group_members fgm
                    WHERE fgm.group_id = p_group_id
                      AND fgm.relative_id_in_tree = r.id) AS is_already_claimed
    FROM family_edges e
    JOIN relatives r ON (r.id::text = e.from_id OR r.id::text = e.to_id)
                     AND r.id != p_anchor_relative_id
    WHERE (e.from_id = p_anchor_relative_id::text OR e.to_id = p_anchor_relative_id::text)
      AND e.edge_type = 'spouse_of'
      AND e.family_group_id = p_group_id
      AND r.gender = p_gender
      AND r.is_self = false;

  ELSIF p_edge_path = 'uncle_aunt' THEN
    RETURN QUERY
    WITH anchor_parents AS (
      SELECT pr.id AS parent_id, pr.full_name AS parent_name
      FROM family_edges e
      JOIN relatives pr ON pr.id::text = e.from_id
      WHERE e.to_id = p_anchor_relative_id::text
        AND e.edge_type = 'parent_of'
        AND e.family_group_id = p_group_id
        AND (v_target_parent_gender IS NULL OR pr.gender = v_target_parent_gender)
    )
    SELECT DISTINCT r.id, r.full_name, r.gender, r.date_of_birth,
           ap.parent_name AS parent_full_name,
           r.is_self,
           EXISTS (SELECT 1 FROM family_group_members fgm
                    WHERE fgm.group_id = p_group_id
                      AND fgm.relative_id_in_tree = r.id) AS is_already_claimed
    FROM anchor_parents ap
    JOIN family_edges se ON (se.from_id = ap.parent_id::text OR se.to_id = ap.parent_id::text)
    JOIN relatives r ON (r.id::text = se.from_id OR r.id::text = se.to_id)
                     AND r.id != ap.parent_id
    WHERE se.edge_type = 'sibling_of'
      AND se.family_group_id = p_group_id
      AND r.gender = p_gender
      AND r.is_self = false;

  ELSIF p_edge_path = 'cousin' THEN
    RETURN QUERY
    WITH anchor_parents AS (
      SELECT pr.id AS parent_id
      FROM family_edges e
      JOIN relatives pr ON pr.id::text = e.from_id
      WHERE e.to_id = p_anchor_relative_id::text
        AND e.edge_type = 'parent_of'
        AND e.family_group_id = p_group_id
        AND (v_target_parent_gender IS NULL OR pr.gender = v_target_parent_gender)
    ),
    parents_siblings AS (
      SELECT DISTINCT sr.id AS sibling_id, sr.full_name AS sibling_name
      FROM anchor_parents ap
      JOIN family_edges se ON (se.from_id = ap.parent_id::text OR se.to_id = ap.parent_id::text)
      JOIN relatives sr ON (sr.id::text = se.from_id OR sr.id::text = se.to_id)
                        AND sr.id != ap.parent_id
      WHERE se.edge_type = 'sibling_of'
        AND se.family_group_id = p_group_id
    )
    SELECT DISTINCT r.id, r.full_name, r.gender, r.date_of_birth,
           ps.sibling_name AS parent_full_name,
           r.is_self,
           EXISTS (SELECT 1 FROM family_group_members fgm
                    WHERE fgm.group_id = p_group_id
                      AND fgm.relative_id_in_tree = r.id) AS is_already_claimed
    FROM parents_siblings ps
    JOIN family_edges ce ON ce.from_id = ps.sibling_id::text
    JOIN relatives r ON r.id::text = ce.to_id
    WHERE ce.edge_type = 'parent_of'
      AND ce.family_group_id = p_group_id
      AND r.gender = p_gender
      AND r.is_self = false;

  ELSIF p_edge_path = 'grandparent' THEN
    RETURN QUERY
    WITH anchor_parents AS (
      SELECT pr.id AS parent_id
      FROM family_edges e
      JOIN relatives pr ON pr.id::text = e.from_id
      WHERE e.to_id = p_anchor_relative_id::text
        AND e.edge_type = 'parent_of'
        AND e.family_group_id = p_group_id
        AND (v_target_parent_gender IS NULL OR pr.gender = v_target_parent_gender)
    )
    SELECT DISTINCT r.id, r.full_name, r.gender, r.date_of_birth,
           NULL::TEXT AS parent_full_name,
           r.is_self,
           EXISTS (SELECT 1 FROM family_group_members fgm
                    WHERE fgm.group_id = p_group_id
                      AND fgm.relative_id_in_tree = r.id) AS is_already_claimed
    FROM anchor_parents ap
    JOIN family_edges ge ON ge.to_id = ap.parent_id::text
    JOIN relatives r ON r.id::text = ge.from_id
    WHERE ge.edge_type = 'parent_of'
      AND ge.family_group_id = p_group_id
      AND r.gender = p_gender
      AND r.is_self = false;

  ELSIF p_edge_path = 'grandchild' THEN
    RETURN QUERY
    WITH anchor_children AS (
      SELECT cr.id AS child_id, cr.full_name AS child_name
      FROM family_edges e
      JOIN relatives cr ON cr.id::text = e.to_id
      WHERE e.from_id = p_anchor_relative_id::text
        AND e.edge_type = 'parent_of'
        AND e.family_group_id = p_group_id
    )
    SELECT DISTINCT r.id, r.full_name, r.gender, r.date_of_birth,
           ac.child_name AS parent_full_name,
           r.is_self,
           EXISTS (SELECT 1 FROM family_group_members fgm
                    WHERE fgm.group_id = p_group_id
                      AND fgm.relative_id_in_tree = r.id) AS is_already_claimed
    FROM anchor_children ac
    JOIN family_edges gce ON gce.from_id = ac.child_id::text
    JOIN relatives r ON r.id::text = gce.to_id
    WHERE gce.edge_type = 'parent_of'
      AND gce.family_group_id = p_group_id
      AND r.gender = p_gender
      AND r.is_self = false;

  ELSIF p_edge_path = 'nephew_niece' THEN
    RETURN QUERY
    WITH anchor_siblings AS (
      SELECT DISTINCT sr.id AS sibling_id, sr.full_name AS sibling_name
      FROM family_edges e
      JOIN relatives sr ON (sr.id::text = e.from_id OR sr.id::text = e.to_id)
                        AND sr.id != p_anchor_relative_id
      WHERE (e.from_id = p_anchor_relative_id::text OR e.to_id = p_anchor_relative_id::text)
        AND e.edge_type = 'sibling_of'
        AND e.family_group_id = p_group_id
    )
    SELECT DISTINCT r.id, r.full_name, r.gender, r.date_of_birth,
           asb.sibling_name AS parent_full_name,
           r.is_self,
           EXISTS (SELECT 1 FROM family_group_members fgm
                    WHERE fgm.group_id = p_group_id
                      AND fgm.relative_id_in_tree = r.id) AS is_already_claimed
    FROM anchor_siblings asb
    JOIN family_edges ce ON ce.from_id = asb.sibling_id::text
    JOIN relatives r ON r.id::text = ce.to_id
    WHERE ce.edge_type = 'parent_of'
      AND ce.family_group_id = p_group_id
      AND r.gender = p_gender
      AND r.is_self = false;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_candidate_relatives(UUID, UUID, TEXT, TEXT, TEXT, TEXT) TO authenticated;
