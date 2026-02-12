# Tree-as-Interface — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the family tree canvas the primary interface for adding relatives. Dashed placeholder nodes show gaps. Tap placeholder → contact picker → relative created → tree updates.

**Architecture:** Extends the existing CustomPainter canvas tree (already implemented). New `PlaceholderNode` model slots into `FamilyTreeLayout`. New `PlaceholderSpawnService` computes which placeholders to show. Painter draws dashed circles. Tap handler on tree screen routes placeholder taps to contact picker in single-select mode.

**Tech Stack:** Flutter/Dart, CustomPainter (existing), InteractiveViewer (existing), Riverpod (existing), FamilyGraph model (existing), ContactImportScreen (existing, gains single-select mode)

**Design Doc:** `docs/plans/2026-02-02-tree-as-interface-design.md`

---

## Task 1: PlaceholderNode Data Model

Create the data model for placeholder nodes. Pure data class, no logic.

**Files:**
- Create: `lib/features/family_tree/models/placeholder_node.dart`
- Modify: `lib/features/family_tree/models/tree_layout.dart`
- Test: `test/unit/models/placeholder_node_test.dart`

**Step 1: Write the test**

```dart
// test/unit/models/placeholder_node_test.dart
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/features/family_tree/models/placeholder_node.dart';
import 'package:silni_app/features/family_tree/models/family_graph.dart';
import 'package:silni_app/shared/models/relative_model.dart';

void main() {
  group('PlaceholderNode', () {
    test('stores relationship metadata from tree position', () {
      final placeholder = PlaceholderNode(
        id: 'ph-father',
        type: RelationshipType.father,
        side: null,
        expectedGender: Gender.male,
        parentNodeId: null,
        label: 'أضف أبوك',
        generation: -1,
        position: const Offset(100, 50),
        radius: 30.0,
      );

      expect(placeholder.type, RelationshipType.father);
      expect(placeholder.expectedGender, Gender.male);
      expect(placeholder.side, isNull);
      expect(placeholder.label, 'أضف أبوك');
      expect(placeholder.generation, -1);
    });

    test('carries family side for extended family', () {
      final placeholder = PlaceholderNode(
        id: 'ph-uncle-pat',
        type: RelationshipType.uncle,
        side: FamilySide.paternal,
        expectedGender: Gender.male,
        parentNodeId: 'father-id',
        label: 'عم',
        generation: -1,
        position: const Offset(200, 50),
        radius: 30.0,
      );

      expect(placeholder.side, FamilySide.paternal);
      expect(placeholder.parentNodeId, 'father-id');
    });
  });
}
```

**Step 2: Create PlaceholderNode**

```dart
// lib/features/family_tree/models/placeholder_node.dart
import 'dart:ui';
import '../../../shared/models/relative_model.dart';
import 'family_graph.dart';

/// A dashed placeholder node in the family tree that represents a gap
/// the user can fill by tapping.
///
/// Each placeholder carries all relationship metadata derived from its
/// position in the tree — so the user never needs a relationship picker,
/// side selector, or gender dropdown.
class PlaceholderNode {
  final String id;
  final RelationshipType type;
  final FamilySide? side;
  final Gender? expectedGender;
  final String? parentNodeId;
  final String label;
  final int generation;
  final Offset position;
  final double radius;

  /// Whether this is a small "+" button (for adding more siblings/cousins)
  /// rather than a full labeled placeholder circle.
  final bool isCompact;

  const PlaceholderNode({
    required this.id,
    required this.type,
    this.side,
    this.expectedGender,
    this.parentNodeId,
    required this.label,
    required this.generation,
    required this.position,
    required this.radius,
    this.isCompact = false,
  });

  /// Create a copy with a new position (used by layout service).
  PlaceholderNode copyWithPosition(Offset newPosition) {
    return PlaceholderNode(
      id: id,
      type: type,
      side: side,
      expectedGender: expectedGender,
      parentNodeId: parentNodeId,
      label: label,
      generation: generation,
      position: newPosition,
      radius: radius,
      isCompact: isCompact,
    );
  }
}
```

**Step 3: Extend FamilyTreeLayout**

Add `placeholders` list and `findPlaceholderAtPosition()` to the existing `FamilyTreeLayout` in `tree_layout.dart`:

```dart
// Add to FamilyTreeLayout class:
final List<PlaceholderNode> placeholders;

// Add to constructor with default:
this.placeholders = const [],

// Add hit-test method:
PlaceholderNode? findPlaceholderAtPosition(Offset position) {
  const tapPadding = 10.0;
  for (final ph in placeholders) {
    final distance = (ph.position - position).distance;
    if (distance <= ph.radius + tapPadding) {
      return ph;
    }
  }
  return null;
}
```

