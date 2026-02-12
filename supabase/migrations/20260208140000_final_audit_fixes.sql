-- ============================================================================
-- Final Audit Fixes — Part 1: create_group_atomic
-- ============================================================================
CREATE OR REPLACE FUNCTION create_group_atomic(p_name TEXT, p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_group RECORD;
BEGIN
  -- SECURITY: Verify caller identity
  IF p_user_id != auth.uid() THEN
    RAISE EXCEPTION 'Cannot create group for another user';
  END IF;

  -- Validate input
  IF p_name IS NULL OR trim(p_name) = '' THEN
    RAISE EXCEPTION 'Group name cannot be empty';
  END IF;
  IF length(trim(p_name)) > 100 THEN
    RAISE EXCEPTION 'Group name too long (max 100 characters)';
  END IF;

  -- Create group
  INSERT INTO family_groups (name, created_by)
  VALUES (trim(p_name), p_user_id)
  RETURNING * INTO v_group;

  -- Add creator as admin (within same transaction)
  INSERT INTO family_group_members (group_id, user_id, role)
  VALUES (v_group.id, p_user_id, 'admin');

  RETURN to_jsonb(v_group);
END;
$$;
