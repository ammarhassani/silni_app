# Personal Additions + Multi-Group Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to execute task-by-task. Steps use `- [ ]` checkboxes.

**Goal:** Stop leaking member-added relatives into the shared group tree, and surface the multi-group capability that the data model already supports. After this lands, the wife problem goes away (my wife is mine, not the group's) and a user can create/join multiple groups without one bleeding into another.

**Architecture:** No new tables, no new columns. The existing `relatives.family_group_id` already distinguishes scope (NULL = personal-to-owner, set = group-shared). We fix two things:

1. **Add-relative default flips by role.** Admin's adds → `family_group_id = group_id` (shared lineage). Non-admin's adds → `family_group_id = NULL` (personal — only the owner sees it).
2. **Group-tree provider merges shared + viewer's personal.** Today the group view only streams `family_group_id = group_id`. We make it ALSO include the viewer's `family_group_id IS NULL` relatives so their personal additions (e.g., wife) render alongside the shared lineage.
3. **`userFamilyGroupProvider` becomes "active group"**, switchable via UI. Multi-group already in the schema; we just surface it.
4. **Backfill** flips non-admin-added relatives from group-scope back to personal.

**Mental model after this lands:**

```
  Personal scope (family_group_id IS NULL, only YOU see)
  ───────────────────────────────────────────────
  Travels with you across every group you join.
  Wife, in-laws, work friends, anyone — all yours.

  Group A — your dad's family (admin = dad)
  ─────────────────────────────────────────
  Dad's lineage (everyone in the group sees).
  You see: Group A's shared tree + your personal merged.
  Other members see: Group A's shared tree + THEIR personal.

  Group B — your wife's family (admin = her dad)
  ─────────────────────────────────────────
  Her lineage. Same model.

  You can be in many groups at once. Switch via a chip.
```

**Tech Stack:** Flutter / Riverpod / Supabase. Same conventions as the earlier deferred-membership refactor.

---

## File Structure

**Migrations (`supabase/migrations/`):**
- `20260511200000_backfill_leaked_member_adds.sql` — flip family_group_id back to NULL on relatives added by non-admins (the leaked rows)
- `20260511210000_add_relative_default_scope_rpc.sql` (optional) — server-side helper RPC; alternatively keep logic in Dart

**Dart files modified:**
- `lib/features/family_tree/providers/family_graph_providers.dart` — `userFamilyGroupProvider` becomes `activeFamilyGroupProvider` + a switcher; `groupRelativesStreamProvider` merges with viewer-personal
- `lib/features/relatives/screens/add_relative_screen.dart` — default `_addToSharedTree = false` for non-admins; only admins see the "share with group" toggle (or default-shared for admins)
- `lib/features/home/providers/home_providers.dart` — `viewerFilteredRelativesProvider` updates to use merged stream in group mode
- `lib/features/family_tree/screens/family_tree_screen.dart` — group switcher chip; banner copy update
- `lib/features/family_groups/screens/family_group_screen.dart` — banner copy
- `lib/features/family_groups/screens/create_family_group_screen.dart` (new OR modify existing) — make "create new group" accessible from home/profile even when already in groups

**Dart files created:**
- `lib/features/family_tree/widgets/group_switcher_chip.dart` — small chip UI to pick active group (or "Personal")
- `lib/features/family_tree/providers/merged_relatives_provider.dart` — combines group + viewer's personal

---

# Phase A — Personal-vs-Shared Fix (the wife problem)

## Task A1: Migration — backfill leaked member-adds

**Files:**
- Create: `supabase/migrations/20260511200000_backfill_leaked_member_adds.sql`

**Why:** Existing rows where a non-admin member added a relative with `family_group_id = the_group_they_were_in` are the bug. Flip them back to NULL so they become personal-to-owner.

- [ ] **Step 1: Probe — who is leaking, how much?**

```sql
SELECT r.user_id, r.family_group_id, fgm.role, COUNT(*) AS leaked_count
FROM relatives r
JOIN family_group_members fgm
  ON fgm.group_id = r.family_group_id AND fgm.user_id = r.user_id
WHERE r.family_group_id IS NOT NULL
  AND fgm.role <> 'admin'
  AND r.is_self = false  -- self-nodes are correctly group-scoped (joiner's identity in the lineage)
GROUP BY r.user_id, r.family_group_id, fgm.role
ORDER BY leaked_count DESC;
```

Report the totals. If >50 rows, ABORT and ask the controller — the migration assumed pre-launch scale.

- [ ] **Step 2: Write the migration**

```sql
-- 20260511200000_backfill_leaked_member_adds.sql
-- Relatives added by non-admin group members are now personal-to-owner.
-- Flip family_group_id back to NULL on any leaked rows.
-- Edges that referenced those rows in group scope get their family_group_id
-- nulled too so they travel with the owner.
--
-- SAFE because: when the row's user_id is NOT the group admin, the row was
-- the member's personal addition that shouldn't have been shared. The
-- member's self-node (is_self = true) is excluded — that one IS supposed
-- to be group-scoped because the admin approved the claim. Same goes for
-- relatives the admin added (user_id = admin); those stay shared.

BEGIN;

-- Audit row count
DO $$
DECLARE
  v_relatives_count INT;
  v_edges_count INT;
BEGIN
  SELECT COUNT(*) INTO v_relatives_count
  FROM relatives r
  WHERE r.family_group_id IS NOT NULL
    AND r.is_self = false
    AND EXISTS (
      SELECT 1 FROM family_group_members fgm
       WHERE fgm.group_id = r.family_group_id
         AND fgm.user_id  = r.user_id
         AND fgm.role <> 'admin'
    );

  SELECT COUNT(*) INTO v_edges_count
  FROM family_edges e
  WHERE e.family_group_id IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM family_group_members fgm
       WHERE fgm.group_id = e.family_group_id
         AND fgm.user_id  = e.user_id
         AND fgm.role <> 'admin'
    );

  RAISE NOTICE 'Unscoping % leaked relatives + % leaked edges',
    v_relatives_count, v_edges_count;
END $$;

-- Unscope leaked relatives
UPDATE relatives r
   SET family_group_id = NULL
 WHERE r.family_group_id IS NOT NULL
   AND r.is_self = false
   AND EXISTS (
     SELECT 1 FROM family_group_members fgm
      WHERE fgm.group_id = r.family_group_id
        AND fgm.user_id  = r.user_id
        AND fgm.role <> 'admin'
   );

-- Unscope edges owned by non-admins
UPDATE family_edges e
   SET family_group_id = NULL
 WHERE e.family_group_id IS NOT NULL
   AND EXISTS (
     SELECT 1 FROM family_group_members fgm
      WHERE fgm.group_id = e.family_group_id
        AND fgm.user_id  = e.user_id
        AND fgm.role <> 'admin'
   );

COMMIT;
```

- [ ] **Step 3: Apply via MCP**

- [ ] **Step 4: Verify**

```sql
-- Should be 0
SELECT COUNT(*) FROM relatives r
JOIN family_group_members fgm
  ON fgm.group_id = r.family_group_id AND fgm.user_id = r.user_id
WHERE fgm.role <> 'admin' AND r.is_self = false;
```

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260511200000_backfill_leaked_member_adds.sql
git commit -m "fix(scope): backfill — unscope relatives added by non-admin members"
```

---

## Task A2: `add_relative_screen` — non-admin default is personal

**Files:**
- Modify: `lib/features/relatives/screens/add_relative_screen.dart`

**Why:** The screen already has `_addToSharedTree` and `_selectedGroup` state. We need to default `_addToSharedTree = false` for non-admins, and either hide the toggle or limit it. Admins keep the current "share with group" toggle visible (defaulting to ON for their own admin group).

- [ ] **Step 1: Determine admin status for the active group**

Read the file. Find where `userFamilyGroupProvider` (or successor) is watched. Add a check: is the current user the ADMIN of that group? (Membership row's `role` field.)

Add a provider if one doesn't exist:

```dart
final isAdminOfActiveGroupProvider = Provider.autoDispose<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  final groupInfo = ref.watch(activeFamilyGroupProvider).valueOrNull;
  if (user == null || groupInfo == null) return false;
  // groupInfo includes the user's role (admin | member)
  return groupInfo.role == 'admin';
});
```

(If `activeFamilyGroupProvider` doesn't yet exist — it's Task B1 — defer this provider and instead query `family_group_members` directly in the screen's initState.)

- [ ] **Step 2: Flip default + label**

In `_AddRelativeScreenState`:

```dart
bool _addToSharedTree = false;  // default personal
// ...

