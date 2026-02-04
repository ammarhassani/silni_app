# Family Sharing — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make family tree sharing work end-to-end — invite a relative from their profile, they join via WhatsApp link, and see the same tree from their own perspective.

**Architecture:** Extends existing FamilyGroupService, FamilyGraphService, and SharedTreeService with glue code: an auto-create-group flow, self-node creation, edge migration to shared scope, invite link with relative ID, and perspective-aware tree rendering. Database changes are additive (new columns, new table). No breaking changes to existing personal tree functionality.

**Tech Stack:** Flutter/Dart, Riverpod, Supabase (Postgres + RLS), GoRouter deep links, share_plus (WhatsApp)

**Design Doc:** `docs/plans/2026-02-04-family-sharing-design.md`

---

## Existing Code Reference

These files already exist and work correctly — the plan modifies/extends them:

| Component | File | What it does |
|-----------|------|-------------|
| FamilyGraphService | `lib/features/family_tree/services/family_graph_service.dart` | `inferEdges()` (15 relationship types), `getLabelForViewer()` (perspective labels), `buildGraph()` |
| FamilyGraph model | `lib/features/family_tree/models/family_graph.dart` | `FamilyEdge`, `FamilyGraph` with adjacency maps, `getParents/Children/Siblings/Spouse/Generation` |
| FamilyGroupService | `lib/features/family_groups/services/family_group_service.dart` | `createGroup()`, `joinGroup()`, `getUserGroups()`, `getGroupMembers()`, `generateInviteLink()` |
| SharedTreeService | `lib/features/family_groups/services/shared_tree_service.dart` | `addSharedRelative()`, `getSharedRelatives()`, `watchSharedRelatives()` |
| Relative model | `lib/shared/models/relative_model.dart` | Has `familyGroupId`, `addedBy`, `familySide` fields |
| Graph providers | `lib/features/family_tree/providers/family_graph_providers.dart` | `familyEdgesStreamProvider` (by userId), `familyGraphProvider` |
| Tree screen | `lib/features/family_tree/screens/family_tree_screen.dart` | CustomPainter canvas tree, hardcoded "شجرة العائلة" header |
| Relative detail | `lib/features/relatives/screens/relative_detail_screen.dart` | Contact actions, no invite button |
| JoinGroupScreen | `lib/features/family_groups/screens/join_group_screen.dart` | Join flow, does NOT set `relative_id_in_tree` |
| family_edges migration | `supabase/migrations/20260201140000_family_edges.sql` | `user_id` scoped edges, no `family_group_id` |
| family_groups migration | `supabase/migrations/20260201150000_family_groups.sql` | Groups, members, shared relative columns, RLS |

---

## Task 1: Database Migration — Shared Edges + Self Node

Add `family_group_id` to `family_edges` so edges can be shared across group members. Add `is_self` to `relatives` for the self-node concept.

**Files:**
- Create: `supabase/migrations/20260204130000_family_sharing.sql`

**Step 1: Write the migration**

