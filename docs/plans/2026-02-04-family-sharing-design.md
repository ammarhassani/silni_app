# Family Sharing — Shared Trees with Perspective Shifting

**Date:** 2026-02-04
**Status:** Draft
**Scope:** End-to-end family tree sharing — invite flow, shared data, perspective-aware labels, collaborative adding, activity feed

---

## Core Idea

A user invites a family member to Silni. That person joins, inherits the entire family tree, and sees it from their own perspective. Mom sees herself at the center — her children, her husband, her parents — not "ابني's أم."

One tree. Many perspectives. Zero setup for the person joining.

---

## What Exists Today

The following infrastructure is already built and production-ready:

- **Family groups**: create, join via invite code, membership management, leave/delete
- **Database**: `family_groups`, `family_group_members` tables with RLS and secure RPC (`lookup_group_by_invite_code`)
- **Shared relatives**: `family_group_id` and `added_by` fields on `relatives` table
- **SharedTreeService**: add, get, watch shared relatives (real-time stream)
- **Screens**: CreateGroupScreen, JoinGroupScreen, FamilyGroupScreen
- **Invite links**: WhatsApp sharing with deep link (`https://silni.app/join/{code}`)
- **Weekly leaderboard**: ranked by interactions per member (Sat–Fri, Saudi timezone)
- **Family graph**: `family_edges` table with `parent_of`, `spouse_of`, `sibling_of` edge types
- **FamilyGraphService**: builds adjacency graph from edges, computes generations

**What's missing:** no entry point from the tree or relative profiles, no auto-group creation, no perspective-shifting labels, no edge inference from existing relationships, no join-notification, no activity feed.

---

## Part 1: Editable Family Name on Tree Screen

The family tree screen top bar currently shows "شجرة العائلة." This becomes an editable family name.

- Tap the title → inline edit field
- User types "عائلة الغامدي" → saved to their profile (`family_name` column on `profiles` table)
- Default: "شجرة العائلة" until set
- When a family group is created, this name is used automatically
- After group creation, the name is stored on the `family_groups.name` field and stays editable by the admin member

---

## Part 2: The Invite Flow

### Entry Points

1. **Relative profile**: "ادعيه/ها لصِلني" button on any relative's detail screen
2. **Family tree screen**: share/invite button in the app bar

### What Happens on First Invite