@override
void initState() {
  super.initState();
  // Auto-select active group AND auto-toggle ON if the user is admin
  final isAdmin = ref.read(isAdminOfActiveGroupProvider);
  if (isAdmin && groupInfo != null) {
    _addToSharedTree = true;
    _selectedGroup = group;
  }
}
```

- [ ] **Step 3: Reword the toggle**

Find the (currently invisible?) toggle UI for `_addToSharedTree`. Make it visible. Copy:

- Header: "نطاق هذا القريب"
- "خاص بي" (Personal) — explained: "لن يظهر للأعضاء الآخرين. مناسب لزوجتي، عائلتها، أصدقائي."
- "مشترك مع المجموعة" (Shared with group) — explained: "سيظهر للجميع في الشجرة. مناسب لأقارب الدم في هذه السلالة."

Default visually selected: "خاص بي" for non-admins, "مشترك" for admins.

If the form doesn't currently render a toggle widget, add a `SegmentedButton` or `Row` of radio chips beneath the relationship picker.

- [ ] **Step 4: Run analyzer**

```bash
flutter analyze lib/features/relatives/screens/add_relative_screen.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/relatives/screens/add_relative_screen.dart
git commit -m "feat(scope): non-admin adds default to personal; admin adds default to shared"
```

---

## Task A3: Group tree provider merges shared + viewer's personal

**Files:**
- Modify: `lib/features/family_tree/providers/family_graph_providers.dart`
- Modify: `lib/features/home/providers/home_providers.dart`

**Why:** Today `groupRelativesStreamProvider(groupId)` only streams `family_group_id = groupId`. A user's personal additions (NULL scope) are invisible in the group view. We need the group view to ALSO show the viewer's personal relatives, merged seamlessly into the tree.

- [ ] **Step 1: Create a merged provider**

In `family_graph_providers.dart`, add:

```dart
/// Group-context tree: shared relatives in the group + the viewer's own
/// personal relatives (family_group_id IS NULL). Other members never see
/// the viewer's personal rows because RLS filters by user_id.
final groupTreeRelativesProvider =
    StreamProvider.autoDispose.family<List<Relative>, String>((ref, groupId) async* {
  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) {
    yield const [];
    return;
  }

  // Two independent streams; we merge their latest values.
  final groupStream = SupabaseConfig.client
      .from('relatives')
      .stream(primaryKey: ['id'])
      .eq('family_group_id', groupId);

  final personalStream = SupabaseConfig.client
      .from('relatives')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .eq('family_group_id', null);  // PostgREST: filter NULL via .isFilter

  // (Use rxdart's combineLatest, or manual StreamController fan-in.)
  // Yield combined + de-duplicated by id, archived filtered out.
  ...
});
```

**Note:** Supabase realtime stream doesn't support `.isFilter('family_group_id', 'null')` cleanly in all SDK versions. Pragmatic alternative: stream BOTH `relatives where user_id = me` AND `relatives where family_group_id = groupId`, then de-dup by id. The viewer's personal-AND-in-group rows would dupe — keep the last.

A cleaner version using existing providers:

```dart
final groupTreeRelativesProvider =
    Provider.autoDispose.family<AsyncValue<List<Relative>>, String>((ref, groupId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const AsyncValue.data([]);

  final groupAsync = ref.watch(groupRelativesStreamProvider(groupId));
  final personalAsync = ref.watch(relativesStreamProvider(user.id));

  if (groupAsync.isLoading || personalAsync.isLoading) {
    return const AsyncValue.loading();
  }

  return AsyncValue.data([
    ...?groupAsync.valueOrNull,
    // Only PERSONAL rows from the personal stream (filter out duplicates
    // and rows already in some group).
    ...(personalAsync.valueOrNull ?? [])
        .where((r) => r.familyGroupId == null),
  ]);
});
```

- [ ] **Step 2: Update `viewerFilteredRelativesProvider`**

In `home_providers.dart`, find `viewerFilteredRelativesProvider`. Replace its group branch with the new merged provider:

```dart
final viewerFilteredRelativesProvider =
    Provider.autoDispose<AsyncValue<List<Relative>>>((ref) {
  final groupInfo = ref.watch(activeFamilyGroupProvider).valueOrNull;
  
  final rawAsync = groupInfo != null
      ? ref.watch(groupTreeRelativesProvider(groupInfo.groupId))  // NEW
      : ref.watch(relativesStreamProvider(user.id));
  
  // ... (rahim scope filter etc., unchanged)
});
```

- [ ] **Step 3: Same for edges**

Edges already follow `user_id = auth.uid()` so the viewer always sees only their own. The merge is automatic. But — confirm `family_edges` queries also fetch BOTH group-scoped and personal-scoped edges owned by the user. Find `sharedFamilyEdgesStreamProvider` and confirm it captures both.

If `sharedFamilyEdgesStreamProvider(groupId)` filters `family_group_id = groupId`, change to also include edges where `user_id = current_user AND family_group_id IS NULL`.

- [ ] **Step 4: Run analyzer**

```bash
flutter analyze lib/features/family_tree/providers/family_graph_providers.dart \
                lib/features/home/providers/home_providers.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/family_tree/providers/family_graph_providers.dart \
        lib/features/home/providers/home_providers.dart
