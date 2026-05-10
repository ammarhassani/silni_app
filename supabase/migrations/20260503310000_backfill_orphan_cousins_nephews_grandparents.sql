-- Phase δ.fix.2 — backfill historical orphan rows for the three remaining
-- same-shape cases extracted from the aunt/uncle Phase δ.fix bug:
--
--   1. Nephew/Niece added BEFORE any sibling existed
--      (relationship_type IN ('nephew','niece') with no incoming parent_of)
--   2. Cousin added BEFORE any uncle/aunt existed
--      (relationship_type = 'cousin' with no incoming parent_of)
--   3. Grandparent added BEFORE the matching-side parent existed
--      (relationship_type IN ('grandfather','grandmother') with explicit
--      family_side, no parent_of from the grandparent to the matching
--      father/mother)
--
-- Each scenario produces a relative row with ZERO family_edges, falling
-- through to orphan-column placement at layout time. The forward bugs
-- are fixed in code (Phase δ.fix.2 sibling/uncle/parent-add branches now
-- backfill these on subsequent adds). This migration covers the historical
-- data that pre-dates that code change.
--
-- All three INSERTs are idempotent (NOT EXISTS guard + ON CONFLICT).
-- Re-running is a no-op.
--
-- Note on column types: family_edges.from_id and to_id are TEXT;
-- relatives.id is UUID. All cross-table id comparisons use ::text cast.
-- (Same trap as the aunt migration — see PHASE_DELTA_FIX_REPORT.md.)

-- ============================================================================
-- 1. Backfill orphan nephews / nieces — link to FIRST sibling (by created_at)
-- ============================================================================
-- Code-side pickFirst behavior: _findFirstSibling iterates existingRelatives
-- and returns the first brother/sister. created_at order is the most stable
-- proxy for that iteration order across query paths.

INSERT INTO public.family_edges (user_id, from_id, to_id, edge_type, family_group_id, created_at)
SELECT
  niece.user_id,
  sibling.id::text  AS from_id,
  niece.id::text    AS to_id,
  'parent_of'       AS edge_type,
  niece.family_group_id,
  now()             AS created_at
FROM public.relatives niece
JOIN LATERAL (
  SELECT s.id, s.family_group_id
  FROM public.relatives s
  WHERE s.user_id = niece.user_id
    AND s.relationship_type IN ('brother', 'sister')
    AND s.is_archived = false
    AND COALESCE(s.family_group_id::text, '') = COALESCE(niece.family_group_id::text, '')
  ORDER BY s.created_at ASC
  LIMIT 1
) sibling ON true
WHERE niece.relationship_type IN ('nephew', 'niece')
  AND niece.is_archived = false
  -- Only backfill nephews/nieces that have NO incoming parent_of edge
  -- (truly orphan; if any parent is already linked, leave it alone — the
  -- user may have manually re-parented).
  AND NOT EXISTS (
    SELECT 1
    FROM public.family_edges e
    WHERE e.edge_type = 'parent_of'
      AND e.user_id = niece.user_id
      AND COALESCE(e.family_group_id::text, '') = COALESCE(niece.family_group_id::text, '')
      AND e.to_id = niece.id::text
  )
ON CONFLICT (user_id, from_id, to_id, edge_type) DO NOTHING;

-- ============================================================================
-- 2. Backfill orphan cousins — link to FIRST uncle/aunt (by created_at)
-- ============================================================================

INSERT INTO public.family_edges (user_id, from_id, to_id, edge_type, family_group_id, created_at)
SELECT
  cousin.user_id,
  ua.id::text       AS from_id,
  cousin.id::text   AS to_id,
  'parent_of'       AS edge_type,
  cousin.family_group_id,
  now()             AS created_at
FROM public.relatives cousin
JOIN LATERAL (
  SELECT u.id, u.family_group_id
  FROM public.relatives u
  WHERE u.user_id = cousin.user_id
    AND u.relationship_type IN ('uncle', 'aunt')
    AND u.is_archived = false
    AND COALESCE(u.family_group_id::text, '') = COALESCE(cousin.family_group_id::text, '')
  ORDER BY u.created_at ASC
  LIMIT 1
) ua ON true
WHERE cousin.relationship_type = 'cousin'
  AND cousin.is_archived = false
  AND NOT EXISTS (
    SELECT 1
    FROM public.family_edges e
    WHERE e.edge_type = 'parent_of'
      AND e.user_id = cousin.user_id
      AND COALESCE(e.family_group_id::text, '') = COALESCE(cousin.family_group_id::text, '')
      AND e.to_id = cousin.id::text
  )
ON CONFLICT (user_id, from_id, to_id, edge_type) DO NOTHING;

-- ============================================================================
-- 3. Backfill orphan grandparents — link to matching-side parent
-- ============================================================================
-- Only handles grandparents with explicit family_side. NULL-side
-- grandparents are left alone (we can't disambiguate paternal vs maternal
-- without the side hint).