```sql
-- Family Sharing: shared edges, self node, relationship labels
-- Part of: docs/plans/2026-02-04-family-sharing-design.md

-- 1. Add family_group_id to family_edges for shared trees
ALTER TABLE family_edges
  ADD COLUMN IF NOT EXISTS family_group_id UUID REFERENCES family_groups(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_family_edges_group
  ON family_edges(family_group_id) WHERE family_group_id IS NOT NULL;

-- 2. Add is_self to relatives for self-node
ALTER TABLE relatives
  ADD COLUMN IF NOT EXISTS is_self BOOLEAN DEFAULT false;

-- 3. RLS: group members can view shared edges
CREATE POLICY "Group members can view shared edges"
  ON family_edges FOR SELECT
  USING (
    family_group_id IS NOT NULL
    AND family_group_id IN (SELECT auth_user_group_ids())
  );

CREATE POLICY "Group members can insert shared edges"
  ON family_edges FOR INSERT
  WITH CHECK (
    family_group_id IS NOT NULL
    AND family_group_id IN (SELECT auth_user_group_ids())
  );

-- 4. Admin relationship labels (admin-panelized perspective labels)
CREATE TABLE IF NOT EXISTS admin_relationship_labels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  edge_path TEXT NOT NULL,
  parent_side TEXT CHECK (parent_side IN ('paternal', 'maternal')),
  gender TEXT NOT NULL CHECK (gender IN ('male', 'female')),
  label_ar TEXT NOT NULL,
  label_en TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(edge_path, parent_side, gender)
);

ALTER TABLE admin_relationship_labels ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read active labels"
  ON admin_relationship_labels FOR SELECT
  USING (is_active = true);

CREATE POLICY "Admins can manage labels"
  ON admin_relationship_labels FOR ALL
  USING (is_admin());

-- 5. Seed relationship labels
INSERT INTO admin_relationship_labels (edge_path, parent_side, gender, label_ar, label_en) VALUES
  ('self',                NULL,        'male',   'أنا',           'Me'),
  ('self',                NULL,        'female', 'أنا',           'Me'),
  ('parent',              NULL,        'male',   'أبي',           'My father'),
  ('parent',              NULL,        'female', 'أمي',           'My mother'),
  ('child',               NULL,        'male',   'ابني',          'My son'),
  ('child',               NULL,        'female', 'ابنتي',         'My daughter'),
  ('spouse',              NULL,        'male',   'زوجي',          'My husband'),
  ('spouse',              NULL,        'female', 'زوجتي',         'My wife'),
  ('sibling',             NULL,        'male',   'أخوي',          'My brother'),
  ('sibling',             NULL,        'female', 'أختي',          'My sister'),
  ('parent.parent',       NULL,        'male',   'جدي',           'My grandfather'),
  ('parent.parent',       NULL,        'female', 'جدتي',          'My grandmother'),
  ('child.child',         NULL,        'male',   'حفيدي',         'My grandson'),
  ('child.child',         NULL,        'female', 'حفيدتي',        'My granddaughter'),
  ('parent.sibling',      'paternal',  'male',   'عمي',           'My paternal uncle'),
  ('parent.sibling',      'paternal',  'female', 'عمتي',          'My paternal aunt'),
  ('parent.sibling',      'maternal',  'male',   'خالي',          'My maternal uncle'),
  ('parent.sibling',      'maternal',  'female', 'خالتي',         'My maternal aunt'),
  ('sibling.child',       NULL,        'male',   'ابن أخوي',       'My nephew'),
  ('sibling.child',       NULL,        'female', 'بنت أخوي',       'My niece'),
  ('parent.sibling.child', 'paternal', 'male',   'ابن عمي',        'My paternal cousin (m)'),
  ('parent.sibling.child', 'paternal', 'female', 'بنت عمي',        'My paternal cousin (f)'),
  ('parent.sibling.child', 'maternal', 'male',   'ابن خالي',       'My maternal cousin (m)'),
  ('parent.sibling.child', 'maternal', 'female', 'بنت خالي',       'My maternal cousin (f)')
ON CONFLICT (edge_path, parent_side, gender) DO NOTHING;

-- 6. Seed join notification template
INSERT INTO admin_notification_templates (
  template_key, title_ar, title_en, body_ar, body_en,
  category, variables, priority, is_active
) VALUES (
  'family_join_1',
  'عضو جديد في العائلة',
  'New Family Member',
  '{{member_name}} انضم/ت ل{{family_name}} 🌳',
  '{{member_name}} joined {{family_name}} 🌳',
  'system',
  ARRAY['member_name', 'family_name'],
  'default',
  true
) ON CONFLICT (template_key) DO NOTHING;
```

**Step 2: Push migration**

Run: `supabase db push --linked`
Expected: Migration applied successfully

**Step 3: Commit**

```bash
git add supabase/migrations/20260204130000_family_sharing.sql
git commit -m "feat(db): add shared edges, self node, and relationship labels for family sharing"
```

---

## Task 2: Model Updates — FamilyEdge + Relative

Update Dart models to support shared edges and self nodes.

**Files:**
- Modify: `lib/features/family_tree/models/family_graph.dart:45-101` (FamilyEdge class)
- Modify: `lib/shared/models/relative_model.dart` (add isSelf field)

**Step 1: Add `familyGroupId` to FamilyEdge**

In `lib/features/family_tree/models/family_graph.dart`, modify the `FamilyEdge` class:

Add field after `type`:
```dart
final String? familyGroupId;
```

Update constructor to include `this.familyGroupId`:
```dart
const FamilyEdge({
  required this.id,
  required this.userId,
  required this.fromId,
  required this.toId,
  required this.type,
  required this.createdAt,
  this.familyGroupId,
});
```

Update `FamilyEdge.create` factory:
```dart
factory FamilyEdge.create({
  required String userId,
  required String fromId,
  required String toId,
  required EdgeType type,
  String? familyGroupId,
}) {
  return FamilyEdge(
    id: const Uuid().v4(),
    userId: userId,
    fromId: fromId,
    toId: toId,
    type: type,
    createdAt: DateTime.now(),
    familyGroupId: familyGroupId,
  );
}
```

Update `fromJson`:
```dart
familyGroupId: json['family_group_id'] as String?,
```

Update `toJson`:
```dart
if (familyGroupId != null) 'family_group_id': familyGroupId,
```

**Step 2: Add `isSelf` to Relative**