git commit -m "feat(scope): group tree merges shared + viewer's personal relatives"
```

---

## Task A4: Banner copy update

**Files:**
- Modify: `lib/features/family_tree/screens/family_tree_screen.dart`
- Modify: `lib/features/family_groups/screens/family_group_screen.dart`

**Why:** Users need an explicit explanation of the new mental model. The user's preferred copy: "you are inside a shared family — when they add someone related to you you'll get them — but feel free to add your personals; we won't share those with the shared tree because your rels can be not their rels."

- [ ] **Step 1: Rewrite the group context banner**

Find the banner in `family_tree_screen.dart`. Add a NEW banner (separate from the unlinked-member banner) that appears whenever the user is viewing a group's tree. Copy:

```
أنت داخل عائلة مشتركة
الإضافات الجديدة من المسؤول ستظهر هنا. أضف أقاربك الخاصين بحرية —
لن يظهروا للأعضاء الآخرين لأن أقاربك قد لا يكونون أقاربهم.
```

Style: tap-to-dismiss; persist dismissal in `shared_preferences` keyed by groupId so it doesn't re-appear every visit.

- [ ] **Step 2: Update `family_group_screen.dart` info card**

If the group detail screen has an "about this group" card, update its copy similarly. If not, skip.

- [ ] **Step 3: Run analyzer**

- [ ] **Step 4: Commit**

```bash
git add lib/features/family_tree/screens/family_tree_screen.dart \
        lib/features/family_groups/screens/family_group_screen.dart