**Step 4: Run test → verify pass**

---

## Task 2: PlaceholderSpawnService

Pure static service that takes existing relatives + graph → returns a list of `PlaceholderNode` (without positions — positions are assigned by the layout service in Task 3).

**Files:**
- Create: `lib/features/family_tree/services/placeholder_spawn_service.dart`
- Test: `test/unit/services/placeholder_spawn_service_test.dart`

**Step 1: Write tests**

Cover all spawn rules from the design doc:

```dart
// test/unit/services/placeholder_spawn_service_test.dart
void main() {
  group('PlaceholderSpawnService', () {
    test('empty tree spawns father + mother placeholders', () {
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        userId: 'user-1',
        relatives: [],
        graph: emptyGraph,
      );
      expect(placeholders, hasLength(2));
      expect(placeholders.map((p) => p.type),
          containsAll([RelationshipType.father, RelationshipType.mother]));
    });

    test('adding father spawns paternal grandparents + عم', () {
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        userId: 'user-1',
        relatives: [fatherRelative],
        graph: graphWithFather,
      );
      // Should have: mother (still missing), paternal grandfather,
      // paternal grandmother, عم, sibling
      final types = placeholders.map((p) => p.type).toList();
      expect(types, contains(RelationshipType.mother));
      expect(types, contains(RelationshipType.grandfather));
      expect(types, contains(RelationshipType.grandmother));
      expect(types, contains(RelationshipType.uncle));
      expect(types, contains(RelationshipType.brother)); // or sister
    });

    test('paternal uncle placeholder has FamilySide.paternal', () {
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        userId: 'user-1',
        relatives: [fatherRelative],
        graph: graphWithFather,
      );
      final uncles = placeholders.where((p) =>
          p.type == RelationshipType.uncle);
      expect(uncles.first.side, FamilySide.paternal);
      expect(uncles.first.parentNodeId, fatherRelative.id);
    });

    test('adding maternal uncle spawns his children placeholder', () {
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        userId: 'user-1',
        relatives: [fatherRelative, motherRelative, maternalUncle],
        graph: graphWithMaternalUncle,
      );
      final cousinPh = placeholders.where((p) =>
          p.type == RelationshipType.cousin &&
          p.side == FamilySide.maternal);
      expect(cousinPh, isNotEmpty);
      expect(cousinPh.first.parentNodeId, maternalUncle.id);
    });

    test('first sibling gets full placeholder, second gets compact +', () {
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        userId: 'user-1',
        relatives: [fatherRelative, motherRelative, siblingRelative],
        graph: graphWithSibling,
      );
      final sibPh = placeholders.where((p) =>
          p.type == RelationshipType.brother ||
          p.type == RelationshipType.sister);
      // Should be compact (+ button) since one sibling already exists
      expect(sibPh.first.isCompact, true);
    });

    test('caps at ~15 visible placeholders', () {
      // Full tree with many relatives
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        userId: 'user-1',
        relatives: fullFamilyRelatives,
        graph: fullFamilyGraph,
      );
      expect(placeholders.length, lessThanOrEqualTo(15));
    });
  });
}
```

**Step 2: Implement PlaceholderSpawnService**

