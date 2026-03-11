# Family Group Creation & Phone-Based Invitation Redesign

**Date:** 2026-03-08
**Status:** Approved

## Problem Statement

The current family group system has critical UX and security flaws:

1. **Silent group creation** — groups are auto-created when a user taps "invite" on a relative, with no awareness or consent
2. **Zero discoverability** — `CreateGroupScreen` exists but no UI navigates to it. Groups are invisible in onboarding, home, settings, and family tree
3. **Link-as-identity is fragile** — invite links with `?rid=` expose relative UUIDs publicly and anyone who clicks the link can join and claim nodes
4. **No invitation lifecycle** — single `invite_code` per group, no expiration, no per-person tracking, no approval flow
5. **Abrupt joiner experience** — auto-claims node silently, lands on tree with no context
6. **Unprofessional domain** — `silni-31811.web.app` used for deep links instead of `silniapp.com`

## Design Decisions (from brainstorming)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Group creation trigger | Explicit, user-initiated | User must understand what sharing means |
| Relative migration | All relatives, with visible summary + confirm | No friction, but user is aware |
| Invitation mechanism | Phone number as key, verified via OTP | Phone ownership = identity |
| Targeted invite without phone | Blocked — admin must add phone first | Phone is the security gate |
| Public link | Kept as secondary fallback | Broad sharing + phone auto-match |
| "This isn't me" on targeted invite | N/A — targeted invites use phone matching, not links | No data exposure risk |
| Group creation entry point | Family tree screen | Where the mental model lives |
| Invitation management | Badge on relative detail + dedicated tab in group management | Quick glance + full control |
| OTP retry limit | Supabase built-in (3 attempts + cooldown) | Standard, no custom logic needed |
| Nudge link on invite | Share sheet with download link + personal message | Admin feels they "sent" something |
| Invite notification UX | Glowing animated bell in notification center | Differentiates from normal notifications |
| Domain | `silniapp.com` | Professional, owned domain |

## Architecture Overview

Three pillars:

1. **Explicit Group Creation** — user-initiated from family tree screen
2. **Phone-Number Invitations** — phone number is the invitation key, verified via OTP
3. **Public Link Fallback** — secondary path for broad sharing with phone auto-match

---

## Pillar 1: Explicit Group Creation

### Entry Point

Family tree screen shows a prominent "شارك شجرتك" (Share your tree) button when the user has no group. Once a group exists, this becomes the group name header (tappable to group management).

### Flow

1. User taps "Share your tree" on family tree screen
2. **Step 1 — Name:** "سمّ مجموعتك العائلية" with auto-filled suggestion ("عائلة [name]"), editable
3. **Step 2 — Review:** "سيتم مشاركة [X] من أقاربك مع أفراد العائلة الذين ينضمون" — scrollable summary of all relative names. Confirm button.
4. **Step 3 — Done:** Group created. All relatives migrated. Screen shows:
   - Success state with group name
   - "Invite family members" CTA → navigates to group management
5. Family tree header now shows group name (tappable → group management)

### What Changes

- `CreateGroupScreen` becomes reachable from family tree screen
- Silent auto-creation in `relative_detail_screen.dart` is **removed**
- "Invite" button on relative detail only appears if user already has a group
- If no group → tapping invite shows: "Create a family group first" → navigates to creation flow

---

## Pillar 2: Phone-Number-Based Invitations

### Prerequisite

Phone OTP authentication added to Supabase Auth. Users register/verify their phone number on signup or via profile settings.

### Admin Invites a Specific Node

1. Admin opens relative detail screen for "محمود"
2. **Phone gate:** Relative MUST have a phone number stored. If not → "أضف رقم محمود للجوال لدعوته" prompt with inline add action
3. Admin taps "ادعُه لصِلني"
4. System creates invitation record in `node_invitations` table
5. Share sheet opens with nudge message:
   - "أضفتك في شجرة عائلتنا على صِلني 🌳 حمّل التطبيق: https://silniapp.com/download"
   - This link is for download only — carries no join authority
6. Relative detail screen shows badge: "دعوة معلقة" (Pending invite)

### Invitee Receives and Joins

1. محمود downloads the app (or already has it)
2. Registers/logs in with phone number `+966512341234` (verified via OTP)
3. On login, system queries `node_invitations` WHERE `phone_number` matches AND `status = 'pending'`
4. Match found → notification center shows invitation:
   - **Bell icon glows and animates** with distinct visual treatment (not a normal notification)
   - Card: "أحمد دعاك للانضمام إلى عائلة الأحمد"
