-- 20260511140000_remove_auto_insert_in_join_rpc.sql
-- join_group_by_invite_code becomes a pure lookup — no side effects.
-- The client navigates the joiner directly into the wizard instead.
-- Membership is created exclusively by approve_node_claim.

CREATE OR REPLACE FUNCTION public.join_group_by_invite_code(
  code TEXT,
  rid UUID DEFAULT NULL  -- legacy param, ignored
)
RETURNS SETOF family_groups
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  target_group family_groups%ROWTYPE;
BEGIN
  SELECT * INTO target_group FROM family_groups WHERE invite_code = code;
  IF target_group.id IS NULL THEN
    RAISE EXCEPTION 'رمز الدعوة غير صالح';
  END IF;
  RETURN NEXT target_group;
END;
$$;

COMMENT ON FUNCTION public.join_group_by_invite_code(TEXT, UUID) IS
  'DEPRECATED side-effects (membership insert) removed 2026-05-11. '
  'Equivalent to lookup_group_by_invite_code. Membership is created '
  'only via approve_node_claim. Kept for older client compatibility.';

-- Re-grant explicitly for fresh-DB replay safety. CREATE OR REPLACE
-- preserves grants on an existing function, but a fresh replay needs these.
GRANT EXECUTE ON FUNCTION public.join_group_by_invite_code(TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.join_group_by_invite_code(TEXT, UUID) TO anon;
GRANT EXECUTE ON FUNCTION public.join_group_by_invite_code(TEXT, UUID) TO service_role;
