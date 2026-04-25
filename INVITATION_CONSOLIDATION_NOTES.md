# Invitation Consolidation — Halted, Awaiting CTO Decision

**Status:** Phase 2 Task 2 STOPPED at step 2 (the explicit STOP gate). No code or schema changes made for this task. Tasks 1, Cleanup 4 are committed; Tasks 3, 4 are separately scoped in PHASE_2_REPORT.md.

**The plan's premise:**
> "Confirm node invitations cover the create-and-share-link case (currently handled by group codes). If they don't, STOP and write the gap into INVITATION_CONSOLIDATION_NOTES.md for the CTO. Do NOT improvise."

After reading the code, **the premise is false.** The two systems serve different UX flows and are not interchangeable. Below is the analysis.

## 1. What each system actually does

### Group invite codes (target of the deletion)

- 12-char hex code is generated when a group is created (`family_groups.invite_code`).
- The code is **untargeted** — anyone holding it can call `join_group_by_invite_code(code)` and become a `family_group_members` row with `relative_id_in_tree = NULL`.
- The code can be rotated by the admin via `rotate_invite_code` to invalidate the old code.
- Used to build a deep link: `https://silniapp.com/join/<CODE>` (see `family_group_service.dart:54`).
- Joiner becomes a member but is **not assigned to any tree node** yet — they're a "ghost member" until the admin sends them a node invitation.

**Use case:** "I want to drop this link in my family's WhatsApp group and have everyone who clicks it land in my family group."

### Node invitations (the survivor)

- Created by the admin via `create_node_invitation(group_id, relative_id, phone)` — per `20260308100001_invitation_rpcs.sql`.
- **Targeted by phone number.** The phone is normalized (whitespace stripped, `+` prefix enforced, length 8–16) and stored on the `node_invitations` row.
- `accept_node_invitation` requires that `auth.users.phone == invitation.phone_number` (after normalization). The verified phone of the accepting user must match the invitation's targeted phone.
- One invitation per node max (uniqueness check), and the node must not already be claimed.
- Acceptance does two things: (a) inserts/updates membership with `relative_id_in_tree = invitation.relative_id`, (b) marks the relative row as `is_self = true` and reassigns its `user_id` to the accepter.

**Use case:** "I, the admin, am telling cousin Ahmed at +9665xxxxxx that the node labeled 'أحمد' in this shared tree is him. When Ahmed signs up and verifies that phone number, he'll see my pending invitation and can accept it to claim that node."

## 2. The gap

| Capability | Group codes | Node invitations |
|---|---|---|
| Untargeted share link (admin doesn't pre-know who'll join) | ✅ | ❌ — phone must be known up-front |
| Anyone-with-link can join | ✅ | ❌ — phone match required at acceptance |
| Auto-assign joiner to a specific node | ❌ — joins as `relative_id_in_tree = NULL` | ✅ |
| Multiple people can use same invite | ✅ | ❌ — one-shot per node, status flips to `accepted` |
| Works without phone verification | ✅ | ❌ — `accept_node_invitation` raises if `auth.users.phone` is NULL |

There is no flow in the current codebase that lets the admin issue a generic, multi-use, untargeted share link backed by node invitations. To replicate it via node invitations would require:

- Pre-creating tree nodes for every person the admin expects to join (impractical — many families don't yet know their tree shape).
- Knowing each person's phone in advance (impractical — that's exactly what the share-link is meant to avoid).
- A new RPC/state for "anyone-can-claim" node invitations that doesn't gate on a phone match (a NEW system, not a consolidation of existing ones).

## 3. What deleting group codes would break

Code paths that read or generate `family_groups.invite_code`:

- `lib/features/family_groups/services/family_group_service.dart`
  - `createGroup` returns `FamilyGroup` whose model includes `inviteCode`
  - `generateInviteLink` uses it to build the share URL
  - `joinGroup` calls `join_group_by_invite_code` RPC
  - `lookupGroupByInviteCode` calls `lookup_group_by_invite_code` RPC
  - `rotateInviteCode` calls `rotate_invite_code` RPC
