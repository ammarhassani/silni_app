-- Fix rotate_invite_code: gen_random_bytes requires pgcrypto extension.
-- Use gen_random_uuid() instead which is always available in PostgreSQL 13+.

CREATE OR REPLACE FUNCTION rotate_invite_code(target_group_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  new_code TEXT;
BEGIN
  -- Verify caller is admin of this group
  IF NOT EXISTS (
    SELECT 1 FROM family_group_members
    WHERE group_id = target_group_id
      AND user_id = auth.uid()
      AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only admins can rotate invite codes';
  END IF;

  -- Use gen_random_uuid() (always available) instead of gen_random_bytes (needs pgcrypto)
  new_code := replace(gen_random_uuid()::text, '-', '');
  new_code := substr(new_code, 1, 12);

  UPDATE family_groups
  SET invite_code = new_code, updated_at = now()
  WHERE id = target_group_id;

  RETURN new_code;
END;
$$;
