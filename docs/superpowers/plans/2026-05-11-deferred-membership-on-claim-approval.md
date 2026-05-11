# Deferred Membership on Claim Approval — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stop inserting a joiner into `family_group_members` the moment they tap an invite link. Defer the INSERT until the admin approves their identity-claim, so a fresh joiner cannot see or "own" any of the admin's relatives until they've been positively identified in the tree.

**Architecture:** Replace the "insert-then-claim" flow with an "invite-code-authed claim, then atomic insert on approval" flow. The invite code becomes a one-time auth token that lets the joiner bootstrap the wizard, fetch candidates, and submit a claim — all without holding a membership row. `approve_node_claim` becomes the single place that creates the membership and links the relative, atomically. RLS is **unchanged** for `family_group_members`, `relatives`, and `family_edges`: non-members already correctly see nothing. We only adjust `create_node_claim` and `get_candidate_relatives` to accept `p_invite_code` as a fallback auth path.

**Tech Stack:** PostgreSQL (SECURITY DEFINER RPCs, RLS), Flutter (Riverpod, go_router), Supabase realtime.

**Design notes worth preserving:**

- **Why not a `status='pending'` column on `family_group_members`?** Every group-scoped RLS policy would need an extra `AND status='active'` check (`relatives`, `family_edges`, `family_group_members` itself, `auth_user_group_ids()`). One miss = data leak. Deferring the INSERT keeps the data model honest: "you have a row → you're a member."
- **The invite code IS the auth token** for pre-member RPCs. It already gates group lookup (`lookup_group_by_invite_code`). We extend the same pattern to `create_node_claim` and `get_candidate_relatives`.
- **Backfill is destructive.** Existing unlinked memberships (`relative_id_in_tree IS NULL`) are deleted, because they represent the exact bug we're fixing — there is no clean "promotion" path that doesn't ask the user to redo the wizard anyway. Pre-launch, the only affected user is `testprodjoiner` on testprod's group.

---

## File Structure

**Migrations to create (`supabase/migrations/`):**
- `20260511100000_create_node_claim_accepts_invite_code.sql` — relax membership requirement in `create_node_claim`, store invite_code on the claim row
- `20260511110000_get_candidate_relatives_accepts_invite_code.sql` — add `p_invite_code` to `get_candidate_relatives`
- `20260511120000_get_group_info_for_invite.sql` — new RPC for wizard bootstrap (admin name, group name, tree members, anchor candidates) without requiring membership
- `20260511130000_approve_claim_inserts_membership.sql` — `approve_node_claim` atomically INSERTs `family_group_members` when row is missing
- `20260511140000_remove_auto_insert_in_join_rpc.sql` — `join_group_by_invite_code` no longer inserts membership; renamed conceptually to "lookup-only"
- `20260511150000_backfill_remove_unlinked_memberships.sql` — DELETE existing `family_group_members` rows where `relative_id_in_tree IS NULL`
- `20260511160000_seed_claim_notification_templates.sql` — seed `claim_pending`, `claim_approved`, `claim_rejected` templates

**Dart files to create:**
- `lib/features/family_groups/screens/claim_pending_review_screen.dart` — post-submit "waiting for admin" screen with realtime claim updates

**Dart files to modify:**
- `lib/features/family_groups/services/family_group_service.dart` — `joinGroup()` becomes `acceptInvite()` (no DB write); add `lookupGroupByInviteCode` invariant docs
- `lib/features/family_groups/services/node_claim_service.dart` — pass `inviteCode` through to RPCs
- `lib/features/family_groups/screens/join_group_screen.dart` — "Join" button skips membership insert, goes directly to wizard with invite code
- `lib/features/family_groups/screens/identity_claim_wizard_screen.dart` — accept `inviteCode` route param; thread through to candidate fetch and claim creation; navigate to pending-review screen on submit
- `lib/features/family_groups/providers/node_claim_providers.dart` — add `myClaimStatusStreamProvider(claimId)` for realtime status
- `lib/core/router/app_router.dart` + `app_routes.dart` — wire `/claim-pending/:claimId` route; thread invite code through `/identity-claim/:groupId?invite=CODE`
- `lib/features/family_tree/screens/family_tree_screen.dart` — handle "user is not a member of this group" gracefully (route back to invite landing or home)

---

# Phase 1 — Database foundation

### Task 1: Add invite_code column to node_claims

**Files:**
- Create: `supabase/migrations/20260511100000_create_node_claim_accepts_invite_code.sql`

- [ ] **Step 1: Write the migration**

```sql
-- 20260511100000_create_node_claim_accepts_invite_code.sql
-- Allow create_node_claim() to authorize via invite_code instead of membership.
-- Persists the invite_code on the row so audit trail is preserved.

BEGIN;

-- 1. Add invite_code column (nullable; legacy claims won't have it).
ALTER TABLE public.node_claims
  ADD COLUMN IF NOT EXISTS invite_code TEXT;

COMMENT ON COLUMN public.node_claims.invite_code IS
  'Invite code used to submit this claim. Stored for audit; auth is performed at insert-time only.';

-- 2. Rewrite create_node_claim to accept p_invite_code AND fall back to membership.
--    Either path is acceptable; both cannot be present.
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

  -- Validation: edge_path/parent_side combo.
  IF p_edge_path NOT IN ('parent','child','spouse','sibling','uncle_aunt','grandparent','grandchild','cousin','nephew_niece') THEN
    RAISE EXCEPTION 'Invalid edge_path: %', p_edge_path;
  END IF;

  INSERT INTO node_claims (
    group_id, claimant_user_id, claimed_relative_id, declared_anchor_relative_id,
    declared_edge_path, declared_parent_side, declared_gender,
    proposed_full_name, proposed_gender, proposed_birth_year, proposed_city,
    proposed_photo_url, proposed_phone_number, invite_code, status
  ) VALUES (
    p_group_id, v_caller_id, p_claimed_relative_id, p_anchor_relative_id,
    p_edge_path, p_parent_side, p_gender,
    p_proposed_full_name, p_proposed_gender, p_proposed_birth_year, p_proposed_city,
    p_proposed_photo_url, p_proposed_phone_number, p_invite_code, 'pending'
  )
  RETURNING id INTO v_claim_id;

  -- Return the freshly-inserted claim (matches get_node_claim_by_id shape).
  SELECT to_jsonb(nc.*) INTO v_claim FROM node_claims nc WHERE id = v_claim_id;
  RETURN v_claim;
END;
$$;

-- 3. Update RLS so direct-insert via PostgREST is impossible (the RPC is the only path).
DROP POLICY IF EXISTS node_claims_insert_claimant ON public.node_claims;
CREATE POLICY node_claims_insert_claimant
  ON public.node_claims FOR INSERT
  WITH CHECK (false);  -- All inserts must go through create_node_claim().

COMMIT;
```

