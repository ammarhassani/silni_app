-- ============================================================================
-- Fix: Mark claimed nodes as is_self = true
-- ============================================================================
-- When a member joins via an invite link with `rid`, their node should be
-- marked as is_self = true. Earlier code didn't do this, leaving some
-- members' nodes with is_self = false. This causes them to appear in their
-- own relatives list (e.g., Amro seeing himself as "brother").
-- ============================================================================

UPDATE relatives r
SET is_self = true
FROM family_group_members m
WHERE m.relative_id_in_tree = r.id
  AND r.is_self = false;
