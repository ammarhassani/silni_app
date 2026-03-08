-- ============================================================================
-- Node Invitations: Phone-number-based invitations for family tree nodes
-- ============================================================================
-- Stores invitations keyed by phone number for specific family tree nodes.
-- When a group admin invites a relative (who has a phone number), a record
-- is created here. When the invitee registers/logs in with a matching phone,
-- they see the invitation.
-- ============================================================================

-- ============================================================================
-- 1. Create node_invitations table
-- ============================================================================

CREATE TABLE node_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
  relative_id UUID NOT NULL REFERENCES relatives(id) ON DELETE CASCADE,
  phone_number TEXT NOT NULL,
  invited_by UUID NOT NULL REFERENCES auth.users(id),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'cancelled')),
  accepted_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  accepted_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ
);

-- ============================================================================
-- 2. Indexes
-- ============================================================================

-- Fast lookup on login: find pending invitations for a phone number
CREATE INDEX idx_node_invitations_phone_status
  ON node_invitations (phone_number, status)
  WHERE status = 'pending';

-- One pending invitation per node in a group
CREATE UNIQUE INDEX idx_node_invitations_unique_pending
  ON node_invitations (group_id, relative_id)
  WHERE status = 'pending';

-- Admin's invitation list for a group
CREATE INDEX idx_node_invitations_group
  ON node_invitations (group_id, status);

-- Look up invitations accepted by a specific user
CREATE INDEX idx_node_invitations_accepted_by
  ON node_invitations (accepted_by)
  WHERE accepted_by IS NOT NULL;

-- ============================================================================
-- 3. Row-Level Security
-- ============================================================================

ALTER TABLE node_invitations ENABLE ROW LEVEL SECURITY;

-- Group members can view invitations in their groups
CREATE POLICY node_invitations_select_admin
  ON node_invitations FOR SELECT
  USING (
    group_id IN (SELECT auth_user_group_ids())
  );

-- Invitees can see their own pending invitations by matching phone number
CREATE POLICY node_invitations_select_invitee
  ON node_invitations FOR SELECT
  USING (
    status = 'pending'
    AND phone_number = (SELECT phone FROM auth.users WHERE id = auth.uid())
  );

-- Group admins can create invitations (must set invited_by to themselves)
CREATE POLICY node_invitations_insert_admin
  ON node_invitations FOR INSERT
  WITH CHECK (
    group_id IN (SELECT auth_user_admin_group_ids())
    AND invited_by = auth.uid()
  );

-- All updates go through RPCs — deny direct updates
CREATE POLICY node_invitations_update_deny
  ON node_invitations FOR UPDATE
  USING (false);

-- Group admins can delete cancelled invitations only
CREATE POLICY node_invitations_delete_admin
  ON node_invitations FOR DELETE
  USING (
    status = 'cancelled'
    AND group_id IN (SELECT auth_user_admin_group_ids())
  );