5. محمود taps → **Invitation detail screen:**
   - Group name: "عائلة الأحمد"
   - "ستنضم كـ **محمود (ابن)**"
   - Mini visual tree preview showing their position
   - "قبول" (Accept) / "رفض" (Decline) buttons
6. Accept → node claimed → `node_invitations.status = 'accepted'` → lands on family tree with welcome context
7. Admin notified: "انضم محمود لشجرة العائلة!"

### If Phone Doesn't Match

Nothing happens. User never sees the invitation. No family data exposed.

### Invitation Management (Admin)

**On relative detail screen:**
- Status badge per node: "No invite" / "Pending" / "Joined"
- Tap to resend nudge or cancel invitation

**In group management screen — "Invitations" tab:**
- All invitations listed with status (pending / accepted / cancelled)
- Actions: resend nudge, cancel invitation
- Filterable by status
- Shows: relative name, phone hint (last 4 digits), status, date sent

---

## Pillar 3: Public Link Fallback

### Purpose

For when the admin wants to share broadly (family WhatsApp group) without inviting each person individually.

### Admin Side

1. Group management screen has "Public invite link" section
2. Uses existing `family_groups.invite_code`
3. Link: `https://silniapp.com/join/{code}` (no `?rid=`)
4. Admin shares: "Join our family on Silni!"

### Joiner Side

1. Clicks link → opens app (or App Store → app)
2. Registers with phone number (OTP verified)
3. System checks: does this phone match any relative node in the group?
   - **YES** → notification appears with the match, same accept flow as targeted invite
   - **NO** → joins as **unlinked member**