- [ ] **Step 2: Apply via MCP**

Use `mcp__plugin_supabase_supabase__apply_migration` with name `20260511100000_create_node_claim_accepts_invite_code` and the SQL body above.

- [ ] **Step 3: Verify with SQL probe**

Use `mcp__plugin_supabase_supabase__execute_sql`:

```sql
SELECT column_name FROM information_schema.columns
WHERE table_name = 'node_claims' AND column_name = 'invite_code';
```
Expected: 1 row.

```sql
SELECT proname, pronargs FROM pg_proc WHERE proname = 'create_node_claim';
```
Expected: pronargs = 13.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260511100000_create_node_claim_accepts_invite_code.sql
git commit -m "feat(claims): accept invite_code in create_node_claim — defers membership"
```

---

### Task 2: Add invite_code auth path to get_candidate_relatives

**Files:**
- Create: `supabase/migrations/20260511110000_get_candidate_relatives_accepts_invite_code.sql`

- [ ] **Step 1: Read the current RPC**

Read `supabase/migrations/20260508120000_get_candidate_relatives_rpc.sql` in full so the rewrite preserves the graph traversal logic exactly. Only the auth check at the top needs to change.

- [ ] **Step 2: Write the migration**

```sql
-- 20260511110000_get_candidate_relatives_accepts_invite_code.sql
-- Accept invite_code as alternative auth when the caller is not yet a member.

CREATE OR REPLACE FUNCTION public.get_candidate_relatives(
  p_group_id UUID,
  p_anchor_relative_id UUID,
  p_edge_path TEXT,
  p_parent_side TEXT,
  p_gender TEXT,
  p_invite_code TEXT DEFAULT NULL
)
RETURNS TABLE (
  -- COPY THE EXACT RETURN COLUMNS from 20260508120000 here.
  -- (id UUID, full_name TEXT, gender TEXT, relationship_type TEXT,
  --  is_self BOOLEAN, is_already_claimed BOOLEAN, score INT, reason TEXT, ...)
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_is_member BOOLEAN;
  v_code_valid BOOLEAN;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT EXISTS(
    SELECT 1 FROM family_group_members
    WHERE group_id = p_group_id AND user_id = v_caller
  ) INTO v_is_member;

  IF NOT v_is_member THEN
    IF p_invite_code IS NULL THEN
      RAISE EXCEPTION 'Caller is not a member of this group';
    END IF;
    SELECT EXISTS(
      SELECT 1 FROM family_groups
      WHERE id = p_group_id AND invite_code = p_invite_code
    ) INTO v_code_valid;
    IF NOT v_code_valid THEN
      RAISE EXCEPTION 'Invalid invite code';
    END IF;
  END IF;

  -- ↓↓↓ COPY THE EXACT GRAPH-TRAVERSAL BODY from 20260508120000 here. ↓↓↓
  -- (The traversal switches on p_edge_path and returns candidates.)
END;
$$;
```

**Important:** before applying, read the original migration body in full and paste it verbatim into the `↓↓↓ COPY ↓↓↓` placeholder. Do not summarize or re-derive.

- [ ] **Step 3: Apply via MCP**

Same as Task 1, Step 2.

- [ ] **Step 4: Verify**

```sql
SELECT pronargs FROM pg_proc WHERE proname = 'get_candidate_relatives';
```
Expected: 6.

- [ ] **Step 5: Smoke test the new auth path**

Use `mcp__plugin_supabase_supabase__execute_sql` (running as service role bypasses auth, so this only validates the SQL doesn't error structurally — real auth test happens in Phase 2 testing):

```sql
-- Should error with 'Authentication required' (auth.uid() is NULL in service role).
SELECT * FROM get_candidate_relatives(
  p_group_id := (SELECT id FROM family_groups LIMIT 1),
  p_anchor_relative_id := gen_random_uuid(),
  p_edge_path := 'spouse',
  p_parent_side := NULL,
  p_gender := 'female',
  p_invite_code := 'fake'
);
```
Expected: error "Authentication required" — confirms the function exists with the new signature.

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/20260511110000_get_candidate_relatives_accepts_invite_code.sql
git commit -m "feat(claims): accept invite_code in get_candidate_relatives"
```

---

### Task 3: Wizard bootstrap RPC for pre-member callers

**Files:**
- Create: `supabase/migrations/20260511120000_get_group_info_for_invite.sql`

**Why:** The wizard's bootstrap step (group name, admin's name banner, list of anchor candidates to seed the picker) currently queries multiple tables that all require membership. Rather than relax each policy or call 4 separate invite-coded RPCs, expose one RPC that returns everything the wizard needs in one round-trip.

- [ ] **Step 1: Write the migration**

```sql
-- 20260511120000_get_group_info_for_invite.sql
-- Single bootstrap call for the identity-claim wizard's pre-member phase.

CREATE OR REPLACE FUNCTION public.get_group_info_for_invite(
  p_invite_code TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_group RECORD;
  v_admin RECORD;
  v_relatives JSONB;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT id, name, invite_code, created_by, created_at
    INTO v_group
    FROM family_groups
   WHERE invite_code = p_invite_code;

  IF v_group.id IS NULL THEN
    RAISE EXCEPTION 'رمز الدعوة غير صالح';
  END IF;

  -- Admin profile (for the "you're joining X's family" banner).
  SELECT p.full_name, p.avatar_url
    INTO v_admin
    FROM profiles p
   WHERE p.id = v_group.created_by;

  -- Tree members visible from the wizard's anchor picker.
  -- Returns minimal fields — wizard doesn't need full relative records yet.
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
           'id', r.id,
           'full_name', r.full_name,
           'gender', r.gender,
           'is_self', r.is_self,
           'admin_label', r.relationship_type
         )), '[]'::jsonb)
    INTO v_relatives
    FROM relatives r
   WHERE r.family_group_id = v_group.id;

  RETURN jsonb_build_object(
    'group_id', v_group.id,
    'group_name', v_group.name,
    'admin_name', v_admin.full_name,
    'admin_avatar_url', v_admin.avatar_url,
    'relatives', v_relatives
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_group_info_for_invite(TEXT) TO authenticated;
```

- [ ] **Step 2: Apply via MCP**

- [ ] **Step 3: Verify with a real invite code**