```dart
// lib/features/family_tree/services/placeholder_spawn_service.dart

class PlaceholderSpawnService {
  PlaceholderSpawnService._();

  static const _maxPlaceholders = 15;

  static List<PlaceholderNode> computePlaceholders({
    required String userId,
    required List<Relative> relatives,
    required FamilyGraph graph,
  }) {
    final activeRelatives = relatives.where((r) => !r.isArchived).toList();
    final typeSet = activeRelatives.map((r) => r.relationshipType).toSet();
    final relativeIds = activeRelatives.map((r) => r.id).toSet();
    final placeholders = <PlaceholderNode>[];

    // Find specific relatives by type for node spawn logic
    final father = activeRelatives.where((r) =>
        r.relationshipType == RelationshipType.father).firstOrNull;
    final mother = activeRelatives.where((r) =>
        r.relationshipType == RelationshipType.mother).firstOrNull;

    // --- Core spawns (always) ---

    // Parents (if missing)
    if (father == null) {
      placeholders.add(_parent(RelationshipType.father, 'أضف أبوك'));
    }
    if (mother == null) {
      placeholders.add(_parent(RelationshipType.mother, 'أضف أمك'));
    }

    // Siblings (if any parent exists)
    if (father != null || mother != null) {
      final hasSiblings = activeRelatives.any((r) =>
          r.relationshipType == RelationshipType.brother ||
          r.relationshipType == RelationshipType.sister);
      placeholders.add(_sibling(isCompact: hasSiblings));
    }

    // --- Per-parent spawns ---
    if (father != null) {
      _spawnParentBranch(father, FamilySide.paternal, activeRelatives, placeholders);
    }
    if (mother != null) {
      _spawnParentBranch(mother, FamilySide.maternal, activeRelatives, placeholders);
    }

    // --- Uncle/aunt children spawns ---
    for (final relative in activeRelatives) {
      if (_isUncleOrAunt(relative)) {
        _spawnUncleChildren(relative, activeRelatives, placeholders);
      }
    }

    // --- Spouse + children ---
    final hasSpouse = activeRelatives.any((r) =>
        r.relationshipType == RelationshipType.husband ||
        r.relationshipType == RelationshipType.wife);
    if (!hasSpouse) {
      placeholders.add(_spouse(userGender));
    }
    if (hasSpouse) {
      _spawnChildren(activeRelatives, placeholders);
    }

    // Cap
    if (placeholders.length > _maxPlaceholders) {
      return placeholders.sublist(0, _maxPlaceholders);
    }
    return placeholders;
  }

  // Helper methods: _parent, _sibling, _spawnParentBranch,
  // _spawnUncleChildren, _spouse, _spawnChildren, _isUncleOrAunt
  // (each creates PlaceholderNode with correct type/side/gender/label)
}
```

Logic for `_spawnParentBranch`:
- Check if paternal/maternal grandparents exist. If not, add placeholder for grandfather + grandmother with the correct side.
- Check if paternal/maternal uncle/aunt exists. If not, add placeholder. If exists, check for compact `+` for more.

**Step 3: Run tests → verify pass**

---

## Task 3: Layout Integration — Position Placeholders

Extend `FamilyTreeLayoutService.computeLayout()` to position `PlaceholderNode`s adjacent to their parent nodes.

**Files:**
- Modify: `lib/features/family_tree/services/family_tree_layout_service.dart`
- Modify: `test/unit/services/family_tree_layout_service_test.dart`

**Step 1: Write tests**

```dart
test('layout includes positioned placeholders for empty tree', () {
  final layout = FamilyTreeLayoutService.computeLayout(
    userId: 'user-1',
    userName: 'أحمد',
    graph: null,
    relatives: [],
    relativesMap: {},
    canvasSize: const Size(400, 600),
  );
  expect(layout.placeholders, hasLength(2)); // father + mother
  // Father placeholder should be above-left of user
  expect(layout.placeholders[0].position.dy,
      lessThan(layout.userPosition.dy));
});
```

**Step 2: Implement**

After the existing layout steps (spine, side branches, descendants), add:

```dart
// ── N. Generate and position placeholders ──
final rawPlaceholders = PlaceholderSpawnService.computePlaceholders(
  userId: userId,
  relatives: relatives,
  graph: effectiveGraph,
);

final positionedPlaceholders = _positionPlaceholders(
  rawPlaceholders,
  nodePositions,  // Map<String, Offset> from existing layout
  nodeRadius,
  horizontalSpacing,
  verticalSpacing,
);
```

Positioning rules:
- Parent placeholders: above user, split left/right
- Sibling placeholders: same Y as user, offset to the right of rightmost sibling
- Grandparent placeholders: above their parent node, split left/right
- Uncle/aunt placeholders: same Y as parent, offset outward from parent
- Cousin placeholders: below their uncle/aunt parent
- Spouse placeholder: same Y as user, offset to the left
- Children placeholders: below user, offset right of existing children

**Step 3: Run tests → verify pass**

---

## Task 4: Render Placeholders on Canvas

Draw placeholder nodes as dashed circles with labels on the existing canvas.

**Files:**
- Modify: `lib/features/family_tree/painters/family_tree_painter.dart`
- Modify: `lib/features/family_tree/screens/family_tree_screen.dart` (add showPlaceholders flag)

**Step 1: Add placeholder painting to FamilyTreeEdgePainter**

In the `paint()` method, after drawing filled nodes and edges:

```dart
if (showPlaceholders) {
  for (final ph in layout.placeholders) {
    _drawPlaceholder(canvas, ph);
  }
}
```

