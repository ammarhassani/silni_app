-- ============================================================================
-- Add partial unique index for shared family edges
-- ============================================================================
-- The existing unique constraint (user_id, from_id, to_id, edge_type) works
-- for personal edges but allows duplicate shared edges within a group when
-- different users insert the same structural edge.
--
-- This migration adds a partial unique index on
-- (family_group_id, from_id, to_id, edge_type) for shared edges,
-- preventing duplicates within a group regardless of which user created them.
-- ============================================================================

-- 1. Deduplicate any existing shared edges (keep the oldest per group)
WITH duplicates AS (
  SELECT id,
    ROW_NUMBER() OVER (
      PARTITION BY family_group_id, from_id, to_id, edge_type
      ORDER BY created_at ASC
    ) AS rn
  FROM family_edges
  WHERE family_group_id IS NOT NULL
)
DELETE FROM family_edges
WHERE id IN (SELECT id FROM duplicates WHERE rn > 1);

-- 2. Add partial unique index for shared edges
CREATE UNIQUE INDEX IF NOT EXISTS idx_family_edges_group_unique
ON family_edges (family_group_id, from_id, to_id, edge_type)
WHERE family_group_id IS NOT NULL;