4. Unlinked members:
   - Can see the shared tree (they're a group member)
   - Have no node assigned
   - Admin sees them as "unlinked" in members list and can assign a node later

---

## Domain Migration

### Old → New

`silni-31811.web.app` → `silniapp.com`

### Links

- Public invite: `https://silniapp.com/join/{code}`
- Download nudge: `https://silniapp.com/download`
- No more `?rid=` parameter in URLs

### Files to Update

| File | Change |
|------|--------|
| `lib/features/family_groups/services/family_group_service.dart:51` | `webDomain` → `silniapp.com` |
| `lib/core/router/app_router.dart:76` | Deep link parsing for `silniapp.com` |
| `android/app/src/main/AndroidManifest.xml:47` | Intent filter host → `silniapp.com` |
| `ios/Runner/Runner.entitlements:19` | Associated domains → `applinks:silniapp.com` |
| `ios/Runner/RunnerRelease.entitlements:19` | Same |
| Test files (2) | Update expected URLs |

### New Pages on `silniapp.com`

- `/join/{code}` — landing page: group name, app store badges, "Open in app" smart banner
- `/.well-known/apple-app-site-association` — iOS universal links
- `/.well-known/assetlinks.json` — Android App Links verification
- `/download` — redirect to appropriate app store

### Removed

- Firebase Hosting dependency for deep links (`silni-31811.web.app` no longer serves invite links)
- Firebase project itself stays for other services (analytics, storage, etc.)

---

## Database Changes

### New Table: `node_invitations`

```sql
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

-- Fast lookup on login: "any pending invitations for this phone?"
CREATE INDEX idx_node_invitations_phone_status
  ON node_invitations(phone_number, status) WHERE status = 'pending';

-- One pending invite per node at a time
CREATE UNIQUE INDEX idx_node_invitations_unique_pending
  ON node_invitations(group_id, relative_id) WHERE status = 'pending';

-- Admin's invitation list per group
CREATE INDEX idx_node_invitations_group
  ON node_invitations(group_id, status);
```

### RLS Policies for `node_invitations`

```sql
-- Admin can see all invitations for their group
SELECT: group_id IN (auth_user_admin_group_ids())

-- Admin can insert invitations for their group
INSERT: group_id IN (auth_user_admin_group_ids()) AND invited_by = auth.uid()

-- Admin can cancel invitations; invitee can accept (via RPC)
UPDATE: (via SECURITY DEFINER RPCs only)

-- Admin can delete cancelled invitations
DELETE: group_id IN (auth_user_admin_group_ids())
```

### New RPCs (SECURITY DEFINER)

```sql
-- Create an invitation (admin only)
create_node_invitation(p_group_id UUID, p_relative_id UUID, p_phone TEXT)
  -- Validates: caller is admin, relative belongs to group, relative has no pending invite
  -- Normalizes phone number
  -- Inserts into node_invitations
  -- Returns invitation record

-- Accept an invitation (invitee)
accept_node_invitation(p_invitation_id UUID)
  -- Validates: caller's verified phone matches invitation phone
  -- Validates: invitation is still pending
  -- Validates: node not already claimed
  -- Claims the node (same as claim_tree_node logic)
  -- Updates invitation status to 'accepted'
  -- Returns group data

-- Cancel an invitation (admin)
cancel_node_invitation(p_invitation_id UUID)
  -- Validates: caller is admin of the group
  -- Updates status to 'cancelled'

-- Check pending invitations for current user's phone (called on login)
get_my_pending_invitations()
  -- Gets caller's verified phone from auth.users
  -- Returns all pending invitations matching that phone
  -- Joins with family_groups and relatives for display data
```

### Auth Changes

- Enable phone OTP in Supabase Auth
- Users must verify phone number (on signup or via profile)
- Verified phone stored on `auth.users.phone`

---

## What Gets Removed

| Component | Reason |
|-----------|--------|
| Silent group creation in `relative_detail_screen.dart` | Replaced by explicit creation flow |
| `?rid=` query parameter on invite links | Replaced by phone-number matching |
| Auto-match-by-name logic in `joinGroup()` | Replaced by phone-number matching |
| `_createJoinerSelfNode()` auto-creation | Unlinked members stay unlinked until admin assigns |
| `FamilySharingService.generateInviteLink(inviteCode, relativeId)` | No more per-node links |
| `silni-31811.web.app` deep link handling | Replaced by `silniapp.com` |

## What's Preserved

| Component | Usage |
|-----------|-------|
| `family_groups.invite_code` | Still used for public links |
| `FamilySharingService.initializeSharedTree()` | Still handles group creation + migration |
| `claim_tree_node()` RPC | Still used when invitation is accepted |
| `verifySharedEdges()` | Still called after node claiming |
| `InviteLinkCard` widget | Repurposed for public link in group management |
| `FamilyGroupScreen` | Enhanced with Invitations tab |
| `JoinGroupScreen` | Simplified for public-link-only flow |

---

## Screen Inventory

| Screen | Status | Purpose |
|--------|--------|---------|
| Family Tree Screen | **Modified** | "Share your tree" CTA when no group; group header when has group |
| Create Group Screen | **Modified** | 3-step explicit flow, reachable from tree screen |
| Relative Detail Screen | **Modified** | Invite button with phone gate + invitation status badge |
| Invitation Detail Screen | **New** | "Join as محمود" with tree preview, accept/decline |
| Notification Center | **Modified** | Glowing animated bell for invitations, invitation cards |
| Group Management Screen | **Modified** | New "Invitations" tab with full lifecycle management |
| Join Group Screen | **Modified** | Public link only, simplified, no `?rid=` handling |
| `silniapp.com/join/{code}` | **New** | Web landing page for public links with app store badges |

---

## Notification UX

### Invitation Notification (Special Treatment)

- Bell icon in app header **glows and pulses** when there's a pending invitation
- Distinct from normal notification dot/badge
- Inside notification center, invitation cards have:
  - Premium visual treatment (gradient border, family icon)
  - Group name and inviter name
  - "View invitation" CTA
  - Clearly distinct from regular notifications (reminders, streak alerts, etc.)

### Admin Notifications

- "محمود accepted your invitation and joined عائلة الأحمد" — standard notification
- "Invitation to محمود has been pending for 7 days" — optional reminder

---

## Security Model

| Threat | Mitigation |
|--------|-----------|
| Leaked nudge link (download link) | Link has no join authority — just opens app store |
| Leaked public group link | Joiner can only see tree after joining + phone verified. No node auto-claim without phone match |
| Registering with someone else's phone | OTP verification prevents this |
| Brute force OTP | Supabase built-in rate limiting (3 attempts + cooldown) |
| Admin invites wrong number | Admin can cancel from invitation management |
| Phone number exposure in URLs | No phone numbers in any URLs. Phone matching happens server-side |
| Probing invite codes | `lookup_group_by_invite_code` returns minimal info (group name only) |
| Data exposure to unlinked members | Unlinked members can see tree (admin shared the public link intentionally) but cannot claim nodes without admin action |