In `lib/shared/models/relative_model.dart`, add field:
```dart
final bool isSelf;
```

Add to constructor with `this.isSelf = false`.

Add to `fromJson`:
```dart
isSelf: json['is_self'] as bool? ?? false,
```

Add to `toJson`:
```dart
if (isSelf) 'is_self': true,
```

Add to `copyWith`.

**Step 3: Run existing tests**

Run: `make test`
Expected: All tests pass (fields are optional/defaulted)

**Step 4: Commit**

```bash
git add lib/features/family_tree/models/family_graph.dart lib/shared/models/relative_model.dart
git commit -m "feat: add familyGroupId to FamilyEdge and isSelf to Relative"
```

---

## Task 3: Editable Family Name on Tree Screen

Replace hardcoded "شجرة العائلة" with an editable family name stored in Supabase user metadata.

**Files:**
- Modify: `lib/features/family_tree/screens/family_tree_screen.dart:176-207` (_buildHeader method)

**Step 1: Add state for family name**

Add to `_FamilyTreeScreenState`:
```dart
String _familyName = 'شجرة العائلة';
bool _isEditingName = false;
final _nameController = TextEditingController();
```

In `initState`, load from user metadata:
```dart
final user = SupabaseConfig.client.auth.currentUser;
final name = user?.userMetadata?['family_name'] as String?;
if (name != null && name.isNotEmpty) {
  _familyName = name;
}
```

**Step 2: Replace _buildHeader**

Replace the hardcoded Text widget (lines 193-202) with a tappable/editable version:

```dart
Expanded(
  child: _isEditingName
      ? TextField(
          controller: _nameController,
          autofocus: true,
          textDirection: TextDirection.rtl,
          style: AppTypography.headlineMedium.copyWith(
            color: themeColors.textOnGradient,
            fontWeight: FontWeight.bold,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'اسم العائلة',
          ),
          onSubmitted: (value) => _saveFamilyName(value),
        )
      : GestureDetector(
          onTap: () {
            setState(() {
              _isEditingName = true;
              _nameController.text = _familyName;
            });
          },
          child: Row(
            children: [
              Flexible(
                child: Text(
                  _familyName,
                  style: AppTypography.headlineMedium.copyWith(
                    color: themeColors.textOnGradient,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.edit_rounded, color: themeColors.textOnGradient.withValues(alpha: 0.5), size: 16),
            ],
          ),
        ),
),
```

**Step 3: Add save method**

```dart
Future<void> _saveFamilyName(String name) async {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    setState(() => _isEditingName = false);
    return;
  }
  setState(() {
    _familyName = trimmed;
    _isEditingName = false;
  });
  await SupabaseConfig.client.auth.updateUser(
    UserAttributes(data: {'family_name': trimmed}),
  );
}
```

**Step 4: Verify on device**

Run: `flutter run` → navigate to family tree → tap header → edit name → verify it persists after restart

**Step 5: Commit**

```bash
git add lib/features/family_tree/screens/family_tree_screen.dart
git commit -m "feat: editable family name on tree screen header"
```

---

## Task 4: Family Sharing Service — The Core

Create the service that auto-creates a family group, creates a self node, migrates personal relatives to shared, and generates edges.

**Files:**
- Create: `lib/features/family_groups/services/family_sharing_service.dart`
- Create: `test/unit/services/family_sharing_service_test.dart`

**Step 1: Write failing test**

