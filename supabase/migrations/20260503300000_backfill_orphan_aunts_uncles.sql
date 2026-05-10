-- Phase δ.fix — backfill orphan aunts/uncles that have missing family_edges.
--
-- إصلاح صفوف الأعمام/العمّات/الأخوال/الخالات التي أُضيفت قبل وجود الوالد
-- المقابل في الشجرة، فلم تُنشأ لها أي حواف. هذه الترقيع يُنشئ حافة
-- siblingOf الأساسية الرابطة بين العم/الخالة والوالد المناسب لجهتها.
-- _enrichSiblingEdges في وقت العرض يكمل بقية الحواف من خلال السلسلة.
--
-- The bug: `inferEdges` for relationship_type='aunt'/'uncle' calls
-- `_findParentForSide`, which returns NULL when the relevant parent
-- (father for paternal, mother for maternal) doesn't exist yet at the
-- time the aunt/uncle is added. With NULL anchor, the function returns
-- an empty edge list — the aunt/uncle is persisted as a relatives row
-- with ZERO family_edges. Layout then falls through to orphan
-- placement, putting the aunt in the wrong column.
--
-- This migration backfills the missing `sibling_of` edges retroactively.
-- Once present, the layout's `_enrichSiblingEdges` chains them at view
-- time to the parent_of edges from grandparents, so display is correct.
--
-- Forward bugs (new orphan creates) are prevented by the code-side fix in
-- lib/features/family_tree/services/family_graph_service.dart (the
-- `father`/`mother`/`grandfather`/`grandmother` branches now backfill
-- aunts/uncles when those relationship types are added).
--
-- Idempotent: re-running is a no-op (NOT EXISTS guard + ON CONFLICT).

-- Note on column types: family_edges.from_id and to_id are TEXT (not UUID).
-- relatives.id is UUID. All cross-table id comparisons must explicitly cast
-- the UUID to text (or use ::uuid on the text side, but UUID→text is safer
-- since family_edges has no GUARANTEE every value is a parseable UUID, even
-- though current code only writes UUIDs).

INSERT INTO public.family_edges (user_id, from_id, to_id, edge_type, family_group_id, created_at)
SELECT
  aunt.user_id,
  aunt.id::text     AS from_id,
  parent.id::text   AS to_id,
  'sibling_of'      AS edge_type,
  aunt.family_group_id,
  now()             AS created_at
FROM public.relatives aunt
JOIN public.relatives parent
  ON parent.user_id = aunt.user_id
  AND (
    (aunt.family_side = 'paternal' AND parent.relationship_type = 'father')
    OR
    (aunt.family_side = 'maternal' AND parent.relationship_type = 'mother')
  )
  -- match the same scope (personal vs shared); NULL group_id matches NULL
  AND COALESCE(parent.family_group_id::text, '') = COALESCE(aunt.family_group_id::text, '')
WHERE aunt.relationship_type IN ('aunt', 'uncle')
  AND aunt.is_archived = false
  AND parent.is_archived = false
  AND NOT EXISTS (
    SELECT 1
    FROM public.family_edges e
    WHERE e.edge_type = 'sibling_of'
      AND e.user_id = aunt.user_id
      AND COALESCE(e.family_group_id::text, '') = COALESCE(aunt.family_group_id::text, '')
      AND (
        (e.from_id = aunt.id::text   AND e.to_id = parent.id::text)
        OR
        (e.from_id = parent.id::text AND e.to_id = aunt.id::text)
      )
  )
ON CONFLICT (user_id, from_id, to_id, edge_type) DO NOTHING;

-- Self-verification: count how many aunt/uncle relatives still have zero
-- sibling_of edges to a same-side parent. The expected value is 0 in any
-- account that also has the matching parent. If the aunt's parent doesn't
-- exist yet, the migration cannot link her — that's correct, future
-- inferEdges father/mother branch will catch it when the parent is added.
DO $verify$
DECLARE
  unfixable_count int;
BEGIN
  -- Count aunts/uncles where matching parent exists but no sibling edge
  SELECT count(*) INTO unfixable_count
  FROM public.relatives aunt
  JOIN public.relatives parent
    ON parent.user_id = aunt.user_id
    AND (
      (aunt.family_side = 'paternal' AND parent.relationship_type = 'father')
      OR
      (aunt.family_side = 'maternal' AND parent.relationship_type = 'mother')
    )
    AND COALESCE(parent.family_group_id::text, '') = COALESCE(aunt.family_group_id::text, '')
  WHERE aunt.relationship_type IN ('aunt', 'uncle')
    AND aunt.is_archived = false
    AND parent.is_archived = false
    AND NOT EXISTS (
      SELECT 1
      FROM public.family_edges e
      WHERE e.edge_type = 'sibling_of'
        AND e.user_id = aunt.user_id
        AND COALESCE(e.family_group_id::text, '') = COALESCE(aunt.family_group_id::text, '')
        AND (
          (e.from_id = aunt.id::text   AND e.to_id = parent.id::text)
          OR
          (e.from_id = parent.id::text AND e.to_id = aunt.id::text)
        )
    );

  IF unfixable_count > 0 THEN
    RAISE EXCEPTION 'backfill failed: % aunt/uncle rows still have a matching parent but no sibling_of edge', unfixable_count;
  END IF;
END
$verify$;