`_drawPlaceholder` implementation:
- Dashed circle: use `Path` with `dashPath` pattern (or manual arc segments)
- Stroke color: `Colors.white.withOpacity(0.4)` — subtle but visible
- Label: `TextPainter` with Arabic text, centered in circle
- Compact (`+` button): smaller circle, just a "+" text
- Connection line: dashed line from `parentNodeId`'s position to placeholder position

**Step 2: Add `showPlaceholders` to tree screen state**

```dart
bool _showPlaceholders = true;

// In screenshot detection callback:
setState(() => _showPlaceholders = false);
Future.delayed(const Duration(seconds: 3), () {
  if (mounted) setState(() => _showPlaceholders = true);
});
```

Pass `showPlaceholders` to the painter.

**Step 3: Visual verification** — run the app with an empty tree, confirm dashed circles appear at correct positions.

---

## Task 5: Hit-Testing + Tap Handler

Handle taps on placeholder nodes to open the contact picker.

**Files:**
- Modify: `lib/features/family_tree/screens/family_tree_screen.dart`

**Step 1: Extend existing tap handler**

The tree screen already has tap handling for filled nodes (opens overlay). Extend it:

```dart
void _handleTap(Offset canvasPosition) {
  // Check filled nodes first
  final node = layout.findNodeAtPosition(canvasPosition);
  if (node != null) {
    _showNodeOverlay(node);
    return;
  }

  // Check placeholders
  final placeholder = layout.findPlaceholderAtPosition(canvasPosition);
  if (placeholder != null) {
    _handlePlaceholderTap(placeholder);
    return;
  }
}

Future<void> _handlePlaceholderTap(PlaceholderNode placeholder) async {
  HapticFeedback.lightImpact();

  // Open contact picker in single-select mode
  final contact = await Navigator.push<Contact>(
    context,
    MaterialPageRoute(
      builder: (_) => const ContactImportScreen(singleSelect: true),
    ),
  );

  if (contact == null) return; // User cancelled

  // Create relative with auto-filled fields
  await _createRelativeFromPlaceholder(placeholder, contact);
}
```

**Step 2: Implement `_createRelativeFromPlaceholder`**

```dart
Future<void> _createRelativeFromPlaceholder(
  PlaceholderNode placeholder,
  Contact contact,
) async {
  final name = contact.displayName;
  final phone = contact.phones.firstOrNull?.number;
  final email = contact.emails.firstOrNull?.address;

  final gender = placeholder.expectedGender ??
      RelationshipInferenceService.inferGender(name);

  final avatarType = AvatarType.suggestFromRelationship(
    placeholder.type, gender,
  );

  final relative = Relative(
    id: const Uuid().v4(),
    userId: currentUserId,
    name: name,
    phone: phone,
    email: email,
    relationshipType: placeholder.type,
    familySide: placeholder.side,
    gender: gender,
    avatarType: avatarType,
    priority: AvatarType.suggestPriority(placeholder.type),
    // ...other defaults
  );

  // Save to Supabase
  await relativesRepository.addRelative(relative);

  // Infer + persist graph edges
  await familyGraphService.inferEdgesForRelative(relative);

  // Create auto reminders
  await autoReminderService.createAutoReminders(relative);

  // Layout recomputes automatically via Riverpod provider invalidation
}
```

---

## Task 6: Contact Picker Single-Select Mode

Add a `singleSelect` parameter to `ContactImportScreen` so it returns a single contact instead of importing a batch.

**Files:**
- Modify: `lib/features/contacts/screens/contact_import_screen.dart`

**Changes:**

```dart
class ContactImportScreen extends ConsumerStatefulWidget {
  /// When true, the screen acts as a single-contact picker:
  /// - No multi-select checkboxes
  /// - Tapping a contact returns it immediately via Navigator.pop
  /// - No "import all" button
  /// - Search still works
  final bool singleSelect;

  const ContactImportScreen({
    super.key,
    this.singleSelect = false,
  });
}
```

In the contact list item's `onTap`:

```dart
if (widget.singleSelect) {
  Navigator.pop(context, contact);
  return;
}
// ...existing multi-select toggle logic
```

Add a "manual entry" option at the top of the list or as a FAB:

```dart
// At the top of the contact list, before actual contacts:
ListTile(
  leading: Icon(Icons.edit, color: AppColors.islamicGreenLight),
  title: Text('أدخل الاسم يدوي'),
  onTap: () => _showManualEntryDialog(context),
)
```

Manual entry dialog returns a synthetic `Contact` with just a name (no phone).

---

## Task 7: User Gender Determination

Determine the user's gender for correct spouse placeholder labeling.