```dart
// test/unit/services/family_sharing_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:silni/features/family_groups/services/family_sharing_service.dart';
import 'package:silni/features/family_tree/models/family_graph.dart';
import 'package:silni/shared/models/relative_model.dart';

void main() {
  group('FamilySharingService', () {
    group('generateSharedEdges', () {
      test('creates self node reference in edges', () {
        final relatives = [
          _makeRelative('mom-id', 'أمي', RelationshipType.mother, Gender.female),
          _makeRelative('dad-id', 'أبوي', RelationshipType.father, Gender.male),
        ];

        final edges = FamilySharingService.generateSharedEdges(
          selfNodeId: 'self-id',
          relatives: relatives,
          groupId: 'group-1',
        );

        // Should have parent edges from mom and dad to self
        expect(edges.any((e) =>
          e.fromId == 'mom-id' && e.toId == 'self-id' &&
          e.type == EdgeType.parentOf), isTrue);
        expect(edges.any((e) =>
          e.fromId == 'dad-id' && e.toId == 'self-id' &&
          e.type == EdgeType.parentOf), isTrue);

        // All edges should have familyGroupId set
        for (final edge in edges) {
          expect(edge.familyGroupId, equals('group-1'));
        }
      });

      test('infers spouse edge between parents', () {
        final relatives = [
          _makeRelative('mom-id', 'أمي', RelationshipType.mother, Gender.female),
          _makeRelative('dad-id', 'أبوي', RelationshipType.father, Gender.male),
        ];

        final edges = FamilySharingService.generateSharedEdges(
          selfNodeId: 'self-id',
          relatives: relatives,
          groupId: 'group-1',
        );

        expect(edges.any((e) =>
          e.type == EdgeType.spouseOf &&
          ((e.fromId == 'mom-id' && e.toId == 'dad-id') ||
           (e.fromId == 'dad-id' && e.toId == 'mom-id'))), isTrue);
      });

      test('handles sibling relationships', () {
        final relatives = [
          _makeRelative('bro-id', 'أخوي', RelationshipType.brother, Gender.male),
        ];

        final edges = FamilySharingService.generateSharedEdges(
          selfNodeId: 'self-id',
          relatives: relatives,
          groupId: 'group-1',
        );

        expect(edges.any((e) =>
          e.type == EdgeType.siblingOf &&
          ((e.fromId == 'bro-id' && e.toId == 'self-id') ||
           (e.fromId == 'self-id' && e.toId == 'bro-id'))), isTrue);
      });

      test('handles paternal uncle via father', () {
        final relatives = [
          _makeRelative('dad-id', 'أبوي', RelationshipType.father, Gender.male),
          _makeRelative('uncle-id', 'عمي', RelationshipType.uncle, Gender.male,
            familySide: FamilySide.paternal),
        ];

        final edges = FamilySharingService.generateSharedEdges(
          selfNodeId: 'self-id',
          relatives: relatives,
          groupId: 'group-1',
        );

        // Uncle should be sibling of dad
        expect(edges.any((e) =>
          e.type == EdgeType.siblingOf &&
          ((e.fromId == 'uncle-id' && e.toId == 'dad-id') ||
           (e.fromId == 'dad-id' && e.toId == 'uncle-id'))), isTrue);
      });
    });
  });
}

Relative _makeRelative(
  String id, String name, RelationshipType type, Gender gender, {
  FamilySide? familySide,
}) {
  return Relative(
    id: id,
    userId: 'user-1',
    fullName: name,
    relationshipType: type,
    gender: gender,
    priority: type.priority,
    lastContactDate: DateTime.now(),
    currentStreak: 0,
    longestStreak: 0,
    avatarType: AvatarType.adultMan,
    createdAt: DateTime.now(),
    familySide: familySide,
  );
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/services/family_sharing_service_test.dart`
Expected: FAIL — file not found

**Step 3: Implement FamilySharingService**

