-- ============================================================================
-- get_candidate_relatives RPC
-- ============================================================================
-- Heart of the identity-claim discovery flow. Given an anchor relative and a
-- declared relationship (edge_path + parent_side + gender, matching the
-- admin_relationship_labels schema), return the candidate tree nodes the
-- joiner could be claiming.
--
-- Traverses family_edges (parent_of / sibling_of / spouse_of) within the
-- shared group (family_group_id = p_group_id). Filters out is_self=true
-- nodes (already claimed) and nodes that another member's
-- relative_id_in_tree already points to (defensive — covers any case where
-- is_self might lag).
--
-- Note: family_edges.from_id and to_id are TEXT (per migration
-- 20260201140000_family_edges.sql), while relatives.id is UUID. Casts are
-- explicit throughout.
-- ============================================================================

CREATE OR REPLACE FUNCTION get_candidate_relatives(
  p_group_id UUID,
  p_anchor_relative_id UUID,
  p_edge_path TEXT,
  p_parent_side TEXT,
  p_gender TEXT
)
RETURNS TABLE (
  id UUID,
  full_name TEXT,
  gender TEXT,
  date_of_birth TIMESTAMPTZ,
  parent_full_name TEXT,
  is_self BOOLEAN,
  is_already_claimed BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_target_parent_gender TEXT;
BEGIN
  -- 1. Verify caller is a member of the group (RLS bypass via SECURITY DEFINER).
  IF NOT EXISTS (
    SELECT 1 FROM family_group_members
    WHERE group_id = p_group_id AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Caller is not a member of this group';
  END IF;

  -- 2. Validate inputs.
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

  -- 3. Resolve parent_side to gender filter for upward traversal.
  v_target_parent_gender := CASE p_parent_side
    WHEN 'paternal' THEN 'male'
    WHEN 'maternal' THEN 'female'
    ELSE NULL
  END;

  -- 4. Branch on edge_path. Each branch returns one TABLE-shaped result.
  -- Common filter: r.is_self = false (exclude already-claimed nodes).

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
    -- Anchor's parent (filtered by side) → that parent's siblings (filtered by gender).
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
    -- Anchor's parent (side filter) → siblings → children (gender filter).
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
    -- Anchor's parent (side filter) → that parent's parent (gender filter).
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
    -- Anchor's children → their children (gender filter).
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
    -- Anchor's siblings → their children (gender filter).
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

GRANT EXECUTE ON FUNCTION get_candidate_relatives(UUID, UUID, TEXT, TEXT, TEXT) TO authenticated;

-- ============================================================================
-- Self-verification: function exists and is callable.
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.proname = 'get_candidate_relatives'
  ) THEN
    RAISE EXCEPTION 'get_candidate_relatives function missing';
  END IF;
END $$;
