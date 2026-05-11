-- 20260511100000_create_node_claim_accepts_invite_code.sql
-- Allow create_node_claim() to authorize via invite_code instead of membership.
-- Persists the invite_code on the row so audit trail is preserved.
--
-- Context: prior to this migration, joining a family group via invite link
-- inserted family_group_members immediately, before identity verification.
-- This migration moves auth for create_node_claim off of membership and onto
-- a presented invite_code. Membership is only granted later, when an admin
-- approves the claim.
--
-- We also drop both prior overloads (11-arg and 12-arg) so the function has
-- a single canonical signature (13 args). RLS is locked so PostgREST-direct
-- inserts are impossible — the RPC is the only path.

BEGIN;

-- 1. Add invite_code column (nullable; legacy claims won't have it).
ALTER TABLE public.node_claims
  ADD COLUMN IF NOT EXISTS invite_code TEXT;

COMMENT ON COLUMN public.node_claims.invite_code IS
  'Invite code used to submit this claim. Stored for audit; auth is performed at insert-time only.';

-- 2. Drop the prior overloads so the new 13-arg version is the only signature.
--    Both legacy signatures exist concurrently in the live DB as of 2026-05-10.
DROP FUNCTION IF EXISTS public.create_node_claim(
  UUID, UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT, INT, TEXT, TEXT
);
DROP FUNCTION IF EXISTS public.create_node_claim(
  UUID, UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT, INT, TEXT, TEXT, TEXT
);

-- 3. Recreate create_node_claim with p_invite_code, falling back to membership.
--    Either auth path is acceptable; only one needs to succeed.
CREATE OR REPLACE FUNCTION public.create_node_claim(
  p_group_id UUID,
  p_claimed_relative_id UUID,
  p_anchor_relative_id UUID,
  p_edge_path TEXT,
  p_parent_side TEXT,
  p_gender TEXT,
  p_proposed_full_name TEXT DEFAULT NULL,
  p_proposed_gender TEXT DEFAULT NULL,
  p_proposed_birth_year INT DEFAULT NULL,
  p_proposed_city TEXT DEFAULT NULL,
  p_proposed_photo_url TEXT DEFAULT NULL,
  p_proposed_phone_number TEXT DEFAULT NULL,
  p_invite_code TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_is_member BOOLEAN;
  v_code_valid BOOLEAN;
  v_normalized_phone TEXT;
  v_claim_id UUID;
  v_claim JSONB;
BEGIN
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- AUTH: caller is a member OR presented a valid invite code for this group.
  SELECT EXISTS(
    SELECT 1 FROM family_group_members
    WHERE group_id = p_group_id AND user_id = v_caller_id
  ) INTO v_is_member;

  IF NOT v_is_member THEN
    IF p_invite_code IS NULL THEN
      RAISE EXCEPTION 'يجب أن تكون عضواً في المجموعة أو تقدم رمز دعوة صالح';
    END IF;
    SELECT EXISTS(
      SELECT 1 FROM family_groups
      WHERE id = p_group_id AND invite_code = p_invite_code
    ) INTO v_code_valid;
    IF NOT v_code_valid THEN
      RAISE EXCEPTION 'رمز الدعوة غير صالح';
    END IF;
  END IF;

  -- Validation: prevent duplicate pending claims by same user in same group.
  IF EXISTS (
    SELECT 1 FROM node_claims
    WHERE group_id = p_group_id
      AND claimant_user_id = v_caller_id
      AND status = 'pending'
  ) THEN
    RAISE EXCEPTION 'لديك طلب معلق بالفعل في هذه المجموعة';
  END IF;

  -- Validation: claimed_relative XOR proposed_full_name.
  IF (p_claimed_relative_id IS NULL) = (p_proposed_full_name IS NULL) THEN
    RAISE EXCEPTION 'يجب تقديم relative موجود أو اسم لإضافة جديدة، وليس كلاهما';
  END IF;

  -- Validation: anchor must belong to the group.
  IF NOT EXISTS (
    SELECT 1 FROM relatives
    WHERE id = p_anchor_relative_id AND family_group_id = p_group_id
  ) THEN
    RAISE EXCEPTION 'Anchor relative not in group';
  END IF;

  -- Validation: edge_path value.
  IF p_edge_path NOT IN (
    'parent','child','spouse','sibling',
    'uncle_aunt','grandparent','grandchild','cousin','nephew_niece'
  ) THEN
    RAISE EXCEPTION 'Invalid edge_path: %', p_edge_path;
  END IF;

  -- Normalize phone if provided (preserves behavior introduced in
  -- 20260510114720_node_claims_add_phone).
  IF p_proposed_phone_number IS NOT NULL AND trim(p_proposed_phone_number) != '' THEN
    v_normalized_phone := regexp_replace(trim(p_proposed_phone_number), '\s+', '', 'g');
    IF left(v_normalized_phone, 1) != '+' THEN
      v_normalized_phone := '+' || v_normalized_phone;
    END IF;
    IF length(v_normalized_phone) < 8 OR length(v_normalized_phone) > 16 THEN
      RAISE EXCEPTION 'رقم الهاتف غير صالح';
    END IF;
  END IF;

  INSERT INTO node_claims (
    group_id, claimant_user_id, claimed_relative_id, declared_anchor_relative_id,
    declared_edge_path, declared_parent_side, declared_gender,
    proposed_full_name, proposed_gender, proposed_birth_year, proposed_city,
    proposed_photo_url, proposed_phone_number, invite_code, status
  ) VALUES (
    p_group_id, v_caller_id, p_claimed_relative_id, p_anchor_relative_id,
    p_edge_path, p_parent_side, p_gender,
    NULLIF(trim(p_proposed_full_name), ''), p_proposed_gender, p_proposed_birth_year,
    NULLIF(trim(p_proposed_city), ''), NULLIF(trim(p_proposed_photo_url), ''),
    v_normalized_phone, p_invite_code, 'pending'
  )
  RETURNING id INTO v_claim_id;

  -- Return the freshly-inserted claim (matches get_node_claim_by_id shape).
  SELECT to_jsonb(nc.*) INTO v_claim FROM node_claims nc WHERE id = v_claim_id;
  RETURN v_claim;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_node_claim(
  UUID, UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT, INT, TEXT, TEXT, TEXT, TEXT
) TO authenticated;

-- 4. Lock down RLS so direct-insert via PostgREST is impossible.
--    The RPC (SECURITY DEFINER) is now the only path to create a claim.
DROP POLICY IF EXISTS node_claims_insert_claimant ON public.node_claims;
CREATE POLICY node_claims_insert_claimant
  ON public.node_claims FOR INSERT
  WITH CHECK (false);

COMMIT;