```dart
// lib/features/family_groups/services/family_sharing_service.dart
import 'package:uuid/uuid.dart';
import '../../../core/config/supabase_config.dart';
import '../../../shared/models/relative_model.dart';
import '../../family_tree/models/family_graph.dart';
import '../../family_tree/services/family_graph_service.dart';
import '../models/family_group_model.dart';
import 'family_group_service.dart';

/// Orchestrates the full family sharing flow:
/// auto-create group, self node, migrate relatives, generate edges.
///
/// Pure static methods for testability. Supabase calls isolated to
/// [initializeSharedTree] and [inviteRelative].
class FamilySharingService {
  FamilySharingService._();

  /// Initialize a shared tree from the user's personal relatives.
  ///
  /// 1. Creates family group with [familyName]
  /// 2. Creates a self-node relative for the user
  /// 3. Sets family_group_id on all user's personal relatives
  /// 4. Generates and persists shared edges
  ///
  /// Returns the created [FamilyGroup].
  static Future<FamilyGroup> initializeSharedTree({
    required String userId,
    required String familyName,
    required String userDisplayName,
    required Gender? userGender,
  }) async {
    final client = SupabaseConfig.client;

    // 1. Create family group
    final group = await FamilyGroupService.createGroup(
      name: familyName,
      userId: userId,
    );

    // 2. Create self node
    final selfNodeJson = {
      'id': const Uuid().v4(),
      'user_id': userId,
      'full_name': userDisplayName,
      'relationship_type': 'other',
      'gender': userGender?.value ?? 'male',
      'priority': 1,
      'avatar_type': userGender == Gender.female ? 'adult_woman' : 'adult_man',
      'current_streak': 0,
      'longest_streak': 0,
      'is_self': true,
      'family_group_id': group.id,
      'added_by': userId,
    };
    final selfNodeData = await client
        .from('relatives')
        .insert(selfNodeJson)
        .select()
        .single();
    final selfNodeId = selfNodeData['id'] as String;

    // 3. Link user to their self node in group membership
    await client
        .from('family_group_members')
        .update({'relative_id_in_tree': selfNodeId})
        .eq('group_id', group.id)
        .eq('user_id', userId);

    // 4. Fetch all personal relatives and migrate to shared
    final personalRelatives = await client
        .from('relatives')
        .select()
        .eq('user_id', userId)
        .isFilter('family_group_id', null)
        .eq('is_archived', false);

    final relatives = personalRelatives
        .map((json) => Relative.fromJson(json))
        .toList();

    // Set family_group_id on all personal relatives
    if (relatives.isNotEmpty) {
      final ids = relatives.map((r) => r.id).toList();
      await client
          .from('relatives')
          .update({
            'family_group_id': group.id,
            'added_by': userId,
          })
          .inFilter('id', ids);
    }

    // 5. Generate and persist shared edges
    final edges = generateSharedEdges(
      selfNodeId: selfNodeId,
      relatives: relatives,
      groupId: group.id,
    );

    if (edges.isNotEmpty) {
      await client.from('family_edges').insert(
        edges.map((e) => e.toJson()).toList(),
      );
    }

    return group;
  }

  /// Generate shared edges from personal relatives.
  ///
  /// Uses [FamilyGraphService.inferEdges] for each relative, replacing
  /// the auth userId with [selfNodeId] as the anchor.
  /// All edges get [groupId] set for shared visibility.
  static List<FamilyEdge> generateSharedEdges({
    required String selfNodeId,
    required List<Relative> relatives,
    required String groupId,
  }) {
    final allEdges = <FamilyEdge>[];

    for (final relative in relatives) {
      final inferred = FamilyGraphService.inferEdges(
        userId: selfNodeId,
        newRelativeId: relative.id,
        relationshipType: relative.relationshipType,
        side: relative.familySide,
        existingEdges: allEdges,
        existingRelatives: relatives,
      );

      // Set familyGroupId on each inferred edge
      for (final edge in inferred) {
        allEdges.add(FamilyEdge(
          id: edge.id,
          userId: edge.userId,
          fromId: edge.fromId,
          toId: edge.toId,
          type: edge.type,
          createdAt: edge.createdAt,
          familyGroupId: groupId,
        ));
      }
    }

    return allEdges;
  }

  /// Get the user's family group (if any).
  static Future<FamilyGroup?> getUserGroup(String userId) async {
    final groups = await FamilyGroupService.getUserGroups(userId);
    return groups.isEmpty ? null : groups.first;
  }

  /// Generate an invite link for a specific relative in the tree.
  ///
  /// The link encodes both the invite code and the relative's ID so
  /// the joiner gets auto-linked to the correct tree node.
  static String generateInviteLink({
    required String inviteCode,
    required String relativeId,
  }) {
    return 'https://silni.app/join/$inviteCode?rid=$relativeId';
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/unit/services/family_sharing_service_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/family_groups/services/family_sharing_service.dart test/unit/services/family_sharing_service_test.dart
git commit -m "feat: FamilySharingService — auto-create group, self node, edge generation"
```

---

## Task 5: Invite Button on Relative Profile

Add an "ادعيه/ها لصِلني" button to the relative detail screen.

**Files:**
- Modify: `lib/features/relatives/screens/relative_detail_screen.dart`

**Step 1: Add invite method to the screen state**

Add import at the top:
```dart
import '../../family_groups/services/family_sharing_service.dart';
import '../../family_groups/services/family_group_service.dart';
import 'package:share_plus/share_plus.dart';
```

Add method to `_RelativeDetailScreenState`:
```dart
Future<void> _inviteRelative(Relative relative) async {
  final user = ref.read(currentUserProvider)?.value;
  if (user == null) return;

  setState(() => _isLoggingInteraction = true); // reuse loading state

  try {
    // Check if user already has a group
    var group = await FamilySharingService.getUserGroup(user.id);

    if (group == null) {
      // Auto-create group from personal tree
      final familyName = user.userMetadata?['family_name'] as String? ?? 'عائلتي';
      final userGender = Gender.fromString(user.userMetadata?['gender'] as String?);

      group = await FamilySharingService.initializeSharedTree(
        userId: user.id,
        familyName: familyName,
        userDisplayName: user.userMetadata?['display_name'] as String? ?? 'أنا',
        userGender: userGender,
      );
    }

    // Generate invite link with relative ID
    final link = FamilySharingService.generateInviteLink(
      inviteCode: group.inviteCode,
      relativeId: relative.id,
    );

    // Share via system sheet (WhatsApp preferred)
    await Share.share(
      'انضم/ي لعائلتنا في صِلني 🌳\n$link',
    );
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoggingInteraction = false);
  }
}
```

**Step 2: Add invite button to the UI**