1. Check if user already has a family group — if yes, skip to step 5
2. Create a `family_group` with the name from the tree bar (or "عائلتي" as fallback)
3. Add the user as admin member
4. Create a **self node** — a relative record representing the user themselves in the tree (needed so edges can reference the user's position)
5. Migrate all personal relatives: set `family_group_id` on every relative owned by this user
6. **Generate graph edges** from existing `relationshipType` values (see Part 4)
7. Generate invite link tied to this family group
8. Open WhatsApp share with: "انضم/ي لعائلتنا في صِلني 🌳 {link}"

### Subsequent Invites

Steps 1–6 already done. Jump straight to generating the invite link and sharing.

---

## Part 3: The Join Flow

When the invited person taps the link:

1. Deep link routes to `/join-family-group/:code` (already implemented)
2. If not logged in → redirect to auth, then back to join screen (already implemented)
3. JoinGroupScreen shows: "انضم/ي ل{familyName} 🌳" with a preview
4. User taps join → added as member to the group
5. **Link to tree node**: the invited person gets linked to their `relative_id_in_tree` — the node that represents them in the shared tree
6. App navigates to the family tree → rendered from THEIR perspective

### Linking to the Correct Node

The invite link needs to encode which relative node this person corresponds to. Two approaches:

- **Option A (recommended):** The invite is sent from a specific relative's profile. Store `target_relative_id` in the invite metadata. When the person joins, auto-set `relative_id_in_tree = target_relative_id`.
- **Option B:** After joining, show a picker: "أنت مين في الشجرة؟" with the unlinked nodes.

We use Option A. The invite carries the node identity. Zero friction for the joiner.

**Implementation:** Add `target_relative_id` column to `family_group_members` (nullable, set during invite creation) or encode it in the invite link URL as a query param.

---

## Part 4: The Perspective Engine

### Graph Edges as Source of Truth

Three edge types cover all family relationships:

| Edge Type | Meaning | Directionality |
|-----------|---------|----------------|
| `parent_of` | A is parent of B | Directional (A → B) |
| `spouse_of` | A and B are married | Bidirectional |
| `sibling_of` | A and B are siblings | Bidirectional |

### Edge Inference from Existing Relationships

When migrating personal relatives to a shared tree, infer edges from `relationshipType`:

| relationshipType | Inferred Edge |
|-----------------|---------------|
| `mother` / `father` | relative_node `parent_of` self_node |
| `son` / `daughter` | self_node `parent_of` relative_node |
| `brother` / `sister` | self_node `sibling_of` relative_node |
| `husband` / `wife` | self_node `spouse_of` relative_node |
| `grandfather` / `grandmother` | relative_node `parent_of` parent_node (if parent exists) |
| `uncle` (paternal) | father_node `sibling_of` relative_node |
| `uncle` (maternal) | mother_node `sibling_of` relative_node |
| `aunt` (paternal) | father_node `sibling_of` relative_node |
| `aunt` (maternal) | mother_node `sibling_of` relative_node |
| `cousin` | uncle/aunt_node `parent_of` relative_node (if uncle/aunt exists) |
| `nephew` / `niece` | sibling_node `parent_of` relative_node (if sibling exists) |

Edges that can't be inferred (missing intermediate nodes) are skipped — they'll be added when more relatives join.

### Label Computation

Given viewer V and target T, traverse the graph to find the relationship path:

**Direct relationships (1 hop):**
- T `parent_of` V → T is V's parent → "أبوي" / "أمي" (by gender)
- V `parent_of` T → T is V's child → "ابني" / "بنتي"
- V `spouse_of` T → "زوجي" / "زوجتي"
- V `sibling_of` T → "أخوي" / "أختي"

**Two hops:**
- T `parent_of` X, X `parent_of` V → T is grandparent → "جدي" / "جدتي"
- V `parent_of` X, X `parent_of` T → T is grandchild → "حفيدي" / "حفيدتي"
- T `parent_of` V, T `parent_of` X (where X ≠ V) → X is sibling → (covered by sibling_of)
- V's parent `sibling_of` T → T is uncle/aunt → "عمي" / "خالي" / "عمتي" / "خالتي" (depends on which parent)
- V `sibling_of` X, X `parent_of` T → T is nephew/niece → "ابن أخوي" / "بنت أختي" etc.

**Three hops:**
- V's parent's sibling's child → cousin → "ابن عمي" / "بنت خالتي" etc.

### Label Mapping Table (Admin-Panelized)

Store label mappings in `admin_relationship_labels`:

```
edge_path           | gender | label_ar
parent              | male   | أبوي
parent              | female | أمي
child               | male   | ابني
child               | female | بنتي
spouse              | male   | زوجي
spouse              | female | زوجتي
sibling             | male   | أخوي
sibling             | female | أختي
parent.parent       | male   | جدي
parent.parent       | female | جدتي
parent.sibling      | male   | عمي / خالي
parent.sibling      | female | عمتي / خالتي
sibling.child       | male   | ابن أخوي / ابن أختي
sibling.child       | female | بنت أخوي / بنت أختي
parent.sibling.child| male   | ابن عمي / ابن خالي
parent.sibling.child| female | بنت عمي / بنت خالتي
self                | any    | أنا
```

Note: uncle/aunt labels differ by whether the connecting parent is father (عم/عمة) or mother (خال/خالة). The engine checks which parent node is in the path.

---

## Part 5: Self Node

Today, the user is implicit — they don't have a node in their own tree. For shared trees, the user needs a node so that:

- Edges can reference their position
- Other members can see them in the tree
- The perspective engine has a starting point for traversal

### Implementation

- When the family group is created, insert a relative record for the user:
  - `full_name`: user's display name from profile
  - `family_group_id`: the new group
  - `added_by`: the user themselves
  - `is_self`: true (new boolean column, default false)
- This node is the anchor for all edge inference
- In the tree visualization, this node renders as "أنا" for the viewer, or the person's name for other members

---

## Part 6: Individual Streaks Per Member

Each member has their own interaction history with shared relatives. The `interactions` table already has `user_id` — no schema change needed.

- When mom joins, she starts with zero streaks — her interactions are hers
- Your streaks stay yours, unaffected
- The tree can optionally show YOUR streak with each relative on the nodes
- The leaderboard (already built) compares members' weekly activity

---

## Part 7: Collaborative Adding

Any group member can add a relative to the shared tree.

- New relative gets `family_group_id` set to the group + `added_by` set to the member
- The adder specifies the relationship FROM THEIR PERSPECTIVE — the app creates the correct edges
  - Mom adds her sister → mom selects "أختي" → edge: mom_node `sibling_of` new_node
  - The system computes: for the original user, this is "خالتي" (mom's sister = maternal aunt)
- The tree updates in real-time via the existing `watchSharedRelatives` stream
- All members see the new relative with perspective-correct labels

---

## Part 8: Join Notifications

When someone joins the family group, all existing members get a push notification.

- Template stored in `admin_notification_templates` (category: `family`)
- Example: "أمك انضمت لعائلة الغامدي 🌳"
- Variables: `{{member_name}}`, `{{family_name}}`, `{{relationship_label}}`
- The relationship label is computed from the RECEIVER's perspective
- Triggered by the join-group flow (edge function or database trigger)

---

## Part 9: Family Activity Feed

Privacy-first. Members see THAT connection is happening, not what was said.

Shown as a section on the family group screen:

- Individual indicators: "أمك عندها سلسلة ١٤ يوم مع جدتك"
- Collective stats: "عائلة الغامدي تواصلوا ٤٧ مرة هالشهر"
- Milestone celebrations: "أبوك وصل سلسلة ٣٠ يوم! 🔥"

### Admin Configuration

- Which activity types to show (streak milestones, interaction counts, collective stats)
- Activity feed templates stored in `admin_notification_templates` (category: `family_activity`)
- Variables: `{{member_name}}`, `{{relative_name}}`, `{{streak}}`, `{{count}}`, `{{family_name}}`

### Privacy Rules

- Show interaction counts, not content
- Show streak existence, not interaction details
- No notes, no timestamps of individual interactions
- Members can opt out of the activity feed (privacy toggle in settings)

---

## Database Changes

### New Columns

```sql
-- profiles table
ALTER TABLE profiles ADD COLUMN family_name TEXT;

-- relatives table
ALTER TABLE relatives ADD COLUMN is_self BOOLEAN DEFAULT false;

-- family_group_members table (if not already there)
-- target_relative_id links the invite to a specific node
ALTER TABLE family_group_members ADD COLUMN target_relative_id UUID REFERENCES relatives(id);
```

### New Admin Table

```sql
CREATE TABLE admin_relationship_labels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  edge_path TEXT NOT NULL,          -- e.g., 'parent', 'parent.sibling', 'parent.sibling.child'
  parent_side TEXT,                  -- 'paternal', 'maternal', or NULL
  gender TEXT NOT NULL,              -- 'male', 'female'
  label_ar TEXT NOT NULL,            -- Arabic label
  label_en TEXT,                     -- English label (optional)
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(edge_path, parent_side, gender)
);
```

### Seed Data

Pre-populate with all standard Arabic relationship labels (~30 rows covering direct family, extended family, and in-laws).

---

## What We're NOT Building

- Permission levels for collaborative adding (any member can add for now)
- Merge/deduplication when two members add the same person
- Group admin transfer
- Multiple family groups per user
- In-law relationship edges (future: `in_law_of`)

---

## Success Criteria

1. User can set family name on tree screen
2. User can invite a relative from their profile
3. Family group auto-created on first invite
4. Invited person joins via WhatsApp link with zero setup
5. Invited person sees the tree from their own perspective
6. Any member can add relatives, visible to all with correct labels
7. Push notification sent when someone joins
8. Family activity feed shows on group screen
9. All label text is admin-panelized, not hardcoded
10. Deployed to production, verified on two devices (inviter + joiner)
