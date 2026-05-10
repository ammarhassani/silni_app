# Family Sharing — Identity Claim Flow (Design)

**Date:** 2026-05-08
**Status:** Approved (design); awaiting implementation plan
**Supersedes (in part):** [docs/plans/2026-03-08-group-invitation-redesign.md](2026-03-08-group-invitation-redesign.md) — Pillar 2 was designed but cut from v1 launch (2026-04-26). This spec revives it as a fast path and adds a new discovery flow for the long tail.

---

## Problem Statement

A family group is currently joinable only via a public invite link. After a successful join, the joiner becomes a group member but is not linked to any specific tree node. The post-join code at [join_group_screen.dart:144-158](../../lib/features/family_groups/screens/join_group_screen.dart#L144) checks `getMyPendingInvitations()` for a phone-matched invitation — but since invitation *creation* was cut from v1, that table is empty. **Result: every public-link joiner becomes an unlinked member with no admin-side UI to assign them a node afterwards.** They see the tree, but they're not in it.

Industry research ([Geni's "claim profile"](https://help.geni.com/), [WikiTree "Trusted List"](https://www.wikitree.com/wiki/Help:Trusted_List), MyHeritage) shows the established pattern is admin pre-assignment via email — admin attaches an email to a tree node, invitee accepts via that email, identity is bound up front. This pattern doesn't fit Silni: most tree nodes are stubs with only a name and relationship type, no email or phone. We need a different mechanism for the long tail, while keeping the industry pattern as a fast path where data permits.

## Goals

1. Every public-link joiner has a path to be linked to a specific tree node, or to add themselves as a new node.
2. Admin retains trust authority — no one is placed in the tree without admin consent.
3. The common case (admin is the patriarch/matriarch, joiner knows them) is fast — minimal taps.
4. The long tail (in-laws, distant cousins, link forwarded twice) has a humane path.
5. Visual feedback: claimed nodes look distinct from stub nodes in the tree.

## Non-Goals (v1)

- "Suggest a different placement" admin counter-proposals (admin rejects → joiner re-picks).
- "Kick a confirmed member" — leaving is the joiner's choice.
- "Revoke a previously approved claim" — same reason.
- Any auto-matching beyond the phone/email fast path (we don't try to guess identity from name similarity).

---

## Architecture: Two Paths

```
                         ┌─ Admin has phone/email for the node? ─┐
                         │                                       │
                         ▼                                       ▼
                    PRE-ASSIGNMENT                         DISCOVERY FLOW
                    (Pillar 1 / fast path)                 (Pillar 2 / long tail)
                         │                                       │
                         ▼                                       ▼
                    Admin sends targeted invite               Joiner self-identifies via:
                    (phone OTP or email link)                   1. Anchor person
                                                                2. Relationship class
                         │                                       3. Pick from candidates
                         ▼                                          OR add yourself
                    Invitee signs up via                         │
                    matched contact, instant link                ▼
                                                            Admin approves the claim
                                                                 │
                                                                 ▼
                                                            Linked to node
```

## Pillar 1 — Pre-assignment Fast Path (revived)

The Pillar 2 design from 2026-03-08 (phone-OTP invitations targeted at specific nodes) is revived here as the *fast path*. Re-implementation requirements:

1. Fix the dormant column-name bug in `create_node_invitation` and `get_my_pending_invitations` RPCs (refs `name`, column is `full_name` — see [node_invitation_service.dart:1-6](../../lib/features/family_groups/services/node_invitation_service.dart#L1)).
2. Wire the admin UI on relative-detail screen: "ادعُ هذا الفرد" button. Visible only if the relative has a phone number stored. If no phone number, the button shows a prompt: "أضف رقم الجوال لإرسال دعوة" with an inline add action.
3. Acceptance plumbing already exists in [join_group_screen.dart:144-158](../../lib/features/family_groups/screens/join_group_screen.dart#L144) — when a joiner has a phone-matched pending invitation for the group they just joined, app navigates to `InvitationDetailScreen` for direct claim. Reuse this.
4. Same applies for email-based invitations (new RPC: `create_node_invitation_email` or extend the existing one with an `email` parameter alongside `phone_number`).

**Outcome:** When admin has the data, joiner skips the entire discovery flow.

## Pillar 2 — Discovery Flow (new)

The discovery flow runs whenever a public-link joiner has no matching pending invitation. It runs as a single guided journey immediately after `joinGroup` succeeds — *before* dropping the joiner on the family tree.

### Step 1: Anchor person

The first screen presents one yes/no question:

> **هل أنت من أقارب [admin name]؟**
> *(Are you a relative of [admin name]?)*
>
> **نعم** — proceed with admin as anchor
> **لا، أنا قريب لشخص آخر في العائلة** — open anchor picker

If "no": a search bar + scrollable list of all tree members (name + parent's name as subtitle for disambiguation). Joiner picks an anchor person — say أحمد. From this point on, all relationship questions reference the chosen anchor.

**Default-to-admin captures the 80% case in one tap.** The anchor-switch escape covers in-laws, distant cousins, and link-forwarded-twice cases.

### Step 2: Relationship picker (two-step drill-down)

Once anchor is locked, joiner picks their relationship to the anchor person. Two-step picker because Arabic kinship vocabulary is rich and side-aware (paternal vs maternal matters).

**Step 2a — Category** (~7 options):

- من أهل البيت (immediate household: parent / sibling / child / spouse)
- من جيل أكبر (older generation: uncle / aunt / parent's spouse-in-law)
- من جيل الأجداد (grandparent generation)
- من جيل أصغر (younger generation: niece / nephew / child-in-law)
- من جيل الأحفاد (grandchild generation)
- ابن/ة عم أو خال (cousin)
- نسيب/ة (in-law: father-in-law / mother-in-law / sibling-in-law)
- غير ذلك (other / I don't fit a category)

**Step 2b — Specific role** (depends on Step 2a, ~3–5 options each):

- Within "أهل البيت": أب / أم / ابن / ابنة / أخ / أخت / زوج / زوجة
- Within "جيل أكبر": عم (paternal uncle) / عمة / خال (maternal uncle) / خالة
- Within "جيل الأجداد": جد لأب / جدة لأب / جد لأم / جدة لأم
- Within "جيل أصغر": ابن أخ / بنت أخ / ابن أخت / بنت أخت
- Within "جيل الأحفاد": حفيد / حفيدة
- Within "ابن/ة عم أو خال": ابن عم / بنت عم / ابن عمة / بنت عمة / ابن خال / بنت خال / ابن خالة / بنت خالة
- Within "نسيب/ة": حما / حماة / زوج الأخت / زوجة الأخ / زوج الابنة / زوجة الابن
- Within "غير ذلك": free-text input

The **specific role** is what determines the candidate-narrowing graph query. "عم" (paternal uncle) narrows to admin's father's brothers. "ابن خال" narrows to admin's maternal uncles' sons. Each role maps to a deterministic graph traversal.

### Step 3: Candidate display

Given (anchor, role), the app runs a graph query and produces a candidate list. Possible outcomes:

| Candidate count | Behavior |
|---|---|
| 0 | Skip the list. Go straight to the "add me" form, prefilled with the declared relationship. |
| 1 | Show as a confirmation-style card: "نعتقد أنك [name]. هل هذا صحيح؟" with **Yes / No, I'm someone else**. |
| 2–10 | Show the list with the row design below. |
| 11+ | Same list, with a search bar at the top to filter by name. |

**Lean row design.** Each candidate row shows:

```
┌────────────────────────────┐
│ 👤  محمود                   │
│     ابن عبدالله             │
└────────────────────────────┘
```

Avatar (using existing `adult_man` / `adult_woman` types from [relative_model.dart](../../lib/shared/models/relative_model.dart)), name, and parent's name as subtitle. Parent's name is the natural Arabic disambiguator ("Mahmoud son of Abdullah" vs "Mahmoud son of Khalid").

**Tap-to-expand.** Tapping a candidate opens an inline expansion (or bottom sheet) with richer context:

- Parent and second parent if both known
- Sibling names
- Spouse's name
- A 2-hop tree snippet (mini canvas around the candidate)

Two states: scan-mode (fast) and inspect-mode (sure). Scan when it's obvious; inspect when it isn't.

**The escape hatch.** Always visible at the bottom of the candidate list:

> **ما أحد منهم أنا — أضِفني للشجرة**
> *(None of these are me — add me to the tree)*

Tapping it opens a small form:

- Full name (pre-filled from auth name)
- Gender (pre-filled from name inference, editable)
- Optional: birth year, city, photo
- The declared relationship is carried forward — joiner doesn't re-enter "I'm a paternal uncle"

Submit creates a `node_claim` with `claimed_relative_id = NULL` (signaling "create new node") and goes to the admin pending queue.

### Step 4: Admin approval

The trust gate. When a `node_claim` is created (whether for an existing node or for a new node), admin gets a push notification.

**Notification copy** (one line of substance, not generic):

> **عبدالعزيز يقول إنه عمك — اضغط للمراجعة**
> *(Abdulaziz says he's your paternal uncle — tap to review)*

The relationship class is stated up front because that's the first thing admin will mentally verify.

**The review screen** (single focused page, not a modal):

- **Top:** the claim sentence prominently — "عبدالعزيز يدّعي أنه عمك (عم — أخو والدك)"
- **Middle:** a small inline tree snippet showing where the claim places the person — admin's grandfather → admin's dad and the claimant as siblings → admin below as confirmation. One-glance verifiability.
- **Below:** the claimant's signed-up profile — full name, optional photo, optional birth year, optional city. Any extra info from the claim form lives here.
- **Bottom:** two large buttons — **تأكيد** (Confirm) and **رفض** (Reject).

**On reject**, a follow-up asks why with three options:

- خطأ في القرابة (wrong relationship)
- لا أعرف هذا الشخص (I don't know this person)
- لاحقاً (let me think later — delays without rejecting)

Selecting "let me think later" closes the screen without finalizing; the claim stays pending.

**Where claims live in-app** (besides push notifications):

- Existing **family group → الدعوات** tab in [family_group_screen.dart](../../lib/features/family_groups/screens/family_group_screen.dart). Add a badge counter when claims are pending. Same review screen reachable from there.
- **Visual signal on the tree itself.** Nodes with pending claims get a small pulsing orange ring (distinct from the blue "claimed" border which is reserved for confirmed claims). Tapping the node opens the same review screen.

Three entry points (push, group-management tab, inline-on-tree) cover active, deliberate, and contextual modes.

### Step 5: Joiner pending state

While waiting for admin action:

- Joiner is a group member — can browse the tree (read-only mode for sections involving them).
- **Cannot log interactions yet** (no node to attach them to).
- Persistent banner on the home/tree surface: *"في انتظار تأكيد [admin] لمكانك في الشجرة"* with a single button: *إلغاء وإعادة الاختيار* (cancel and re-pick).
- After 48 hours of inaction, the banner adds a quieter secondary option: *"الانضمام بدون مكان محدد"* (join as unlinked member, can be assigned later). Admin still sees the request; joiner isn't permanently stuck.

### Step 6: After action

**Approve →**

- `node_claims.status = 'approved'`
- If `claimed_relative_id` exists: `family_group_members.relative_id_in_tree = claimed_relative_id`. The relative row's `is_claimed_by_user_id = joiner_id` (new column, see Database section).
- If `claimed_relative_id` is NULL: a new `relatives` row is materialized using the form data (name, gender, the inferred position from declared relationship + anchor), and the joiner is linked to it.
- Joiner gets push: *"تم تأكيد مكانك! أنت [role] [admin] في الشجرة"*. Tree goes live. Node visually transitions from stub to claimed (Geni-style blue border).

**Reject →**

- `node_claims.status = 'rejected'` with `rejection_reason`.
- Joiner gets push: *"لم يتم تأكيد مكانك"*. Drops back into the discovery flow at the relationship-class step. Their previous picks are remembered as defaults — they just reconsider. They aren't ejected from the group.

---

## Visual Signals on the Tree

Three node states to render visibly distinct:

| State | Visual | Meaning |
|---|---|---|
| Stub (the default today) | No border decoration | Admin-created node, no real user behind it |
| Pending claim | Pulsing orange ring | A joiner has claimed this node, awaiting admin approval |
| Claimed | Solid blue border (Geni-inspired) | A real user owns this node |

The painter that draws node rings lives in [family_tree_painter.dart](../../lib/features/family_tree/painters/family_tree_painter.dart). Add the two new ring styles as decoration parameters on `LayoutNode`.

---

## Database Changes

### Schema reuse audit (2026-05-08)

Before adding any column or table, verified against canonical schema in [20260427300000_capture_core_tables.sql](../../supabase/migrations/20260427300000_capture_core_tables.sql) and existing migrations. **Several of my v1 proposals were redundant** — corrected here:

- **No new `is_claimed_by_user_id` column.** `relatives.is_self = true` already marks claimed nodes; `relatives.user_id` already transfers to the claimer when [claim_tree_node](../../supabase/migrations/20260209100000_claim_tree_node_rpc.sql) runs. Visual claimed-state driver = `is_self = true`. Index `idx_relatives_self_per_user_group` enforces one self-node per (user, group).
- **No new role taxonomy.** [admin_relationship_labels](../../supabase/migrations/20260204130000_family_sharing.sql#L70) already has `(edge_path, parent_side, gender)` — exact same shape as what I was inventing. `node_claims` stores those three columns directly.
- **No duplicate claim mechanic.** `approve_node_claim` calls the existing `claim_tree_node(group_id, node_id)` RPC for the existing-node path. For the "add me" path it INSERTs the new `relatives` row first, then calls `claim_tree_node` on it.

### New table: `node_claims`

Distinct from `node_invitations` (admin→invitee, phone-keyed). `node_claims` is joiner→admin, role-based, supports both "claim existing node" and "add me to the tree":

```sql
CREATE TABLE node_claims (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
  claimant_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- The node the joiner is claiming. NULL means "I'm not in the tree, add me".
  claimed_relative_id UUID REFERENCES relatives(id) ON DELETE CASCADE,

  -- The declared relationship to the anchor (matches admin_relationship_labels schema).
  declared_anchor_relative_id UUID NOT NULL REFERENCES relatives(id) ON DELETE CASCADE,
  declared_edge_path TEXT NOT NULL,            -- 'parent', 'child', 'spouse', 'sibling',
                                                -- 'grandparent', 'grandchild',
                                                -- 'uncle_aunt', 'nephew_niece', 'cousin'
  declared_parent_side TEXT CHECK (declared_parent_side IN ('paternal', 'maternal')),
  declared_gender TEXT NOT NULL CHECK (declared_gender IN ('male', 'female')),

  -- For "add me" path: the form data (NULL when claiming an existing node).
  proposed_full_name TEXT,
  proposed_gender TEXT CHECK (proposed_gender IN ('male', 'female')),
  proposed_birth_year INT,
  proposed_city TEXT,
  proposed_photo_url TEXT,

  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')),
  rejection_reason TEXT,
  decided_by UUID REFERENCES auth.users(id),
  decided_at TIMESTAMPTZ,
  snoozed_until TIMESTAMPTZ,  -- "let me think later" — claim hidden from admin queue until this passes

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Either claim an existing node OR propose a new one — never both, never neither.
  CONSTRAINT claim_target_consistency CHECK (
    (claimed_relative_id IS NOT NULL AND proposed_full_name IS NULL)
    OR (claimed_relative_id IS NULL AND proposed_full_name IS NOT NULL)
  )
);

-- One pending claim per joiner per group
CREATE UNIQUE INDEX idx_node_claims_one_pending_per_user_per_group
  ON node_claims (group_id, claimant_user_id) WHERE status = 'pending';

CREATE INDEX idx_node_claims_group_pending
  ON node_claims (group_id, status) WHERE status = 'pending';

CREATE INDEX idx_node_claims_claimant
  ON node_claims (claimant_user_id, status);
```

### RLS policies for `node_claims`

```sql
-- Joiner can see their own claims
SELECT: claimant_user_id = auth.uid()

-- Admin can see all claims for groups they admin
SELECT: group_id IN (auth_user_admin_group_ids())

-- Joiner can insert their own claim (must be a group member)
INSERT: claimant_user_id = auth.uid()
        AND group_id IN (auth_user_group_ids())

-- Joiner can cancel their own pending claim
UPDATE: claimant_user_id = auth.uid() AND status = 'pending' AND new.status = 'cancelled'

-- Admin can decide pending claims (via SECURITY DEFINER RPC only)
UPDATE: (via approve_node_claim / reject_node_claim RPCs)
```

### New RPCs

```
create_node_claim(p_group_id, p_claimed_relative_id, p_anchor_relative_id, p_role, p_proposed_*)
approve_node_claim(p_claim_id)
reject_node_claim(p_claim_id, p_reason)
cancel_node_claim(p_claim_id)
get_my_pending_claims()
get_group_pending_claims(p_group_id)
get_candidate_relatives(p_group_id, p_anchor_relative_id, p_role)  -- the graph-query for Step 3
```

`get_candidate_relatives` is the heart of the narrowing logic. Inputs use the existing `(edge_path, parent_side, gender)` taxonomy. Examples:

| Input | Path from anchor |
|---|---|
| `('uncle_aunt', 'paternal', 'male')` → عم | parent (male) → siblings (male) |
| `('uncle_aunt', 'maternal', 'male')` → خال | parent (female) → siblings (male) |
| `('cousin', 'paternal', 'male')` → ابن عم/عمة | parent (male) → siblings → children (male) |
| `('cousin', 'maternal', 'female')` → بنت خال/خالة | parent (female) → siblings → children (female) |
| `('grandparent', 'paternal', 'male')` → جد لأب | parent (male) → parent (male) |
| `('nephew_niece', NULL, 'male')` → ابن أخ/أخت | siblings → children (male) |

The traversal is over `family_edges` (parent_of / sibling_of / spouse_of). Postgres-side execution beats N+1 round trips from Dart. A static lookup function maps `(edge_path, parent_side)` to the traversal sequence.

### Cleanup of dormant `node_invitations`

The 2026-03-08 phone-invite system stays. The column-name bug at [20260308100001_invitation_rpcs.sql:43](../../supabase/migrations/20260308100001_invitation_rpcs.sql#L43) and [line 298](../../supabase/migrations/20260308100001_invitation_rpcs.sql#L298) is real — both reference `r.name` while the canonical column ([20260427300000_capture_core_tables.sql:66](../../supabase/migrations/20260427300000_capture_core_tables.sql#L66)) is `full_name`. Fix migration replaces `r.name` → `r.full_name` in `create_node_invitation` and `get_my_pending_invitations`.

### Existing claim mechanism — REUSED

`approve_node_claim` does not duplicate node-claiming logic. After validation, it:
1. If `claimed_relative_id IS NOT NULL` → calls existing [claim_tree_node](../../supabase/migrations/20260209100000_claim_tree_node_rpc.sql)`(group_id, claimed_relative_id)`.
2. If `claimed_relative_id IS NULL` → INSERT a new `relatives` row using the proposed_* fields and the inferred position from `(declared_anchor_relative_id, declared_edge_path, declared_parent_side)`. Then call `claim_tree_node` on the new row. Then insert the appropriate `family_edges` entries via existing edge inference.

---

## Files Affected

| File | Change |
|---|---|
| [join_group_screen.dart](../../lib/features/family_groups/screens/join_group_screen.dart) | After `joinGroup` succeeds, navigate to new `IdentityClaimWizardScreen` (instead of `familyTree`) when no pending phone-invitation exists. |
| `lib/features/family_groups/screens/identity_claim_wizard_screen.dart` | **New.** The 5-step joiner journey (anchor → category → role → candidates → confirm/add-me). |
| `lib/features/family_groups/screens/admin_review_claim_screen.dart` | **New.** Admin's review screen with claim sentence + tree snippet + profile + approve/reject. |
| [family_group_screen.dart](../../lib/features/family_groups/screens/family_group_screen.dart) | Add badge counter to "الدعوات" tab when pending claims exist. Surface claims list alongside existing invitations. |
| [family_tree_painter.dart](../../lib/features/family_tree/painters/family_tree_painter.dart) | Render pulsing orange ring for nodes with pending claims; solid blue border for claimed nodes. |
| [family_graph_service.dart](../../lib/features/family_tree/services/family_graph_service.dart) | Add `relationshipRoleToTraversal` helper exposing the role → graph-path mapping (for the RPC and any in-Dart fallback). |
| [node_invitation_service.dart](../../lib/features/family_groups/services/node_invitation_service.dart) | Remove the "CUT FROM V1" header. Wire the createInvitation methods to a UI on relative-detail screen. |
| [relative_detail_screen.dart](../../lib/features/relatives/screens/relative_detail_screen.dart) | Add "ادعُ هذا الفرد" CTA when relative has a phone, else show "أضف رقم" prompt. |
| `lib/features/family_groups/services/node_claim_service.dart` | **New.** Wraps the new RPCs. |
| `lib/features/family_groups/providers/node_claim_providers.dart` | **New.** Riverpod providers for joiner's pending claim, group's pending claims. |
| New migrations | `node_claims` table, `relatives.is_claimed_by_user_id` column, RPCs. |
| Push notifications | Two new templates: claim-arrived (admin-side), claim-decided (joiner-side). |

## Notification Templates

```
admin claim_arrived:
  title: "[claimant first name] يطلب الانضمام لشجرتك"
  body: "[claimant] يقول إنه [role] [admin] — اضغط للمراجعة"
  data: { claim_id, group_id }
  on_tap: open admin_review_claim_screen

joiner claim_approved:
  title: "تم تأكيد مكانك في الشجرة!"
  body: "أنت [role] [admin]. شجرة العائلة جاهزة"
  on_tap: open family_tree

joiner claim_rejected:
  title: "لم يتم تأكيد مكانك"
  body: "[admin] طلب اختيار قرابة مختلفة"
  on_tap: open identity_claim_wizard_screen at relationship-class step
```

---

## Security Considerations

| Threat | Mitigation |
|---|---|
| Anyone with public link claims to be the patriarch | Admin approval required for every claim. No auto-link. |
| Admin spammed with bulk claims by malicious joiners | Two layers: (a) DB exclusion constraint — one pending claim per joiner per group (stops re-spamming the same group); (b) RPC-enforced cap — max 3 active pending claims per joiner across all groups (stops fan-out across many groups). |
| Claim race: two joiners both claim the same node | First claim wins. Second sees `claimed_relative_id` already has a pending or approved claim → forced to "add me" path or different anchor. |
| Joiner harvests tree data, then cancels | Joiner has group-member access while pending — same view they'd have as a regular linked member. Group admins should treat membership-via-public-link as the access boundary, not the claim approval. (Same threat model as the existing public link.) |
| Admin transfer mid-claim | Pending claims stay attached to the group, not the admin user. New admin sees the queue on next open. |
| Phone-fast-path link forwarded | Phone OTP verification at signup gates this — only the verified phone owner can accept. (Same as the 2026-03-08 plan.) |

---

## What This Replaces / Restores / Adds

**Replaces**
- The dead-end "unlinked member" outcome that every public-link joiner currently hits.
- The single hidden entry point for "claim a node" (none existed in v1 for self-claim).

**Restores**
- The phone-OTP node-targeted invitation system from the 2026-03-08 plan, with the column-name bug fixed and a real admin UI.

**Adds**
- The discovery flow (anchor → relationship → candidates → claim or add-me).
- The pending-claim state for joiners.
- Visual signals on the tree (pulsing orange for pending, blue border for claimed).
- Admin's claim-review screen and inline-on-tree access to it.
- The `node_claims` table and its RPCs.
- The `is_claimed_by_user_id` column on `relatives`.

**Preserved (no change)**
- `leave_group_atomic` — joiner can always exit.
- `family_group_id` on relatives — group → tree is unchanged.
- The 3-step group creation flow at [create_group_screen.dart](../../lib/features/family_groups/screens/create_group_screen.dart).

---

## Open Questions for Implementation Planning

These don't block design approval but should be resolved before code:

1. **Does `get_candidate_relatives` execute in Postgres or Dart?** Postgres-side avoids round trips; Dart-side reuses existing `family_graph_service` traversal logic. Recommend Postgres but with a Dart fallback for unit testability.
2. **Caching of candidate lookups.** Tree changes are infrequent — a 60-second TTL on candidate-list responses is probably fine. Decide during implementation.
3. **Should the "let me think later" rejection state persist longer than the pending claim itself?** Probably yes — admin shouldn't see the same claim re-promoted on every app open. Add a `snoozed_until` timestamp.
4. **Push notification handler for app-cold-start.** When the admin's device is fully closed and the push lands, FCM payload should carry enough data to deep-link directly to the review screen without a server round trip.

---

End of design.