Find the contact actions area in the build method and add an invite button below it. Look for a suitable location after the existing action buttons and add:

```dart
// Invite to family tree button
Padding(
  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
  child: OutlinedButton.icon(
    onPressed: () => _inviteRelative(relative),
    icon: const Icon(Icons.share_rounded),
    label: Text(
      relative.gender == Gender.female ? 'ادعيها لصِلني' : 'ادعيه لصِلني',
    ),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(double.infinity, 48),
    ),
  ),
),
```

**Step 3: Verify on device**

Run: `flutter run` → open a relative's profile → tap invite button → verify WhatsApp share opens with correct link

**Step 4: Commit**

```bash
git add lib/features/relatives/screens/relative_detail_screen.dart
git commit -m "feat: invite button on relative profile for family sharing"
```

---

## Task 6: Join Flow — Link Joiner to Tree Node

Update the join flow to extract the relative ID from the invite link and set `relative_id_in_tree`.

**Files:**
- Modify: `lib/core/router/app_router.dart` (pass query params)
- Modify: `lib/features/family_groups/screens/join_group_screen.dart`
- Modify: `lib/features/family_groups/services/family_group_service.dart`

**Step 1: Update route to pass relative ID**

In `app_router.dart`, the join route already captures `:code` as a path param. Update the `JoinGroupScreen` instantiation to also pass the `rid` query param:

```dart
GoRoute(
  path: '${AppRoutes.joinFamilyGroup}/:code',
  name: 'joinFamilyGroup',
  pageBuilder: (context, state) {
    final code = state.pathParameters['code']!;
    final relativeId = state.uri.queryParameters['rid'];
    return _buildPageWithTransition(
      context,
      state,
      JoinGroupScreen(inviteCode: code, targetRelativeId: relativeId),
    );
  },
),
```

**Step 2: Update JoinGroupScreen**

Add `targetRelativeId` param:
```dart
class JoinGroupScreen extends ConsumerStatefulWidget {
  final String inviteCode;
  final String? targetRelativeId;

  const JoinGroupScreen({
    super.key,
    required this.inviteCode,
    this.targetRelativeId,
  });
```

Update `_joinGroup()` to pass relative ID:
```dart
final group = await FamilyGroupService.joinGroup(
  inviteCode: widget.inviteCode,
  userId: user.id,
  relativeIdInTree: widget.targetRelativeId,
);
```

**Step 3: Update FamilyGroupService.joinGroup**

Add optional `relativeIdInTree` parameter:
```dart
static Future<FamilyGroup> joinGroup({
  required String inviteCode,
  required String userId,
  String? relativeIdInTree,
}) async {
  // ... existing lookup ...

  if (existing == null) {
    await client.from('family_group_members').insert({
      'group_id': group.id,
      'user_id': userId,
      'role': 'member',
      if (relativeIdInTree != null) 'relative_id_in_tree': relativeIdInTree,
    });
  }

  return group;
}
```

**Step 4: After joining, navigate to the family tree instead of group screen**

In `_joinGroup()`, change navigation:
```dart
if (mounted) {
  HapticFeedback.heavyImpact();
  context.go(AppRoutes.familyTree);
}
```

**Step 5: Run tests, verify**

Run: `flutter test`
Expected: PASS

**Step 6: Commit**

```bash
git add lib/core/router/app_router.dart lib/features/family_groups/screens/join_group_screen.dart lib/features/family_groups/services/family_group_service.dart
git commit -m "feat: join flow sets relative_id_in_tree from invite link"
```

---

## Task 7: Shared Edge Providers + Perspective Tree

Add providers for shared edges and update the tree screen to render perspective-aware labels.

**Files:**
- Modify: `lib/features/family_tree/providers/family_graph_providers.dart`
- Modify: `lib/features/family_tree/screens/family_tree_screen.dart`
- Modify: `lib/features/family_tree/widgets/tree_node_widget.dart`

**Step 1: Add shared edge providers**

In `family_graph_providers.dart`, add:

```dart
/// Stream provider for shared family edges (by group ID).
final sharedFamilyEdgesStreamProvider =
    StreamProvider.autoDispose.family<List<FamilyEdge>, String>((ref, groupId) {
  final link = ref.keepAlive();
  Timer? timer;

  ref.onDispose(() => timer?.cancel());
  ref.onCancel(() {
    timer = Timer(_cacheTimeout, () => link.close());
  });
  ref.onResume(() => timer?.cancel());

  return SupabaseConfig.client
      .from('family_edges')
      .stream(primaryKey: ['id'])
      .eq('family_group_id', groupId)
      .map((data) => data.map((json) => FamilyEdge.fromJson(json)).toList());
});

/// Build a shared graph with a specific viewer as anchor.
///
/// [viewerNodeId] is the relative_id_in_tree of the current viewer.
final sharedFamilyGraphProvider = Provider.autoDispose
    .family<FamilyGraph?, ({String groupId, String viewerNodeId})>((ref, params) {
  final edgesAsync = ref.watch(sharedFamilyEdgesStreamProvider(params.groupId));
  return edgesAsync.whenData((edges) {
    if (edges.isEmpty) return null;
    return FamilyGraphService.buildGraph(
      userId: params.viewerNodeId,
      edges: edges,
    );
  }).valueOrNull;
});
```