INSERT INTO public.family_edges (user_id, from_id, to_id, edge_type, family_group_id, created_at)
SELECT
  gp.user_id,
  gp.id::text     AS from_id,
  parent.id::text AS to_id,
  'parent_of'     AS edge_type,
  gp.family_group_id,
  now()           AS created_at
FROM public.relatives gp
JOIN public.relatives parent
  ON parent.user_id = gp.user_id
  AND (
    (gp.family_side = 'paternal' AND parent.relationship_type = 'father')
    OR
    (gp.family_side = 'maternal' AND parent.relationship_type = 'mother')
  )
  AND COALESCE(parent.family_group_id::text, '') = COALESCE(gp.family_group_id::text, '')
WHERE gp.relationship_type IN ('grandfather', 'grandmother')
  AND gp.is_archived = false
  AND parent.is_archived = false
  AND NOT EXISTS (
    SELECT 1
    FROM public.family_edges e
    WHERE e.edge_type = 'parent_of'
      AND e.user_id = gp.user_id
      AND COALESCE(e.family_group_id::text, '') = COALESCE(gp.family_group_id::text, '')
      AND e.from_id = gp.id::text
      AND e.to_id = parent.id::text
  )
ON CONFLICT (user_id, from_id, to_id, edge_type) DO NOTHING;

-- ============================================================================
-- Self-verification
-- ============================================================================
-- For each of the three cases, count rows that SHOULD have been linked
-- (matching anchor exists, no edge present). Expected: 0 across the board.
-- If any of these is non-zero post-INSERT, the JOIN logic missed
-- something and the migration must be reviewed before next deploy.

DO $verify$
DECLARE
  unfixable_nieces        int;
  unfixable_cousins       int;
  unfixable_grandparents  int;
BEGIN
  -- Nephews/nieces: matching sibling exists, but no incoming parent_of
  SELECT count(*) INTO unfixable_nieces
  FROM public.relatives niece
  WHERE niece.relationship_type IN ('nephew', 'niece')
    AND niece.is_archived = false
    AND EXISTS (
      SELECT 1 FROM public.relatives s
      WHERE s.user_id = niece.user_id
        AND s.relationship_type IN ('brother', 'sister')
        AND s.is_archived = false
        AND COALESCE(s.family_group_id::text, '') = COALESCE(niece.family_group_id::text, '')
    )
    AND NOT EXISTS (
      SELECT 1 FROM public.family_edges e
      WHERE e.edge_type = 'parent_of'
        AND e.user_id = niece.user_id
        AND COALESCE(e.family_group_id::text, '') = COALESCE(niece.family_group_id::text, '')
        AND e.to_id = niece.id::text
    );

  -- Cousins: matching uncle/aunt exists, but no incoming parent_of
  SELECT count(*) INTO unfixable_cousins
  FROM public.relatives cousin
  WHERE cousin.relationship_type = 'cousin'
    AND cousin.is_archived = false
    AND EXISTS (
      SELECT 1 FROM public.relatives u
      WHERE u.user_id = cousin.user_id
        AND u.relationship_type IN ('uncle', 'aunt')
        AND u.is_archived = false
        AND COALESCE(u.family_group_id::text, '') = COALESCE(cousin.family_group_id::text, '')
    )
    AND NOT EXISTS (
      SELECT 1 FROM public.family_edges e
      WHERE e.edge_type = 'parent_of'
        AND e.user_id = cousin.user_id
        AND COALESCE(e.family_group_id::text, '') = COALESCE(cousin.family_group_id::text, '')
        AND e.to_id = cousin.id::text
    );

  -- Grandparents: matching-side parent exists, but no parent_of from
  -- grandparent to that parent
  SELECT count(*) INTO unfixable_grandparents
  FROM public.relatives gp
  JOIN public.relatives parent
    ON parent.user_id = gp.user_id
    AND (
      (gp.family_side = 'paternal' AND parent.relationship_type = 'father')
      OR
      (gp.family_side = 'maternal' AND parent.relationship_type = 'mother')
    )
    AND COALESCE(parent.family_group_id::text, '') = COALESCE(gp.family_group_id::text, '')
  WHERE gp.relationship_type IN ('grandfather', 'grandmother')
    AND gp.is_archived = false
    AND parent.is_archived = false
    AND NOT EXISTS (
      SELECT 1 FROM public.family_edges e
      WHERE e.edge_type = 'parent_of'
        AND e.user_id = gp.user_id
        AND COALESCE(e.family_group_id::text, '') = COALESCE(gp.family_group_id::text, '')
        AND e.from_id = gp.id::text
        AND e.to_id = parent.id::text
    );

  IF unfixable_nieces > 0 OR unfixable_cousins > 0 OR unfixable_grandparents > 0 THEN
    RAISE EXCEPTION 'Phase δ.fix.2 backfill incomplete: nieces=%, cousins=%, grandparents=%',
      unfixable_nieces, unfixable_cousins, unfixable_grandparents;
  END IF;
END
$verify$;