```sql
SELECT get_group_info_for_invite((SELECT invite_code FROM family_groups WHERE created_by IS NOT NULL LIMIT 1));
```
Expected: JSON object with `group_id`, `group_name`, `admin_name`, `relatives` array.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260511120000_get_group_info_for_invite.sql
git commit -m "feat(claims): get_group_info_for_invite — wizard bootstrap without membership"
```

---

### Task 4: approve_node_claim INSERTs membership atomically

**Files:**
- Create: `supabase/migrations/20260511130000_approve_claim_inserts_membership.sql`

**Why:** Today `approve_node_claim` UPSERTs `relative_id_in_tree` on an existing `family_group_members` row. After this refactor that row does not yet exist for new joiners. We change the UPDATE → INSERT ... ON CONFLICT.

- [ ] **Step 1: Read the current approve_node_claim**

Read `supabase/migrations/20260508130000_node_claim_lifecycle_rpcs.sql` lines 186–328 in full. Note the two paths: claim-existing (line 227) and add-me (line 267). Both need to ensure membership exists post-approval.

- [ ] **Step 2: Write the migration**

```sql
-- 20260511130000_approve_claim_inserts_membership.sql
-- approve_node_claim becomes the sole creator of family_group_members rows
-- for joiners. Membership INSERT happens atomically with relative link-up.