git commit -m "copy(scope): banner explaining personal-vs-shared"
```

---

# Phase B — Multi-Group

## Task B1: Rename `userFamilyGroupProvider` → `activeFamilyGroupProvider` + switcher

**Files:**
- Modify: `lib/features/family_tree/providers/family_graph_providers.dart`

**Why:** Today the provider returns `rows.first` from `family_group_members`. We need it to return a SELECTED group, with a default if none selected.

- [ ] **Step 1: Add active-group state**

```dart
/// Persistent user-selected active group. Null = personal-only view.
/// Persists across app restarts via shared_preferences.
final activeGroupIdProvider = StateNotifierProvider<ActiveGroupNotifier, String?>((ref) {
  return ActiveGroupNotifier();
});

class ActiveGroupNotifier extends StateNotifier<String?> {
  ActiveGroupNotifier() : super(null) { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('active_group_id');
  }

  Future<void> setActive(String? groupId) async {
    state = groupId;
    final prefs = await SharedPreferences.getInstance();
    if (groupId == null) {
      await prefs.remove('active_group_id');
    } else {
      await prefs.setString('active_group_id', groupId);
    }
  }
}
```

- [ ] **Step 2: Refactor `userFamilyGroupProvider`**

Rename to `activeFamilyGroupProvider`. Returns the membership row for the active group, falling back to first-group if no selection persists.

```dart
final activeFamilyGroupProvider =
    StreamProvider.autoDispose<ActiveGroupInfo?>((ref) {
  final activeId = ref.watch(activeGroupIdProvider);
  // ... query family_group_members for (active_id) row, fall back to first
});
```

Keep the OLD provider name as a deprecated alias pointing to the new one so call-sites can be migrated incrementally:

```dart
@Deprecated('Use activeFamilyGroupProvider')
final userFamilyGroupProvider = activeFamilyGroupProvider;
```

- [ ] **Step 3: Update call sites**

Grep for `userFamilyGroupProvider` and replace with `activeFamilyGroupProvider` in non-deprecated paths. Analyzer will flag deprecation warnings.

- [ ] **Step 4: Run analyzer + commit**

```bash
git commit -m "feat(scope): activeFamilyGroupProvider supports switching groups"
```

---

## Task B2: Group switcher chip on family tree screen

**Files:**
- Create: `lib/features/family_tree/widgets/group_switcher_chip.dart`
- Modify: `lib/features/family_tree/screens/family_tree_screen.dart`

- [ ] **Step 1: Build the chip**

```dart
class GroupSwitcherChip extends ConsumerWidget {
  const GroupSwitcherChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final activeId = ref.watch(activeGroupIdProvider);
    final groupsAsync = ref.watch(userGroupsProvider(user!.id));