**Files:**
- Modify: `lib/features/family_tree/screens/family_tree_screen.dart`
- Modify: `lib/features/family_tree/services/placeholder_spawn_service.dart`

**Step 1: Infer from user's name**

```dart
// In tree screen or a provider:
Gender? _resolveUserGender(String userName, UserProfile profile) {
  // Check if already stored in profile
  if (profile.gender != null) return profile.gender;

  // Try inference
  return RelationshipInferenceService.inferGender(userName);
}
```

**Step 2: Ask if ambiguous**

If gender is `null` after inference, show a one-time bottom sheet on the tree screen:

```dart
void _askUserGender() {
  showModalBottomSheet(
    context: context,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('حدد جنسك لتخصيص الشجرة', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _genderButton('ذكر', Gender.male)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _genderButton('أنثى', Gender.female)),
            ],
          ),
        ],
      ),
    ),
  );
}
```

Store in user profile via Supabase. Never ask again.

**Step 3: Pass to PlaceholderSpawnService**

```dart
static List<PlaceholderNode> computePlaceholders({
  required String userId,
  required List<Relative> relatives,
  required FamilyGraph graph,
  required Gender? userGender, // NEW
}) {
  // Use userGender for spouse placeholder label
}
```

---

## Task 8: Animations

Add fill, spawn, and pulse animations for placeholder interactions.

**Files:**
- Modify: `lib/features/family_tree/screens/family_tree_screen.dart`
- Modify: `lib/features/family_tree/painters/family_tree_painter.dart`

**Step 1: Guided pulse**

One placeholder pulses to guide attention — the one `RelationshipInferenceService.suggestRelationships()` would recommend first. Drive with existing `AnimationController` (the tree already has one for health pulse).

```dart
// In painter, for the "priority" placeholder:
final pulseOpacity = 0.4 + 0.3 * sin(animationValue * 2 * pi);
// Draw with this opacity instead of fixed 0.4
```

**Step 2: Node fill animation**

When a placeholder becomes a filled node:
1. Track `_recentlyFilledNodeId` in state
2. For that node, run a 500ms spring animation:
   - Scale: 0.0 → 1.05 → 1.0
   - Opacity: 0.0 → 1.0
   - Dashed stroke morphs to solid

**Step 3: New placeholder spawn animation**

When new placeholders appear after a fill:
1. Track `_recentPlaceholderIds` in state
2. Staggered fade-in: each placeholder delays 50ms after the previous
3. Scale: 0.5 → 1.0 with spring curve
4. Dashed connection line draws progressively (stroke dash offset animation)

---

## Task 9: Export Mode — Hide Placeholders

Ensure placeholders disappear during screenshot/export.

**Files:**
- Modify: `lib/features/family_tree/screens/family_tree_screen.dart`

**Already partially implemented:** The tree screen has `_showWatermark` logic for screenshot detection. Extend:

```dart
void _initScreenshotDetection() {
  _screenshotCallback.addListener(() {
    if (mounted) {
      setState(() {
        _showWatermark = true;
        _showPlaceholders = false; // NEW: hide placeholders
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showWatermark = false;
            _showPlaceholders = true; // NEW: restore
          });
        }
      });
    }
  });
}
```

For manual "share" export: set `_showPlaceholders = false` before capturing the tree image, restore after.

---

## Task 10: FAB Fallback

Add a floating action button for edge-case additions.

**Files:**
- Modify: `lib/features/family_tree/screens/family_tree_screen.dart`

**Implementation:**

Small FAB in the bottom corner of the tree screen:

```dart
FloatingActionButton.small(
  onPressed: _showFallbackAddSheet,
  backgroundColor: AppColors.islamicGreenDark,
  child: const Icon(Icons.add, color: Colors.white),
)
```

`_showFallbackAddSheet` opens a bottom sheet with `SmartRelationshipPicker` (already built). After selecting a type, opens contact picker. Creates relative with the selected type + contact. This covers `RelationshipType.other` and out-of-order additions.

---

## Task Order & Dependencies

```
Task 1 (model)
  → Task 2 (spawn service) [depends on model]
    → Task 3 (layout integration) [depends on spawn service]
      → Task 4 (render) [depends on layout]
        → Task 8 (animations) [depends on render]
        → Task 9 (export mode) [depends on render]
Task 6 (single-select picker) [independent]
Task 7 (user gender) [independent]
Task 5 (tap handler) [depends on Task 4 + Task 6]
Task 10 (FAB fallback) [depends on Task 5]
```

Parallelizable: Tasks 1, 6, 7 can all start simultaneously. Tasks 8, 9 can be done in parallel after Task 4.
