-- ============================================================================
-- Fix: Create missing self-nodes for group admins
-- ============================================================================
-- Some groups were created without a self-node for the admin (due to a partial
-- failure in initializeSharedTree). This migration creates self-node relatives
-- for admins who are missing one and links them via relative_id_in_tree.
--
-- Shared edges will be generated automatically by the app's verifySharedEdges()
-- when any group member next opens the tree.
-- ============================================================================

DO $$
DECLARE
  admin_row RECORD;
  new_node_id UUID;
  admin_name TEXT;
  admin_gender TEXT;
  admin_avatar TEXT;
BEGIN
  FOR admin_row IN
    SELECT m.user_id, m.group_id, u.raw_user_meta_data
    FROM family_group_members m
    JOIN auth.users u ON u.id = m.user_id
    WHERE m.role = 'admin'
      AND m.relative_id_in_tree IS NULL
  LOOP
    -- Extract display name from user metadata
    admin_name := COALESCE(
      admin_row.raw_user_meta_data->>'full_name',
      admin_row.raw_user_meta_data->>'display_name',
      'أنا'
    );

    -- Simple gender heuristic (Arabic names ending in ة or ى)
    IF admin_name LIKE '%ة' OR admin_name LIKE '%ى' THEN
      admin_gender := 'female';
      admin_avatar := 'adult_woman';
    ELSE
      admin_gender := 'male';
      admin_avatar := 'adult_man';
    END IF;

    -- Create self-node
    new_node_id := gen_random_uuid();
    INSERT INTO relatives (
      id, user_id, full_name, relationship_type, gender, priority,
      avatar_type, is_self, family_group_id, added_by
    ) VALUES (
      new_node_id, admin_row.user_id, admin_name, 'other',
      admin_gender, 1, admin_avatar, true,
      admin_row.group_id, admin_row.user_id
    );

    -- Link admin to their self-node
    UPDATE family_group_members
    SET relative_id_in_tree = new_node_id
    WHERE group_id = admin_row.group_id
      AND user_id = admin_row.user_id;

    RAISE NOTICE 'Created self-node % for admin % in group %',
      new_node_id, admin_row.user_id, admin_row.group_id;
  END LOOP;
END $$;