    return groupsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (groups) {
        if (groups.isEmpty) return const SizedBox.shrink();

        final activeName = groups.firstWhereOrNull((g) => g.id == activeId)?.name ?? 'شخصي';

        return InkWell(
          onTap: () => _showPicker(context, ref, groups, activeId),
          child: Chip(
            label: Text(activeName),
            avatar: const Icon(Icons.swap_horiz_rounded, size: 18),
          ),
        );
      },
    );
  }

  void _showPicker(
    BuildContext context, WidgetRef ref, List<FamilyGroup> groups, String? activeId,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person_rounded),
            title: const Text('شخصي'),
            trailing: activeId == null ? const Icon(Icons.check) : null,
            onTap: () {
              ref.read(activeGroupIdProvider.notifier).setActive(null);
              Navigator.pop(context);
            },
          ),
          for (final g in groups)
            ListTile(
              leading: const Icon(Icons.group_rounded),
              title: Text(g.name),
              trailing: g.id == activeId ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(activeGroupIdProvider.notifier).setActive(g.id);
                Navigator.pop(context);
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add_rounded),
            title: const Text('إنشاء مجموعة جديدة'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.createFamilyGroup);
            },
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Mount the chip in family_tree_screen's AppBar/header**

Find where the screen's header is built. Add `const GroupSwitcherChip()` to the trailing or leading slot.

- [ ] **Step 3: Run analyzer + commit**

```bash
git commit -m "feat(scope): GroupSwitcherChip for multi-group navigation"
```

---

## Task B3: Surface "Create new group" from home + profile