CREATE OR REPLACE FUNCTION public.approve_node_claim(p_claim_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_claim node_claims%ROWTYPE;
  v_target_relative_id UUID;
  v_created_new BOOLEAN := false;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT * INTO v_claim FROM node_claims WHERE id = p_claim_id FOR UPDATE;
  IF v_claim.id IS NULL THEN
    RAISE EXCEPTION 'Claim not found';
  END IF;

  -- Only group admins may approve.
  IF NOT EXISTS (
    SELECT 1 FROM family_group_members
    WHERE group_id = v_claim.group_id AND user_id = v_caller AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'يجب أن تكون مديراً للمجموعة';
  END IF;

  IF v_claim.status <> 'pending' THEN
    RAISE EXCEPTION 'Claim is not pending (status=%)', v_claim.status;
  END IF;

  -- ▼ Determine target relative (existing OR newly inserted) ▼
  IF v_claim.claimed_relative_id IS NOT NULL THEN
    v_target_relative_id := v_claim.claimed_relative_id;
  ELSE
    INSERT INTO relatives (
      user_id, full_name, gender, birth_year, city, photo_url, phone_number,
      relationship_type, family_group_id, is_self
    ) VALUES (
      v_claim.claimant_user_id,
      v_claim.proposed_full_name,
      COALESCE(v_claim.proposed_gender, v_claim.declared_gender),
      v_claim.proposed_birth_year,
      v_claim.proposed_city,
      v_claim.proposed_photo_url,
      v_claim.proposed_phone_number,
      'other',  -- placeholder; family_edges carries the real semantics
      v_claim.group_id,
      true
    )
    RETURNING id INTO v_target_relative_id;
    v_created_new := true;
  END IF;

  -- ▼ Flip self + link to claimant ▼
  UPDATE relatives
     SET is_self = true,
         user_id = v_claim.claimant_user_id
   WHERE id = v_target_relative_id;

  -- ▼ ATOMIC MEMBERSHIP INSERT — the heart of this refactor ▼
  -- INSERT if missing, otherwise just update relative_id_in_tree.
  INSERT INTO family_group_members (group_id, user_id, role, relative_id_in_tree)
  VALUES (v_claim.group_id, v_claim.claimant_user_id, 'member', v_target_relative_id)
  ON CONFLICT (group_id, user_id)
  DO UPDATE SET relative_id_in_tree = EXCLUDED.relative_id_in_tree;

  -- ▼ Insert family_edges based on declared relation ▼
  -- (Preserves the logic from 20260508_approve_node_claim_inserts_edges.)
  PERFORM public._insert_claim_edges(
    v_claim.claimant_user_id,
    v_target_relative_id,
    v_claim.declared_anchor_relative_id,
    v_claim.declared_edge_path,
    v_claim.declared_parent_side,
    v_claim.group_id
  );

  -- ▼ Mark claim approved ▼
  UPDATE node_claims
     SET status = 'approved',
         decided_by_user_id = v_caller,
         decided_at = now()
   WHERE id = p_claim_id;

  RETURN jsonb_build_object(
    'claim_id', p_claim_id,
    'group_id', v_claim.group_id,
    'claimant_user_id', v_claim.claimant_user_id,
    'relative_id', v_target_relative_id,
    'created_new_node', v_created_new
  );
END;
$$;
```

**Note on `_insert_claim_edges`:** if the helper from the prior approve_node_claim_inserts_edges migration is inlined rather than extracted, inline the edge logic here directly. Read the existing migration first to confirm the helper's name and signature, then either call it (if it exists) or inline.

- [ ] **Step 3: Apply via MCP**

- [ ] **Step 4: Verify behavior on a fixture**

```sql
-- Create a synthetic pending claim and approve it as the group admin
-- in a single test transaction. ROLLBACK at the end so it's non-destructive.
BEGIN;
  -- (use existing testprod group + create a fake claimant)
  -- ...
  SELECT approve_node_claim('<claim_id>'::uuid);
  SELECT EXISTS(SELECT 1 FROM family_group_members WHERE user_id = '<claimant>'::uuid) AS member_exists;
ROLLBACK;
```
Expected: `member_exists` = true.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260511130000_approve_claim_inserts_membership.sql
git commit -m "feat(claims): approve_node_claim atomically INSERTs family_group_members"
```

---

### Task 5: Strip auto-insert from join_group_by_invite_code

**Files:**
- Create: `supabase/migrations/20260511140000_remove_auto_insert_in_join_rpc.sql`

- [ ] **Step 1: Write the migration**

```sql
-- 20260511140000_remove_auto_insert_in_join_rpc.sql
-- join_group_by_invite_code becomes a pure lookup — no side effects.
-- The client navigates the joiner directly into the wizard instead.

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
```

- [ ] **Step 2: Apply via MCP**

- [ ] **Step 3: Verify no insert happens**

```sql
BEGIN;
  SELECT join_group_by_invite_code('<some_existing_code>');
  SELECT COUNT(*) FROM family_group_members
   WHERE group_id = (SELECT id FROM family_groups WHERE invite_code = '<some_existing_code>');
ROLLBACK;
```
Expected: COUNT unchanged from before the call.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260511140000_remove_auto_insert_in_join_rpc.sql
git commit -m "feat(claims): join_group_by_invite_code no longer inserts membership"
```

---

### Task 6: Backfill — remove existing unlinked memberships

**Files:**
- Create: `supabase/migrations/20260511150000_backfill_remove_unlinked_memberships.sql`

**Decision:** Delete every `family_group_members` row where `relative_id_in_tree IS NULL`. These are the exact users the new flow protects against — they hold membership without identity. Pre-launch, the only affected user is `testprodjoiner` on testprod's group. They will be re-prompted to claim via the wizard the next time they visit the invite link or open the app.

- [ ] **Step 1: Probe first**

```sql
SELECT id, group_id, user_id, joined_at
  FROM family_group_members
 WHERE relative_id_in_tree IS NULL
 ORDER BY joined_at;
```

Save the output. If more than 10 rows, abort and ask the user whether bulk-delete is OK — backfill plan assumed pre-launch scale.

- [ ] **Step 2: Write the migration**

```sql
-- 20260511150000_backfill_remove_unlinked_memberships.sql
-- One-shot cleanup. Removes the "phantom member" rows that motivated
-- the deferred-membership refactor. Idempotent — re-running is a no-op.

BEGIN;

-- Audit row for safety: how many will we delete?
DO $$
DECLARE
  n INT;
BEGIN
  SELECT COUNT(*) INTO n FROM family_group_members WHERE relative_id_in_tree IS NULL;
  RAISE NOTICE 'Deleting % unlinked memberships', n;
END $$;

DELETE FROM family_group_members
 WHERE relative_id_in_tree IS NULL;

COMMIT;
```

- [ ] **Step 3: Apply via MCP**

- [ ] **Step 4: Verify**

```sql
SELECT COUNT(*) FROM family_group_members WHERE relative_id_in_tree IS NULL;
```
Expected: 0.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260511150000_backfill_remove_unlinked_memberships.sql
git commit -m "fix(claims): backfill — remove unlinked phantom memberships"
```

---

### Task 7: Seed claim notification templates

**Files:**
- Create: `supabase/migrations/20260511160000_seed_claim_notification_templates.sql`

- [ ] **Step 1: Write the migration**

```sql
-- 20260511160000_seed_claim_notification_templates.sql
-- Templates used by client-side notification dispatch when claim status changes.

INSERT INTO admin_notification_templates (template_key, title_ar, body_ar, category, variables, is_active)
VALUES
  ('claim_pending',
   'طلب انضمام جديد في {group_name}',
   '{claimant_name} يطلب الانضمام كـ {role_label}. اضغط للمراجعة.',
   'family_sharing',
   '["group_name","claimant_name","role_label"]'::jsonb,
   true),
  ('claim_approved',
   'تمت إضافتك إلى {group_name}',
   'وافق المدير على طلبك. مرحباً بك في العائلة!',
   'family_sharing',
   '["group_name"]'::jsonb,
   true),
  ('claim_rejected',
   'لم يتم قبول طلبك في {group_name}',
   '{reason_text} يمكنك تعديل بياناتك وإعادة المحاولة.',
   'family_sharing',
   '["group_name","reason_text"]'::jsonb,
   true)
ON CONFLICT (template_key) DO NOTHING;
```

- [ ] **Step 2: Apply via MCP**

- [ ] **Step 3: Verify**

```sql
SELECT template_key FROM admin_notification_templates
 WHERE template_key LIKE 'claim_%';
```
Expected: 3 rows.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260511160000_seed_claim_notification_templates.sql
git commit -m "feat(claims): seed claim_pending/approved/rejected templates"
```

---

# Phase 2 — Service layer

### Task 8: NodeClaimService accepts invite_code

**Files:**
- Modify: `lib/features/family_groups/services/node_claim_service.dart`

- [ ] **Step 1: Add `inviteCode` parameter to `createClaim` and `findCandidates`**

```dart
Future<NodeClaim> createClaim({
  required String groupId,
  String? claimedRelativeId,
  required String anchorRelativeId,
  required String edgePath,
  String? parentSide,
  required String gender,
  String? proposedFullName,
  String? proposedGender,
  int? proposedBirthYear,
  String? proposedCity,
  String? proposedPhotoUrl,
  String? proposedPhoneNumber,
  String? inviteCode,  // NEW — passed when caller is not yet a member
}) async {
  final result = await _supabase.rpc('create_node_claim', params: {
    'p_group_id': groupId,
    'p_claimed_relative_id': claimedRelativeId,
    'p_anchor_relative_id': anchorRelativeId,
    'p_edge_path': edgePath,
    'p_parent_side': parentSide,
    'p_gender': gender,
    'p_proposed_full_name': proposedFullName,
    'p_proposed_gender': proposedGender,
    'p_proposed_birth_year': proposedBirthYear,
    'p_proposed_city': proposedCity,
    'p_proposed_photo_url': proposedPhotoUrl,
    'p_proposed_phone_number': proposedPhoneNumber,
    'p_invite_code': inviteCode,
  });
  return NodeClaim.fromJson(result as Map<String, dynamic>);
}
```

Apply the same `inviteCode` parameter and `p_invite_code` param-passthrough to `findCandidates`.

- [ ] **Step 2: Add `getGroupInfoForInvite` method**

```dart
/// Pre-member wizard bootstrap. Returns group name, admin name,
/// and the relative list for the anchor picker — all without
/// requiring a family_group_members row. Auth is the invite code.
Future<Map<String, dynamic>> getGroupInfoForInvite(String inviteCode) async {
  final result = await _supabase
      .rpc('get_group_info_for_invite', params: {'p_invite_code': inviteCode})
      .timeout(const Duration(seconds: 10));
  return result as Map<String, dynamic>;
}
```

- [ ] **Step 3: Run analyzer**

```bash
flutter analyze lib/features/family_groups/services/node_claim_service.dart
```
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/family_groups/services/node_claim_service.dart
git commit -m "feat(claims): NodeClaimService threads inviteCode through RPCs"
```

---

### Task 9: FamilyGroupService — remove `joinGroup` side-effects, keep as lookup-only

**Files:**
- Modify: `lib/features/family_groups/services/family_group_service.dart`

- [ ] **Step 1: Replace `joinGroup` with `acceptInvite` semantics**

Find the existing `joinGroup` static method (line ~77–116). Replace its body so it ONLY validates the invite code and returns the group — no membership insert, no notification fan-out (notifications now fire on approval).

```dart
/// Validate an invite code and return the group it belongs to.
/// **Does NOT create a family_group_members row** — that happens
/// atomically inside approve_node_claim when an admin confirms the
/// joiner's identity-claim. Callers should follow this with a
/// navigation into the identity-claim wizard.
static Future<FamilyGroup> acceptInvite({
  required String inviteCode,
}) async {
  final client = SupabaseConfig.client;
  final groupData = await client.rpc(
    'join_group_by_invite_code',
    params: {'code': inviteCode},
  );
  final results = groupData is List<dynamic>
      ? groupData
      : (groupData != null ? [groupData] : <dynamic>[]);
  if (results.isEmpty) {
    throw Exception('رمز الدعوة غير صالح');
  }
  return FamilyGroup.fromJson(results.first as Map<String, dynamic>);
}

@Deprecated('Use acceptInvite. joinGroup created a phantom membership row '
            'before identity was verified — fixed 2026-05-11.')
static Future<FamilyGroup> joinGroup({
  required String inviteCode,
  required String userId,
}) => acceptInvite(inviteCode: inviteCode);
```

- [ ] **Step 2: Delete the now-unused `_sendJoinNotification` helper**

Find `_sendJoinNotification` (line ~118–162) and delete it entirely. Notifications now fire on `approve_node_claim` server-side (Phase 5).

- [ ] **Step 3: Run analyzer**

```bash
flutter analyze lib/features/family_groups/services/family_group_service.dart
```
Expected: No errors. Deprecation warnings on `joinGroup` callers are fine — Task 10 cleans them up.

- [ ] **Step 4: Commit**

```bash
git add lib/features/family_groups/services/family_group_service.dart
git commit -m "refactor(claims): joinGroup → acceptInvite (lookup-only, no side-effects)"
```

---

# Phase 3 — Joiner-side UI

### Task 10: JoinGroupScreen — skip membership insert, route to wizard with invite code

**Files:**
- Modify: `lib/features/family_groups/screens/join_group_screen.dart`

- [ ] **Step 1: Replace `_joinGroup()` body**

```dart
Future<void> _joinGroup() async {
  if (_isJoining) return;
  final user = ref.read(currentUserProvider);
  if (user == null) {
    final redirectPath = Uri.encodeComponent(
      '${AppRoutes.joinFamilyGroup}/${widget.inviteCode}',
    );
    context.go('${AppRoutes.login}?redirect=$redirectPath');
    return;
  }

  setState(() => _isJoining = true);

  try {
    // Validate the invite code (no DB write yet).
    final group = await FamilyGroupService.acceptInvite(
      inviteCode: widget.inviteCode,
    );

    if (!mounted) return;
    HapticFeedback.heavyImpact();

    // Check for a phone-based invitation — it's a fast-path that
    // skips the wizard because the admin already pre-identified the
    // joiner. This branch still creates the membership through the
    // invitation-accept RPC (not this refactor's concern).
    try {
      final invitationService = NodeInvitationService();
      final pending = await invitationService.getMyPendingInvitations();
      final matchingInvitation = pending.where(
        (inv) => inv.groupId == group.id,
      );
      if (matchingInvitation.isNotEmpty && mounted) {
        context.go(
          '${AppRoutes.invitationDetail}/${matchingInvitation.first.id}',
        );
        return;
      }
    } catch (e) {
      debugPrint('Failed to check pending invitations: $e');
    }

    // Drop the joiner into the identity-claim wizard, passing the
    // invite code as the auth token for pre-member RPCs.
    if (mounted) {
      context.go(
        '${AppRoutes.identityClaim}/${group.id}?invite=${Uri.encodeComponent(widget.inviteCode)}',
      );
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _isJoining = false;
        _errorMessage = e.toString().contains('invite') ||
                e.toString().contains('دعوة')
            ? 'رمز الدعوة غير صالح أو منتهي الصلاحية'
            : 'حدث خطأ أثناء التحقق من المجموعة. يرجى المحاولة مرة أخرى';
      });
    }
  }
}
```

- [ ] **Step 2: Delete the post-join cache invalidations**

Lines that previously called `ref.invalidate(userFamilyGroupProvider)`, `ref.invalidate(groupRelativesStreamProvider(...))`, etc., are no longer relevant — there's no membership to invalidate. They were already removed in the replacement body above. Confirm nothing else references them on this screen.

- [ ] **Step 3: Update button label semantically**

Find the `GradientButton(text: 'انضم للمجموعة', ...)` near line 370. Change text to `'متابعة للتعرّف عليك'` — it no longer "joins" anything; it advances to the identity wizard.

- [ ] **Step 4: Run analyzer + a quick build check**

```bash
flutter analyze lib/features/family_groups/screens/join_group_screen.dart
```
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/family_groups/screens/join_group_screen.dart
git commit -m "feat(claims): JoinGroupScreen — skip membership, route to wizard with code"
```

---

### Task 11: Route invite code through identity-claim wizard

**Files:**
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/core/router/app_routes.dart` (only if a constant rename helps)

- [ ] **Step 1: Find the identityClaim route**

```bash
grep -n "identityClaim\|identity-claim\|IdentityClaim" lib/core/router/app_router.dart
```
Locate the `GoRoute` for `/identity-claim/:groupId`.

- [ ] **Step 2: Pass `invite` query param into the screen**

```dart
GoRoute(
  path: '${AppRoutes.identityClaim}/:groupId',
  name: 'identityClaim',
  pageBuilder: (context, state) {
    final groupId = state.pathParameters['groupId']!;
    final inviteCode = state.uri.queryParameters['invite'];
    return _buildPageWithTransition(
      context,
      state,
      IdentityClaimWizardScreen(
        groupId: groupId,
        inviteCode: inviteCode,  // NEW
      ),
    );
  },
),
```

- [ ] **Step 3: Add new route for pending-review screen**

```dart
GoRoute(
  path: '${AppRoutes.claimPending}/:claimId',
  name: 'claimPending',
  pageBuilder: (context, state) {
    final claimId = state.pathParameters['claimId']!;
    return _buildPageWithTransition(
      context,
      state,
      ClaimPendingReviewScreen(claimId: claimId),
    );
  },
),
```

- [ ] **Step 4: Add the constant in app_routes.dart**

```dart
static const String claimPending = '/claim-pending';
```

- [ ] **Step 5: Run analyzer**

The new screen import will fail until Task 13 creates it. That's fine — keep the route definition but expect a red squiggle until then. If Dart's analyzer trips during this commit, stash the route lines and add them in Task 13 instead.

- [ ] **Step 6: Commit (only if analyzer is clean — otherwise bundle with Task 13)**

```bash
git add lib/core/router/app_router.dart lib/core/router/app_routes.dart
git commit -m "feat(claims): route inviteCode → wizard; add /claim-pending route"
```

---

### Task 12: IdentityClaimWizardScreen — accept inviteCode, use invite-authed RPCs

**Files:**
- Modify: `lib/features/family_groups/screens/identity_claim_wizard_screen.dart`

- [ ] **Step 1: Add `inviteCode` constructor param**

```dart
class IdentityClaimWizardScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String? inviteCode;  // NEW — null when caller is already a member
  const IdentityClaimWizardScreen({
    super.key,
    required this.groupId,
    this.inviteCode,
  });
  ...
}
```

- [ ] **Step 2: Replace `_bootstrapAdminAndTree` to call the new RPC**

Find `_bootstrapAdminAndTree` (it was at line ~101 prior to the type-error fix). Replace the body so that when `widget.inviteCode != null` it calls `getGroupInfoForInvite`; otherwise falls back to the existing per-call lookups.

```dart
Future<void> _bootstrapAdminAndTree() async {
  try {
    if (widget.inviteCode != null) {
      // Pre-member path — one round-trip with invite-code auth.
      final info = await ref
          .read(nodeClaimServiceProvider)
          .getGroupInfoForInvite(widget.inviteCode!);
      if (!mounted) return;
      setState(() {
        _groupName = info['group_name'] as String?;
        _adminName = info['admin_name'] as String?;
        _adminAvatarUrl = info['admin_avatar_url'] as String?;
        _treeRelatives = ((info['relatives'] as List<dynamic>?) ?? const [])
            .cast<Map<String, dynamic>>();
        _bootstrapLoading = false;
      });
      return;
    }

    // Member path — existing logic (unchanged).
    // ... existing code that pulls profiles/relatives via gated queries.
  } catch (e, st) {
    debugPrint('[IdentityClaimWizard._bootstrap] ✗ $e\n$st');
    if (!mounted) return;
    setState(() {
      _bootstrapLoading = false;
      _bootstrapError = e.toString();
    });
  }
}
```

- [ ] **Step 3: Thread inviteCode into NodeClaimService calls**

Find where `findCandidates` is called inside the wizard. Add `inviteCode: widget.inviteCode` as a named parameter. Same for `createClaim` at submit time:

```dart
final claim = await ref.read(nodeClaimServiceProvider).createClaim(
  groupId: widget.groupId,
  claimedRelativeId: _selectedCandidateId,
  anchorRelativeId: _anchorRelativeId,
  edgePath: _edgePath,
  parentSide: _parentSide,
  gender: _gender,
  proposedFullName: _proposedFullName,
  proposedGender: _proposedGender,
  proposedBirthYear: _proposedBirthYear,
  proposedCity: _proposedCity,
  proposedPhotoUrl: _proposedPhotoUrl,
  proposedPhoneNumber: _proposedPhoneNumber,
  inviteCode: widget.inviteCode,  // NEW
);
```

- [ ] **Step 4: After submit, navigate to ClaimPendingReviewScreen**

Find the post-submit navigation (currently probably `context.go(AppRoutes.familyTree)` or similar). Replace with:

```dart
if (mounted) {
  context.go('${AppRoutes.claimPending}/${claim.id}');
}
```

- [ ] **Step 5: Run analyzer**

```bash
flutter analyze lib/features/family_groups/screens/identity_claim_wizard_screen.dart
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/family_groups/screens/identity_claim_wizard_screen.dart
git commit -m "feat(claims): wizard threads inviteCode + routes to pending-review on submit"
```

---

### Task 13: ClaimPendingReviewScreen — realtime status surface for the joiner

**Files:**
- Create: `lib/features/family_groups/screens/claim_pending_review_screen.dart`

- [ ] **Step 1: Write the screen**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:silni_app/core/constants/app_spacing.dart';
import 'package:silni_app/core/constants/app_typography.dart';
import 'package:silni_app/core/router/app_routes.dart';
import 'package:silni_app/core/theme/theme_provider.dart';
import 'package:silni_app/features/family_groups/providers/node_claim_providers.dart';
import 'package:silni_app/shared/widgets/gradient_background.dart';
import 'package:silni_app/shared/widgets/glass_card.dart';
import 'package:silni_app/shared/widgets/gradient_button.dart';
import 'package:silni_app/shared/widgets/premium_loading_indicator.dart';

/// Surfaces the joiner's "waiting for admin review" state after they
/// submit a claim. Subscribes to the claim's status via realtime so
/// approval/rejection lands without the user pulling-to-refresh.
class ClaimPendingReviewScreen extends ConsumerWidget {
  final String claimId;
  const ClaimPendingReviewScreen({super.key, required this.claimId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final claimAsync = ref.watch(claimByIdRealtimeProvider(claimId));

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(animated: true, child: SizedBox.expand()),
          SafeArea(
            child: claimAsync.when(
              loading: () => const Center(child: PremiumLoadingIndicator()),
              error: (e, _) => _ErrorView(message: e.toString()),
              data: (claim) {
                switch (claim.status) {
                  case 'pending':
                    return _PendingView(themeColors: themeColors);
                  case 'approved':
                    // Auto-navigate to the family tree after a beat,
                    // so the celebration reads.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Future.delayed(const Duration(milliseconds: 1200), () {
                        if (context.mounted) {
                          context.go(AppRoutes.familyTree);
                        }
                      });
                    });
                    return _ApprovedView(themeColors: themeColors);
                  case 'rejected':
                    return _RejectedView(
                      themeColors: themeColors,
                      reason: claim.rejectionReason,
                      groupId: claim.groupId,
                    );
                  case 'cancelled':
                    return _CancelledView(themeColors: themeColors);
                  default:
                    return _PendingView(themeColors: themeColors);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingView extends StatelessWidget {
  final dynamic themeColors;
  const _PendingView({required this.themeColors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.hourglass_top_rounded,
              size: AppSpacing.iconXxl, color: themeColors.onSurface),
          const SizedBox(height: AppSpacing.md),
          Text('بانتظار موافقة المدير',
              style: AppTypography.headlineSmall.copyWith(
                  color: themeColors.onSurface,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text('سنخبرك فور مراجعة طلبك. لا حاجة للبقاء على هذه الشاشة.',
              style: AppTypography.bodyMedium.copyWith(
                  color: themeColors.onSurface.withValues(alpha: 0.75)),
              textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xl),
          GradientButton(
            text: 'العودة للرئيسية',
            icon: Icons.home_rounded,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
    );
  }
}

class _ApprovedView extends StatelessWidget {
  final dynamic themeColors;
  const _ApprovedView({required this.themeColors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded,
              size: AppSpacing.iconXxl, color: themeColors.statusSuccess),
          const SizedBox(height: AppSpacing.md),
          Text('تم القبول!',
              style: AppTypography.headlineSmall.copyWith(
                  color: themeColors.onSurface,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Text('مرحباً بك في العائلة',
              style: AppTypography.bodyLarge.copyWith(
                  color: themeColors.onSurface.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}

class _RejectedView extends StatelessWidget {
  final dynamic themeColors;
  final String? reason;
  final String groupId;
  const _RejectedView({
    required this.themeColors,
    required this.reason,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.cancel_rounded,
              size: AppSpacing.iconXxl, color: themeColors.statusError),
          const SizedBox(height: AppSpacing.md),
          Text('لم يتم قبول طلبك',
              style: AppTypography.headlineSmall.copyWith(
                  color: themeColors.onSurface,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
          if (reason != null && reason!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            GlassCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text('سبب الرفض: $reason',
                  style: AppTypography.bodyMedium.copyWith(
                      color: themeColors.onSurface.withValues(alpha: 0.85))),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          GradientButton(
            text: 'العودة للرئيسية',
            icon: Icons.home_rounded,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
    );
  }
}

class _CancelledView extends StatelessWidget {
  final dynamic themeColors;
  const _CancelledView({required this.themeColors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('تم إلغاء الطلب',
              style: AppTypography.headlineSmall.copyWith(
                  color: themeColors.onSurface)),
          const SizedBox(height: AppSpacing.xl),
          GradientButton(
            text: 'العودة للرئيسية',
            icon: Icons.home_rounded,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text('تعذر تحميل الطلب: $message'),
      ),
    );
  }
}
```

- [ ] **Step 2: Add `claimByIdRealtimeProvider` in node_claim_providers.dart**

```dart
/// Streams a single claim's row, updating in realtime on UPDATE events.
/// Backed by getClaimById for the initial fetch + a postgres-changes
/// subscription for status flips.
final claimByIdRealtimeProvider =
    StreamProvider.autoDispose.family<NodeClaim, String>((ref, claimId) async* {
  final service = ref.watch(nodeClaimServiceProvider);
  yield await service.getClaimById(claimId);

  // Subscribe to row changes.
  final controller = StreamController<NodeClaim>();
  final channel = SupabaseConfig.client
      .channel('node_claim_$claimId')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'node_claims',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: claimId,
        ),
        callback: (payload) async {
          try {
            controller.add(await service.getClaimById(claimId));
          } catch (_) {}
        },
      )
      .subscribe();

  ref.onDispose(() {
    controller.close();
    SupabaseConfig.client.removeChannel(channel);
  });

  yield* controller.stream;
});
```

- [ ] **Step 3: Confirm route in app_router.dart resolves**

The route added in Task 11 Step 3 now has a real screen to bind to. Re-run analyzer.

```bash
flutter analyze lib/features/family_groups/ lib/core/router/
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/family_groups/screens/claim_pending_review_screen.dart \
        lib/features/family_groups/providers/node_claim_providers.dart \
        lib/core/router/app_router.dart \
        lib/core/router/app_routes.dart
git commit -m "feat(claims): ClaimPendingReviewScreen with realtime status updates"
```

---

# Phase 4 — Navigation guards & non-member UX

### Task 14: family_tree_screen — graceful handling when user is not a member

**Files:**
- Modify: `lib/features/family_tree/screens/family_tree_screen.dart`

**Why:** A non-member who tries to navigate to `/family-tree` (via deep link, back-stack, or stale provider state) currently hits a screen that queries `family_group_members` and gets back null. The screen renders, but downstream queries fail unpredictably. We make this case explicit.

- [ ] **Step 1: Audit current guard**

Read lines 130–180 of `family_tree_screen.dart`. The `_bootstrap` (or equivalent) method queries `family_group_members` via `.maybeSingle()` and proceeds with `null` when the user isn't a member.

- [ ] **Step 2: Add explicit not-member guard**

Where the `memberRow` is fetched:

```dart
final memberRow = await SupabaseConfig.client
    .from('family_group_members')
    .select('role, relative_id_in_tree')
    .eq('group_id', groupId)
    .eq('user_id', userId)
    .maybeSingle();

if (memberRow == null) {
  // User is not (yet) a member of this group — could be because they
  // tapped a deep link without going through the wizard, or because
  // their unlinked-membership row was pruned by the 2026-05-11 backfill.
  // Route them home; they can re-tap the invite link.
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('لست عضواً في هذه المجموعة بعد')),
    );
    context.go(AppRoutes.home);
  }
  return;
}
```

- [ ] **Step 3: Run analyzer**

```bash
flutter analyze lib/features/family_tree/screens/family_tree_screen.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/family_tree/screens/family_tree_screen.dart
git commit -m "fix(family-tree): graceful handling when user isn't yet a group member"
```

---

### Task 15: family_group_screen — guard the admin/member-only sections

**Files:**
- Modify: `lib/features/family_groups/screens/family_group_screen.dart`

- [ ] **Step 1: Find the screen's bootstrap**

```bash
grep -n "family_group_members\|isMember\|userFamilyGroupProvider" lib/features/family_groups/screens/family_group_screen.dart
```

- [ ] **Step 2: Add not-member fallback**

If the screen is reached without active membership in `groupId`, render a minimal "you don't have access" card with a button back to home. Don't crash, don't show empty admin lists.

```dart
if (memberRow == null) {
  return Scaffold(
    body: SafeArea(
      child: Center(
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('لا يمكنك عرض هذه المجموعة'),
              const SizedBox(height: AppSpacing.md),
              GradientButton(
                text: 'العودة للرئيسية',
                onPressed: () => context.go(AppRoutes.home),
                icon: Icons.home_rounded,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
```

- [ ] **Step 3: Run analyzer**

- [ ] **Step 4: Commit**

```bash
git add lib/features/family_groups/screens/family_group_screen.dart
git commit -m "fix(family-groups): graceful render when user lacks membership"
```

---

# Phase 5 — Notifications

### Task 16: approve_node_claim fires claim_approved notification

**Files:**
- Modify: `supabase/migrations/20260511130000_approve_claim_inserts_membership.sql` — OR add a new migration `20260511170000_approve_claim_notifies.sql` if the prior migration already shipped.

**Why:** Client-side push fan-out via `send-push-notification` edge function. Server-side trigger keeps the joiner informed without requiring the admin's app to do the dispatch.

- [ ] **Step 1: Write the migration**

```sql
-- 20260511170000_approve_claim_notifies.sql
-- Trigger a push to the joiner when their claim is approved.
-- Uses the existing send-push-notification edge function via pg_net.

CREATE OR REPLACE FUNCTION public._notify_claim_status(
  p_claimant_user_id UUID,
  p_group_id UUID,
  p_template_key TEXT,
  p_extra JSONB DEFAULT '{}'::jsonb
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_template RECORD;
  v_group_name TEXT;
  v_title TEXT;
  v_body TEXT;
BEGIN
  SELECT title_ar, body_ar INTO v_template
    FROM admin_notification_templates
   WHERE template_key = p_template_key AND is_active;
  IF NOT FOUND THEN RETURN; END IF;

  SELECT name INTO v_group_name FROM family_groups WHERE id = p_group_id;

  v_title := REPLACE(v_template.title_ar, '{group_name}', COALESCE(v_group_name, ''));
  v_body  := REPLACE(v_template.body_ar,  '{group_name}', COALESCE(v_group_name, ''));
  -- Additional variable substitution can be done here from p_extra.

  PERFORM net.http_post(
    url := current_setting('app.settings.supabase_url', true) || '/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
    ),
    body := jsonb_build_object(
      'userId', p_claimant_user_id,
      'notificationType', 'system',
      'title', v_title,
      'body', v_body,
      'data', jsonb_build_object('type', p_template_key, 'group_id', p_group_id)
    )
  );
END;
$$;
```

If `app.settings.supabase_url` / `app.settings.service_role_key` are not already configured in the project, leave this as a no-op (`RETURN`) and add a TODO comment. In-app realtime via `myPendingClaimsProvider` already covers the joiner's UX without the push.

- [ ] **Step 2: Call `_notify_claim_status` from approve / reject RPCs**

Inside `approve_node_claim` (right before the final RETURN):

```sql
PERFORM public._notify_claim_status(
  v_claim.claimant_user_id, v_claim.group_id, 'claim_approved'
);
```

Inside `reject_node_claim`:

```sql
PERFORM public._notify_claim_status(
  v_claim.claimant_user_id, v_claim.group_id, 'claim_rejected',
  jsonb_build_object('reason_text', COALESCE(p_reason, ''))
);
```

Inside `create_node_claim` (to ping admins):

```sql
-- Loop over admins and notify each.
FOR v_admin IN
  SELECT user_id FROM family_group_members
   WHERE group_id = p_group_id AND role = 'admin'
LOOP
  PERFORM public._notify_claim_status(
    v_admin.user_id, p_group_id, 'claim_pending'
  );
END LOOP;
```

- [ ] **Step 3: Apply via MCP**

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260511170000_approve_claim_notifies.sql
git commit -m "feat(claims): push notifications on claim_pending/approved/rejected"
```

---

# Phase 6 — End-to-end testing

### Task 17: Manual test journey on simulator + phone

**Files:** none (testing only)

- [ ] **Step 1: Build joiner simulator + admin phone**

```bash
flutter run -d <simulator_udid>  # for testprodjoiner
# admin: TestFlight build on physical device (testprod)
```

- [ ] **Step 2: Reset state — verify the backfill cleared testprodjoiner**

In SQL:

```sql
SELECT * FROM family_group_members WHERE user_id = '<testprodjoiner_uuid>';
```
Expected: 0 rows.

- [ ] **Step 3: Tap invite link on simulator**

Verify: simulator opens to `JoinGroupScreen` showing group name. Tap "متابعة للتعرّف عليك".

Expected: navigates to `IdentityClaimWizardScreen` with admin name banner. **No row in `family_group_members` yet.** Confirm:

```sql
SELECT COUNT(*) FROM family_group_members WHERE user_id = '<testprodjoiner_uuid>';
```
Expected: 0.

- [ ] **Step 4: Complete the wizard and submit**

Submit claim as "spouse, female." Verify:

- Navigates to `ClaimPendingReviewScreen`.
- SQL: `SELECT id, status, invite_code FROM node_claims WHERE claimant_user_id = '<testprodjoiner_uuid>'` — 1 row, status='pending', invite_code populated.
- Still no row in `family_group_members`.

- [ ] **Step 5: Admin phone — verify pending card appears**

On testprod's phone, open `FamilyGroupScreen`. `PendingClaimsCard` shows the new claim. Tap it.

Expected: `AdminReviewClaimScreen` loads claim details. Approve.

- [ ] **Step 6: Verify atomic membership creation**

```sql
SELECT user_id, role, relative_id_in_tree
  FROM family_group_members
 WHERE user_id = '<testprodjoiner_uuid>';
```
Expected: 1 row, `relative_id_in_tree` IS NOT NULL.

```sql
SELECT id, is_self, user_id
  FROM relatives
 WHERE id = (SELECT relative_id_in_tree FROM family_group_members WHERE user_id = '<testprodjoiner_uuid>');
```
Expected: 1 row, `is_self=true`, `user_id='<testprodjoiner_uuid>'`.

```sql
SELECT * FROM family_edges
 WHERE family_group_id = '<testprod_group>'
   AND (from_id = '<joiner_relative_id>' OR to_id = '<joiner_relative_id>');
```
Expected: at least 1 edge (e.g., spouse_of).

- [ ] **Step 7: On simulator — pending screen flips to approved**

The `claimByIdRealtimeProvider` subscription should fire. `ClaimPendingReviewScreen` shows `_ApprovedView` then auto-navigates to family tree where testprodjoiner now sees testprod and her own self-node.

- [ ] **Step 8: Test rejection path**

Repeat from Step 3 with a different fake user. Admin rejects with reason. Verify simulator shows `_RejectedView` with the reason. Verify no row in `family_group_members`.

- [ ] **Step 9: Test "user closes app mid-pending"**

After submitting claim, force-quit simulator app. Reopen. Verify the app re-routes to `ClaimPendingReviewScreen` via the open-pending-claim provider — or at minimum, a banner on `HomeScreen` shows "you have a pending claim in <group>" with a tap-target to the pending screen. (If this provider doesn't exist yet, add a follow-up task — see Open Items.)

---

### Task 18: Run the existing test suite

- [ ] **Step 1: Unit tests**

```bash
flutter test test/unit/
```
Expected: PASS.

- [ ] **Step 2: Smoke**

```bash
make smoke
```
Expected: PASS.

- [ ] **Step 3: If anything fails, fix or document**

Family-graph unit tests should not be affected by this change (they're pure). If `family_group_service_test.dart` tests `joinGroup` insertion side-effects, update them to expect no insert.

---

# Open Items (post-merge follow-ups, NOT in this plan)

- **Auto-restore pending claim on app cold-start** — `HomeScreen` could query `getMyPendingClaims()` and surface a banner that links to `ClaimPendingReviewScreen`. Out of scope here; testing Task 17 Step 9 may surface this as needed.
- **"Cancel claim" UI in ClaimPendingReviewScreen** — the joiner currently can't withdraw their pending claim from this screen. `NodeClaimService.cancelClaim` exists; just needs a button.
- **`leave_group_atomic` interaction with new flow** — verify the leave RPC still works correctly when called on a member with an approved claim (probably fine; calls out as a known-good area).
- **Android assetlinks.json** — still placeholder, unrelated to this refactor.

---

# Self-Review Checklist

**Spec coverage:** The user said "they should go through all steps and wizard to let the engine know who this guy is, then based on the outcome we enrich the guy with proper data." Mapping:

- "go through all steps and wizard" — Task 10 (JoinGroupScreen routes to wizard, no DB write) + Task 12 (wizard threads invite code).
- "let the engine know who this guy is" — Task 1 (create_node_claim invite-coded) + Task 2 (candidates lookup invite-coded) + Task 12 (wizard submit creates the claim).
- "based on the outcome we enrich the guy" — Task 4 (approve_node_claim atomically creates membership + relative + edges).
- "should NOT see admin's relatives as their relatives as OTHER" — Task 6 (backfill removes phantom memberships); RLS already prevents non-members from seeing group relatives so no new policy needed.

**Placeholder scan:** Two intentional copy-the-real-body markers in Task 2 (Step 2) and Task 4 (Step 2) — these are explicit instructions to copy verbatim from existing migrations, not TBDs. The plan flags both with "**Important:** before applying, read the original migration body in full."

**Type consistency:** `inviteCode` is the Dart name throughout (Tasks 8, 9, 10, 11, 12). `p_invite_code` is the SQL param name throughout (Tasks 1, 2, 3). `claimByIdRealtimeProvider` is used in Task 13 and added in Task 13 — same task, no drift.

**Risk:** Task 6 (backfill) is destructive. The probe in Step 1 caps execution at ≤10 rows; anything larger aborts. Confirmed safe for pre-launch.