**Step 2: Add provider to detect shared tree context**

```dart
/// Provider that returns the user's family group membership info.
/// Returns (groupId, relativeIdInTree) or null.
final userFamilyGroupProvider =
    FutureProvider.autoDispose<({String groupId, String nodeId})?>(
      (ref) async {
  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) return null;

  final data = await SupabaseConfig.client
      .from('family_group_members')
      .select('group_id, relative_id_in_tree')
      .eq('user_id', user.id)
      .not('relative_id_in_tree', 'is', null)
      .limit(1)
      .maybeSingle();

  if (data == null) return null;
  final groupId = data['group_id'] as String?;
  final nodeId = data['relative_id_in_tree'] as String?;
  if (groupId == null || nodeId == null) return null;
  return (groupId: groupId, nodeId: nodeId);
});
```

**Step 3: Update tree screen to use perspective labels**

In `family_tree_screen.dart`, where tree nodes are rendered, check if the user is in a shared tree and use `getLabelForViewer` for labels.

The tree node widget receives a `Relative` and displays its `relationshipType.arabicName`. Update it to accept an optional `perspectiveLabel` that overrides the default:

In the tree screen's node rendering section, compute labels:
```dart
// When building tree nodes:
final groupInfo = ref.watch(userFamilyGroupProvider).valueOrNull;
final graph = groupInfo != null
    ? ref.watch(sharedFamilyGraphProvider((
        groupId: groupInfo.groupId,
        viewerNodeId: groupInfo.nodeId,
      )))
    : ref.watch(familyGraphProvider(userId));

// For each relative node:
final label = graph != null
    ? FamilyGraphService.getLabelForViewer(
        graph: graph,
        viewerId: groupInfo?.nodeId ?? userId,
        targetId: relative.id,
        relativesMap: relativesMap,
      )
    : relative.relationshipType.arabicName;
```

**Step 4: Update TreeNodeWidget to accept perspective label**

Pass the computed `label` to the tree node widget and display it instead of `relative.relationshipType.arabicName`.

**Step 5: Test on device**

Run: `flutter run` → verify personal tree still shows correct labels → create a family group via invite flow → verify labels update to perspective view

**Step 6: Commit**

```bash
git add lib/features/family_tree/providers/family_graph_providers.dart lib/features/family_tree/screens/family_tree_screen.dart lib/features/family_tree/widgets/tree_node_widget.dart
git commit -m "feat: perspective-aware tree rendering with shared edges"
```

---

## Task 8: Join Notification

Send push notification to group members when someone joins.

**Files:**
- Modify: `lib/features/family_groups/services/family_group_service.dart`

**Step 1: Add notification after join**

In `FamilyGroupService.joinGroup()`, after the member is inserted, call the push notification function for all existing members:

```dart
if (existing == null) {
  // ... insert member ...

  // Send join notification to existing members
  _sendJoinNotification(
    groupId: group.id,
    newUserId: userId,
    familyName: group.name,
  );
}
```

```dart
/// Fire-and-forget join notification to group members.
static Future<void> _sendJoinNotification({
  required String groupId,
  required String newUserId,
  required String familyName,
}) async {
  try {
    final client = SupabaseConfig.client;

    // Get display name of the new member
    final newUser = await client
        .from('family_group_members')
        .select()
        .eq('group_id', groupId)
        .eq('user_id', newUserId)
        .maybeSingle();

    // Get all OTHER members
    final members = await client
        .from('family_group_members')
        .select('user_id')
        .eq('group_id', groupId)
        .neq('user_id', newUserId);

    // Fetch the join template
    final template = await client
        .from('admin_notification_templates')
        .select()
        .eq('template_key', 'family_join_1')
        .eq('is_active', true)
        .maybeSingle();

    if (template == null) return;

    final body = (template['body_ar'] as String)
        .replaceAll('{{member_name}}', 'عضو جديد')
        .replaceAll('{{family_name}}', familyName);
    final title = template['title_ar'] as String;

    // Send to each member via the existing push function
    for (final member in members) {
      await client.functions.invoke('send-push-notification', body: {
        'userId': member['user_id'],
        'notificationType': 'system',
        'title': title,
        'body': body,
        'data': {'type': 'family_join', 'group_id': groupId},
      });
    }
  } catch (_) {
    // Fire-and-forget — don't block join flow on notification failure
  }
}
```