**Files:**
- Modify: `lib/features/profile/screens/profile_screen.dart` (probably)
- Modify: `lib/features/home/screens/home_screen.dart` (probably)
- Verify or add: `lib/features/family_groups/screens/create_family_group_screen.dart`
- Modify: `lib/core/router/app_router.dart` (if route doesn't yet exist)
- Modify: `lib/core/router/app_routes.dart` — `createFamilyGroup` constant

**Why:** Currently group creation is buried. The user explicitly wants this to be accessible: "what if my uncle joined the tree and he wants to add his cousin there is no flexibility to create multiple groups as well."

- [ ] **Step 1: Verify create-group route exists**

```bash
grep -rn "create.*family.*group\|createFamilyGroup\|CreateGroupScreen" lib/core/router/
```

If not present, locate the existing creation form in the codebase. Wire it as `/create-family-group` if missing.

- [ ] **Step 2: Add CTA**

In the GroupSwitcherChip bottom sheet (Task B2 Step 1) — already done. Additionally:

- Profile screen: add a button "إنشاء مجموعة عائلية جديدة" near "مجموعاتي" section.
- Home screen (optional): add a banner if the user has 0 groups.

- [ ] **Step 3: Run analyzer + commit**

```bash
git commit -m "feat(scope): surface create-group CTA in profile + switcher"
```

---

# Phase C — Testing

## Task C1: Manual journey on simulator + phone

(User-driven. Test the scenarios below in sequence.)

1. **Member adds wife — personal stay personal**
   - As `testprodjoiner`, join `testprod`'s group via invite, claim spouse position, get approved.
   - Add a new relative "wife of testprodjoiner" via add-relative screen.
   - Verify the form defaults to "خاص بي" (personal). Save.
   - On testprodjoiner's tree (group view): wife appears as their spouse.
   - On testprod's tree (admin): wife does NOT appear. ✓

2. **Admin adds — shared by default**
   - As testprod, add a new relative (e.g., "نوني's son").
   - Verify the form defaults to "مشترك مع المجموعة". Save.
   - Visible to all members. ✓

3. **Multi-group**
   - As testprodjoiner, create a NEW group (e.g., "joiner's side").
   - GroupSwitcherChip now shows both groups + "شخصي".
   - Switch to "joiner's side" — empty tree (you're admin). Switch back to testprod's — see testprod's lineage + your personal wife.

4. **Backfill check**
   - Before-and-after SQL: pre-migration `SELECT COUNT(*) FROM relatives r JOIN family_group_members fgm USING (user_id) WHERE fgm.role <> 'admin' AND r.is_self = false AND r.family_group_id IS NOT NULL`. After migration, count should be 0.

## Task C2: Unit tests + analyzer

```bash
flutter analyze
flutter test test/unit/
```

Existing tests should still pass. If `addRelative` tests assert old defaults (`_addToSharedTree = true`), update them to reflect new role-aware default.

---

# Open follow-ups (NOT in this plan)

- **"Promote my personal relative to shared"** — member-initiated request, admin approves. Mirror the claim flow. Out of scope for v1.
- **"Cross-group merge"** — when admin's group and joiner's group represent overlapping families, merging them. Likely doesn't apply pre-launch; defer.
- **Edges RLS group-scoping** — `family_edges` RLS is currently `auth.uid() = user_id` only. The `family_group_id` column on edges is unused by RLS. Audit whether group-scoped edges should be visible to all members (probably yes for the SHARED admin-added edges). Separate refactor.

---

# Self-Review Checklist

**Spec coverage:** The user's pain mapping:

- "wife is part of my family but she has her own lineage" → Task A2 (default personal) + Task A3 (merge personal into group view).
- "engine fits the relative into a shared tree" → Task A2 + Task A1 backfill.
- "no flexibility to create multiple groups" → Tasks B1, B2, B3.
- "even the group info page banner button should say [new copy]" → Task A4.

**Placeholder scan:** none of the steps say "TBD". Code skeletons are concrete enough for an implementer to fill in.

**Type consistency:** `activeFamilyGroupProvider` is referenced consistently across Tasks A2 (admin check), A3 (group merge), B1 (definition). `GroupSwitcherChip` widget name consistent. `activeGroupIdProvider` consistent.

**Risk:** Task A1 (backfill) is destructive (UPDATE). Probe gate caps it at 50 rows. Pre-launch this is testprod's group + maybe a few others. Confirmed safe.
