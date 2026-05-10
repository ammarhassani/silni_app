-- ============================================================================
-- Node Claims: Joiner-initiated identity-claim records for family tree nodes
-- ============================================================================
-- Counterpart to node_invitations (which is admin → invitee, phone-keyed).
-- node_claims is joiner → admin, role-based: a public-link joiner declares
-- their relationship to an anchor person in the tree, optionally targets an
-- existing tree node (claimed_relative_id), and waits for admin approval.
--
-- The "add me to the tree" path uses claimed_relative_id IS NULL with the
-- proposed_* fields populated from the joiner's form.
--
-- Approval is via the approve_node_claim RPC (separate migration), which
-- delegates the actual node-claiming mechanic to the existing claim_tree_node
-- RPC (20260209100000_claim_tree_node_rpc.sql) — no duplicate logic.
--
-- See docs/plans/2026-05-08-family-sharing-identity-claim-design.md
-- ============================================================================

-- ============================================================================
-- 1. Create node_claims table
-- ============================================================================

CREATE TABLE node_claims (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
  claimant_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- The node the joiner is claiming. NULL means "I'm not in the tree, add me".
  claimed_relative_id UUID REFERENCES relatives(id) ON DELETE CASCADE,

  -- Declared relationship (matches admin_relationship_labels schema:
  -- edge_path + parent_side + gender).
  declared_anchor_relative_id UUID NOT NULL REFERENCES relatives(id) ON DELETE CASCADE,
  declared_edge_path TEXT NOT NULL,
  declared_parent_side TEXT,
  declared_gender TEXT NOT NULL,

  -- "Add me" form fields (NULL when claiming an existing node).
  proposed_full_name TEXT,
  proposed_gender TEXT,
  proposed_birth_year INT,
  proposed_city TEXT,
  proposed_photo_url TEXT,

  status TEXT NOT NULL DEFAULT 'pending',
  rejection_reason TEXT,
  decided_by UUID REFERENCES auth.users(id),
  decided_at TIMESTAMPTZ,
  snoozed_until TIMESTAMPTZ,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- 2. CHECK constraints
-- ============================================================================

ALTER TABLE node_claims
  ADD CONSTRAINT node_claims_status_check
    CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled'));

ALTER TABLE node_claims
  ADD CONSTRAINT node_claims_declared_edge_path_check
    CHECK (declared_edge_path IN (
      'parent', 'child', 'spouse', 'sibling',
      'grandparent', 'grandchild',
      'uncle_aunt', 'nephew_niece', 'cousin'
    ));

ALTER TABLE node_claims
  ADD CONSTRAINT node_claims_declared_parent_side_check
    CHECK (declared_parent_side IS NULL OR declared_parent_side IN ('paternal', 'maternal'));

ALTER TABLE node_claims
  ADD CONSTRAINT node_claims_declared_gender_check
    CHECK (declared_gender IN ('male', 'female'));

ALTER TABLE node_claims
  ADD CONSTRAINT node_claims_proposed_gender_check
    CHECK (proposed_gender IS NULL OR proposed_gender IN ('male', 'female'));

ALTER TABLE node_claims
  ADD CONSTRAINT node_claims_proposed_birth_year_check
    CHECK (proposed_birth_year IS NULL OR (proposed_birth_year >= 1900 AND proposed_birth_year <= 2100));

-- Either claim an existing node OR propose a new one — never both, never neither.
ALTER TABLE node_claims
  ADD CONSTRAINT node_claims_target_consistency_check
    CHECK (
      (claimed_relative_id IS NOT NULL AND proposed_full_name IS NULL)
      OR (claimed_relative_id IS NULL AND proposed_full_name IS NOT NULL)
    );

-- ============================================================================
-- 3. Indexes
-- ============================================================================

-- One pending claim per joiner per group (enforces user can't double-claim).
CREATE UNIQUE INDEX idx_node_claims_one_pending_per_user_per_group
  ON node_claims (group_id, claimant_user_id)
  WHERE status = 'pending';

-- Admin's pending-claim queue for a group.
CREATE INDEX idx_node_claims_group_pending
  ON node_claims (group_id, status)
  WHERE status = 'pending';

-- Joiner's own claims across groups.
CREATE INDEX idx_node_claims_claimant_status
  ON node_claims (claimant_user_id, status);

-- Snooze handling: surface claims whose snooze has expired.
CREATE INDEX idx_node_claims_snoozed_until
  ON node_claims (snoozed_until)
  WHERE snoozed_until IS NOT NULL AND status = 'pending';

-- Decided claims for audit / joiner-side history.
CREATE INDEX idx_node_claims_decided
  ON node_claims (decided_at DESC)
  WHERE decided_at IS NOT NULL;

-- ============================================================================
-- 4. Row-Level Security
-- ============================================================================

ALTER TABLE node_claims ENABLE ROW LEVEL SECURITY;

-- Claimant can see their own claims (any status).
CREATE POLICY node_claims_select_claimant
  ON node_claims FOR SELECT
  USING (claimant_user_id = auth.uid());

-- Group admins can see all claims for their groups (for the queue UI).
CREATE POLICY node_claims_select_admin
  ON node_claims FOR SELECT
  USING (group_id IN (SELECT auth_user_admin_group_ids()));

-- Joiner can insert their own claim — must be a member of the group.
-- (The claimant_user_id = auth.uid() check ensures the user can only
-- create claims under their own identity. Group membership is enforced
-- via the auth_user_group_ids() helper.)
CREATE POLICY node_claims_insert_claimant
  ON node_claims FOR INSERT
  WITH CHECK (
    claimant_user_id = auth.uid()
    AND group_id IN (SELECT auth_user_group_ids())
  );

-- All UPDATEs go through SECURITY DEFINER RPCs (approve / reject / cancel / snooze).
-- Direct UPDATE is denied for safety — RPCs do the validation.
CREATE POLICY node_claims_update_deny
  ON node_claims FOR UPDATE
  USING (false);

-- Group admins can delete decided claims (cleanup / privacy).
CREATE POLICY node_claims_delete_admin
  ON node_claims FOR DELETE
  USING (
    status IN ('approved', 'rejected', 'cancelled')
    AND group_id IN (SELECT auth_user_admin_group_ids())
  );

-- Claimants can delete their own decided claims (privacy / right-to-erasure).
CREATE POLICY node_claims_delete_claimant
  ON node_claims FOR DELETE
  USING (
    claimant_user_id = auth.uid()
    AND status IN ('approved', 'rejected', 'cancelled')
  );

-- ============================================================================
-- 5. Self-verification
-- ============================================================================

DO $$
DECLARE
  v_count INTEGER;
BEGIN
  -- Table exists with RLS.
  IF NOT EXISTS (SELECT 1 FROM pg_class WHERE oid = 'public.node_claims'::regclass AND relrowsecurity) THEN
    RAISE EXCEPTION 'node_claims missing or RLS not enabled';
  END IF;

  -- Expected indexes.
  SELECT COUNT(*) INTO v_count FROM pg_indexes
  WHERE schemaname = 'public' AND tablename = 'node_claims';
  IF v_count < 5 THEN
    RAISE EXCEPTION 'node_claims expected at least 5 indexes (incl. PK), found %', v_count;
  END IF;

  -- Expected policy count: 5 (2 SELECT + 1 INSERT + 1 UPDATE-deny + 2 DELETE).
  SELECT COUNT(*) INTO v_count FROM pg_policies
  WHERE schemaname = 'public' AND tablename = 'node_claims';
  IF v_count <> 6 THEN
    RAISE EXCEPTION 'node_claims expected 6 policies, found %', v_count;
  END IF;

  -- CHECK constraints.
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'node_claims_target_consistency_check' AND conrelid = 'public.node_claims'::regclass) THEN
    RAISE EXCEPTION 'node_claims_target_consistency_check missing';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'node_claims_declared_edge_path_check' AND conrelid = 'public.node_claims'::regclass) THEN
    RAISE EXCEPTION 'node_claims_declared_edge_path_check missing';
  END IF;
END $$;