**Step 2: Commit**

```bash
git add lib/features/family_groups/services/family_group_service.dart
git commit -m "feat: push notification when member joins family group"
```

---

## Task 9: Family Activity Feed

Add a collective stats card to the family group screen.

**Files:**
- Create: `lib/features/family_groups/widgets/family_activity_card.dart`
- Modify: `lib/features/family_groups/screens/family_group_screen.dart`

**Step 1: Create FamilyActivityCard**

```dart
// lib/features/family_groups/widgets/family_activity_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/glass_card.dart';

/// Displays collective family stats: total interactions this month,
/// active members, and top streak.
class FamilyActivityCard extends ConsumerWidget {
  final String groupId;
  final String familyName;

  const FamilyActivityCard({
    super.key,
    required this.groupId,
    required this.familyName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchFamilyStats(groupId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final stats = snapshot.data!;
        final totalInteractions = stats['total'] as int? ?? 0;
        final activeMembers = stats['active'] as int? ?? 0;

        if (totalInteractions == 0) return const SizedBox.shrink();

        return GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📊 نشاط العائلة هالشهر',
                style: AppTypography.titleSmall.copyWith(
                  color: themeColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '$familyName تواصلوا $totalInteractions مرة هالشهر',
                style: AppTypography.bodyMedium.copyWith(
                  color: themeColors.onSurface,
                ),
              ),
              if (activeMembers > 0)
                Text(
                  '$activeMembers أعضاء نشطين',
                  style: AppTypography.bodySmall.copyWith(
                    color: themeColors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static Future<Map<String, dynamic>> _fetchFamilyStats(
    String groupId,
  ) async {
    final client = SupabaseConfig.client;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).toUtc().toIso8601String();

    // Get all member user IDs
    final members = await client
        .from('family_group_members')
        .select('user_id')
        .eq('group_id', groupId);

    final memberIds = members.map((m) => m['user_id'] as String).toList();
    if (memberIds.isEmpty) return {'total': 0, 'active': 0};

    // Count interactions by group members this month
    final interactions = await client
        .from('interactions')
        .select('id, user_id')
        .inFilter('user_id', memberIds)
        .gte('interaction_date', monthStart);

    final uniqueActiveMembers = interactions
        .map((i) => i['user_id'] as String)
        .toSet()
        .length;

    return {
      'total': interactions.length,
      'active': uniqueActiveMembers,
    };
  }
}
```

**Step 2: Add to FamilyGroupScreen**

Import and add `FamilyActivityCard` to the family group screen's body, above the leaderboard:

```dart
FamilyActivityCard(
  groupId: widget.groupId,
  familyName: group.name,
),
```

**Step 3: Commit**

```bash
git add lib/features/family_groups/widgets/family_activity_card.dart lib/features/family_groups/screens/family_group_screen.dart
git commit -m "feat: family activity feed on group screen"
```

---

## Task 10: Push Migration to Production + Verify

**Step 1: Push all migrations**

```bash
supabase db push --linked
```

**Step 2: Deploy edge function updates (if any)**

```bash
supabase functions deploy send-push-notification --project-ref bapwklwxmwhpucutyras
```

**Step 3: Build and deploy**

```bash
flutter build ios
# or
flutter build apk
```

**Step 4: End-to-end verification on TWO devices**

1. Device A (inviter): Open relative profile → tap invite → share link → verify group created
2. Device B (joiner): Open link → create account → join → verify tree shows from their perspective
3. Device A: Verify notification received
4. Both devices: Verify shared tree shows same relatives with different labels

**Step 5: Final commit**

```bash
git add -A
git commit -m "feat: family sharing — end-to-end shared trees with perspective shifting"
```

---

## Dependency Graph

```
Task 1 (migration) ────→ Task 2 (models) ────→ Task 4 (sharing service) ────→ Task 5 (invite button)
                                                       │                              │
Task 3 (editable name) ──────────────────────────────────                              │
                                                       │                              │
                                                       ↓                              ↓
                                                 Task 7 (perspective tree) ←── Task 6 (join flow)
                                                       │
                                                       ↓
                                                 Task 8 (join notification)
                                                 Task 9 (activity feed)
                                                       │
                                                       ↓
                                                 Task 10 (deploy + verify)
```

**Tasks 1-2:** Foundation (must be first)
**Task 3:** Independent, can parallel with 4
**Tasks 4-7:** Critical path (sequential)
**Tasks 8-9:** Independent polish (can parallel)
**Task 10:** Final verification