- `lib/features/family_groups/screens/join_group_screen.dart` — reads the code from the deep-link path
- `lib/features/family_groups/screens/family_group_screen.dart` — admin-side display of the current code
- `lib/features/family_groups/widgets/invite_link_card.dart` — UI for copying / sharing the link
- `lib/features/family_groups/models/family_group_model.dart` — `inviteCode` field
- `lib/core/router/app_router.dart` — `/join/:code` deep-link route

Migration files referencing the column or the rotation/lookup RPCs:
- `20260201150000_family_groups.sql` (column definition)
- `20260207100000_family_sharing_hardening.sql`
- `20260207110000_fix_rotate_invite_code.sql`
- `20260207120000_critical_security_fixes.sql`

Dropping the column without a replacement for the share-link flow means:
1. Existing share links in the wild (in WhatsApp histories, emails, screenshots) become permanently dead. Anyone who hasn't accepted yet cannot join.
2. The "I want to invite anyone" flow has no in-app analog — admins can only invite by phone, one node at a time.
3. Existing `family_groups.invite_code` data is destroyed (irreversible without a backup).

## 4. Possible paths forward (CTO chooses)

### Path A — Keep both systems
Acknowledge the plan was wrong on this point and leave the invitation system as it is. Group codes for discovery, node invitations for assignment. The two-step UX (join via code → admin sends node invitation → accept node) is awkward but works.

**Cost:** Zero. **Risk:** Zero. **Trade-off:** The original plan's "consolidation" goal is dropped.

### Path B — Augment node invitations with an "anyone-can-claim" mode
Add a new column `node_invitations.allow_any_claimant BOOLEAN DEFAULT false`. When true, `accept_node_invitation` skips the phone check. Generate share links of the form `https://silniapp.com/claim/<invitation_id>`. Group codes get deleted; the new claim flow replaces them.

**Cost:** New schema column, new RPC behavior, new screen, migration to convert existing group-code links into per-node claim links (ambiguous because group codes don't map to a specific node). **Risk:** Medium-high. Untargeted node claims open new race conditions and security concerns.

**This is a NEW feature, not a consolidation.** It is also explicitly out of scope per CTO standing order #5 ("No new features").

### Path C — Replace group codes with a "group-level claim link" that's separate from node invitations
Keep node invitations as-is for targeted assignment. Replace `family_groups.invite_code` with a new `family_groups.share_token` that's the same idea but with a cleaner name and rotation story. This is essentially renaming the existing system, not consolidating.

**Cost:** Migration churn for no behavioral change. **Risk:** Low. **Trade-off:** Doesn't actually consolidate anything.

### Path D — Delete group codes, accept the regression
Drop the column, delete the screens that show/copy the code, accept that admins can only invite by phone going forward. Existing wild links die.

**Cost:** Significant UX regression. **Risk:** Low technically; high from a user perspective. Some users may not know everyone's phone.

## 5. My recommendation

**Path A.** The original plan was based on a misreading of how the two systems relate. Group codes solve "wide-net invite by share link"; node invitations solve "precise node assignment by phone." Both are necessary for the current UX. Consolidation here means *removing functionality the user has*, which violates the standing order against new feature work and creates real UX regressions.

If the CTO wants to reduce surface area, the most defensible move is to keep group codes alive and tighten Phase 3's settings/group-management UX so it's clearer to users when each system applies — but that's a UX clarity task, not a schema consolidation.

## 6. What I did NOT do

- No edits to `family_group_service.dart`.
- No new migration was written.
- No deletions of `lookup_group_by_invite_code` or `rotate_invite_code` RPCs.
- No edits to `join_group_screen.dart`, `family_group_screen.dart`, or `invite_link_card.dart`.
- No changes to `family_group_model.dart`.

The repo is in the same state on the invitation system as it was at the start of Phase 2.

Awaiting CTO decision before resuming Task 2.
