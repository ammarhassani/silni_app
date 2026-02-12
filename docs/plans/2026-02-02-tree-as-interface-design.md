# Tree-as-Interface: Adding Relatives Through the Family Tree

**Date:** 2026-02-02
**Status:** Draft
**Scope:** Replace the form-based add-relative flow with an interactive tree where placeholder nodes ARE the add interface
**Builds on:** `2026-02-02-family-tree-rewrite-design.md` (CustomPainter canvas, spine-based layout)

---

## Problem

Adding relatives in Silni is painful:

1. **12-field form** (`add_relative_screen.dart`): name, photo, avatar, relationship type, family side, gender, phone, email, priority, favorite, health status, notes. Feels like paperwork.
2. **Contact import dialog** (`relationship_specification_dialog.dart`): after importing contacts, user must assign all 16 relationship types as tiny chips for EACH contact individually.
3. **Too many taps to start**: navigate to Add Relative screen → choose manual or import → fill form or assign per-contact relationships.
4. **Redundant questions**: the app asks for relationship type, family side, AND gender — when position in the tree already answers all three.

The intelligence-and-growth design doc states: *"Every time the app asks the user a question, that is a failure."*

---

## Core Concept

**The family tree canvas IS the add-relative interface.**

Dashed placeholder nodes appear in the tree showing where relatives belong. Each placeholder carries all relationship metadata (type, side, expected gender) based on its position. Tap a placeholder → phone contacts picker opens → pick a contact → node fills in → new placeholders animate in for the next natural connections.

No relationship picker. No side selector. No gender dropdown. Two taps to add a relative.

---

## Section 1: Placeholder Nodes

### Data Model

Every dashed circle in the tree is not just visual — it's a data object that knows what it represents:

```dart
class PlaceholderNode {
  /// Unique ID for this placeholder slot.
  final String id;

  /// The relationship type this slot expects (father, uncle, cousin...).
  final RelationshipType type;

  /// Paternal or maternal — determined by which parent branch this hangs from.
  final FamilySide? side;

  /// Expected gender — male for عم, female for خالة, null if either.
  final Gender? expectedGender;

  /// The existing relative whose node spawned this placeholder.
  /// e.g. father's node spawns the عم placeholder, so parentNodeId = father's ID.
  final String? parentNodeId;

  /// Arabic label shown inside the dashed circle.
  /// e.g. "أضف أبوك", "أضف عمك", "أضف أبناء خالك"
  final String label;

  /// Generation level in the tree (same system as LayoutNode).
  final int generation;

  /// Position computed by the layout service (same coordinate system as LayoutNode).
  final Offset position;
}
```

### Layout Integration

`PlaceholderNode` integrates with the existing `FamilyTreeLayout`:

```dart
class FamilyTreeLayout {
  final List<LayoutNode> nodes;          // existing filled nodes
  final List<PlaceholderNode> placeholders; // NEW: dashed placeholder nodes
  final List<LayoutEdge> edges;
  final List<LayoutJunction> junctions;
  final Rect bounds;
  final Offset userPosition;
}
```

The `FamilyTreeLayoutService.computeLayout()` method gains a new step after positioning filled nodes: it computes positions for placeholders based on node spawn rules (Section 2) and positions them adjacent to their parent node using the same spacing constants.

### Visual Rendering

The `FamilyTreeEdgePainter` draws placeholders as:
- Dashed-stroke circle (no fill) with white dashed border
- Label text centered inside (Arabic, `AppTypography.labelSmall`)
- Connection line from parent node to placeholder (dashed, same soft blue-gray as other edges)
- Subtle pulse animation on the "next suggested" placeholder to guide the user

Hit-testing extends `FamilyTreeLayout.findNodeAtPosition()` to also check placeholders.

---

## Section 2: Node Spawn Rules

Each filled node independently spawns its natural connections as placeholders. This is **per-node**, not per-level — branches grow independently.

### Spawn Table

| When you fill...           | Placeholders that appear                                                |
|----------------------------|-------------------------------------------------------------------------|
| (empty tree)               | أضف أبوك (father), أضف أمك (mother)                                      |
| Father                     | جد أبوي (paternal grandfather), جدة أبوية (paternal grandmother), عم (paternal uncle) |
| Mother                     | جد أمي (maternal grandfather), جدة أمية (maternal grandmother), خال (maternal uncle) |
| Any one parent exists       | أخ/أخت (sibling placeholder at user's level)                           |
| Father + Mother both exist  | (sibling placeholder already there from above)                         |
| Paternal uncle (عم)         | أبناء العم (his children = paternal cousins)                            |
| Maternal uncle (خال)        | أبناء الخال (his children = maternal cousins)                           |
| Paternal aunt (عمة)         | أبناءها (her children = paternal cousins)                               |
| Maternal aunt (خالة)        | أبناءها (her children = maternal cousins)                               |
| Paternal grandfather        | `+` button to extend upward (great-grandparents), عم الأب (great-uncle) |
| Maternal grandfather        | `+` button to extend upward, خال الأم (great-uncle)                     |
| Spouse (added next to YOU)  | ابنك/بنتك (children placeholders below user+spouse)                     |

### Siblings Pattern

- When first parent is added, one full-sized "أضف أخوك/أختك" placeholder appears at the user's generation level.
- After the first sibling is filled, the full placeholder is replaced with a small `+` icon next to the sibling nodes. Tap `+` → contact picker → another sibling node appears.
- Same `+` pattern for multiple uncles, multiple cousins, etc.

### Uncle/Aunt Split

Uncles and aunts are NEVER shown as generic "uncle/aunt" placeholders. They are always pre-split by side:
- Father's node spawns: عم (paternal uncle) — `FamilySide.paternal` auto-set
- Mother's node spawns: خال (maternal uncle) — `FamilySide.maternal` auto-set
- Same for عمة (paternal aunt) vs خالة (maternal aunt)

This eliminates the "من طرف أبوك ولا أمك؟" follow-up question entirely.

### Depth Control

- Default depth: 2 generations up (parents + grandparents).
- Each grandparent node shows a `+` button to manually extend upward (great-grandparents, great-uncles). This keeps the tree manageable by default while allowing unlimited depth.
- Downward: children appear after spouse is added. Their children (grandchildren) follow the same `+` extension pattern.

---

## Section 3: Tap → Contact Picker → Done

### The Flow (2 taps)

1. User taps a dashed placeholder circle on the tree canvas
2. Contact picker opens in **single-select mode** (same `ContactImportScreen` but configured for single selection)
3. User picks a contact (or taps "manual entry" to type a name)
4. A `Relative` is created with fields auto-filled:

| Field              | Source                                                               |
|--------------------|----------------------------------------------------------------------|
| `name`             | Contact's display name                                               |
| `phone`            | Contact's first phone number (intl format)                           |
| `email`            | Contact's first email (if available)                                 |
| `relationshipType` | From `PlaceholderNode.type`                                          |
| `familySide`       | From `PlaceholderNode.side`                                          |
| `gender`           | From `PlaceholderNode.expectedGender`, or inferred via `RelationshipInferenceService.inferGender(name)` |
| `avatarType`       | Via `AvatarType.suggestFromRelationship(type, gender)`               |
| `priority`         | Via `AvatarType.suggestPriority(type)`                               |
| `isFavorite`       | `false` (default)                                                    |

5. Node fills in the tree with a spring animation
6. New placeholders animate in for the next natural connections
7. `FamilyGraphService` infers and persists graph edges automatically (already implemented)
8. `AutoReminderService` creates a reminder based on relationship type (already implemented)

### What Happens to the 12-Field Form?

- **Eliminated from the primary flow.** Adding a relative = tap placeholder + pick contact.
- Optional fields (health status, notes, custom avatar, email) are accessible from the relative's **profile/detail screen** after adding. Not during.
- The old `AddRelativeScreen` is kept as a fallback for edge cases only (see Section 6).

---

## Section 4: Placeholders Are Permanent

Placeholders are **always visible** in the tree. There is no "onboarding mode" vs "normal mode". The tree always shows gaps.

### The Only Exception: Export/Screenshot Mode

When the user:
- Takes a screenshot (detected via `ScreenshotCallback`, already implemented)
- Taps "share" or "export"

All placeholder nodes and their dashed connection lines are hidden. Only filled nodes render. This produces a clean, shareable family tree image.

Implementation: `FamilyTreeEdgePainter` and the node rendering layer check a `bool showPlaceholders` flag. Default `true`, set to `false` during export/screenshot.

---

## Section 5: User Gender Determination

The spouse placeholder label depends on the user's gender:
- Male user → "أضف زوجتك" (add your wife), spouse expected gender = female
- Female user → "أضف زوجك" (add your husband), spouse expected gender = male

Also affects sibling labels: "أضف أخوك" vs "أضف أختك" (though siblings can be either gender).

### Approach: Infer First, Ask If Needed

1. **Try `RelationshipInferenceService.inferGender(userName)`** — the service already handles Arabic name patterns (40+ male names, 30+ female names, ة ending = female, عبد prefix = male).
2. **If ambiguous** (returns `null`): show a one-time, simple prompt the first time the tree screen opens: two buttons, "ذكر" (male) and "أنثى" (female). Store in user profile. Never ask again.

No dropdowns, no third options. Male and female.

---

## Section 6: Fallback — Generic Add Button

A floating `+` button on the tree screen handles edge cases that don't fit the tree structure:

- `RelationshipType.other` (custom relationships)
- Relationships the user wants to add out of order
- Any relative type not currently shown as a placeholder

Tapping the FAB opens a minimal bottom sheet with the existing `SmartRelationshipPicker` (already built), then contact picker. This is the escape hatch, not the primary flow.

---

## Section 7: Animations

### Node Fill Animation
When a contact is picked and a placeholder becomes a real node:
1. Dashed circle morphs to solid (stroke animates from dashed to solid)
2. Circle fills with the avatar background color (scale from 0→1)
3. Emoji fades in with a subtle bounce
4. Name label types in character by character (Arabic RTL)
5. Spring overshoot on the whole node (scale 0.8→1.05→1.0)

### New Placeholder Animation
When new placeholders appear after a node is filled:
1. Fade in from 0% opacity
2. Scale from 0.5→1.0 with spring curve
3. Dashed connection line draws itself from parent to placeholder (stroke animation)
4. Staggered delay between multiple new placeholders (50ms each)

### Guided Pulse
The "next suggested" placeholder has a subtle breathing pulse (opacity 0.6→1.0→0.6, repeating) to guide the user's attention. Only one placeholder pulses at a time — the one `RelationshipInferenceService.suggestRelationships()` would recommend first.

### Export Transition
When entering screenshot/export mode:
- All placeholders fade out simultaneously (200ms)
- Tree auto-centers on filled nodes
- Watermark fades in (already implemented)

---

## Section 8: Architecture & File Impact

### New Files

| File | Purpose |
|------|---------|
| `lib/features/family_tree/models/placeholder_node.dart` | `PlaceholderNode` data model |
| `lib/features/family_tree/services/placeholder_spawn_service.dart` | Pure static service: given filled nodes + graph → compute which placeholders to show |
| `lib/features/family_tree/painters/placeholder_painter.dart` | Draws dashed circles, labels, pulse animation (or integrate into existing `FamilyTreeEdgePainter`) |

### Modified Files

| File | Changes |
|------|---------|
| `lib/features/family_tree/models/tree_layout.dart` | Add `List<PlaceholderNode> placeholders` to `FamilyTreeLayout`. Add `findPlaceholderAtPosition()` hit-test method. |
| `lib/features/family_tree/services/family_tree_layout_service.dart` | New step in `computeLayout()`: call `PlaceholderSpawnService` to generate placeholders, then position them adjacent to their parent nodes using same spacing. |
| `lib/features/family_tree/painters/family_tree_painter.dart` | Draw placeholder nodes (dashed circles + labels) and dashed connection lines. Check `showPlaceholders` flag. |
| `lib/features/family_tree/screens/family_tree_screen.dart` | Handle tap on placeholder → open contact picker in single-select mode → create `Relative` with auto-filled fields → persist → refresh tree. Add `showPlaceholders` flag toggled during screenshot detection. |
| `lib/features/family_tree/widgets/tree_node_widget.dart` | No changes if placeholders are painted on canvas. If placeholders are Flutter widgets overlaid (like `TreeNodeWidget`), add a `PlaceholderNodeWidget`. |
| `lib/features/contacts/screens/contact_import_screen.dart` | Add single-select mode: `ContactImportScreen(singleSelect: true)` that returns one contact instead of a list. |
| `lib/features/relatives/services/relationship_inference_service.dart` | Already works as-is. Used for gender inference from names and guiding the pulse animation priority. |

### Unchanged

- `add_relative_screen.dart` — kept as fallback but no longer the primary flow
- `smart_relationship_picker.dart` — used in the FAB fallback flow
- `relationship_specification_dialog.dart` — no longer needed for the primary flow

### Data Flow

```
User taps placeholder
  → PlaceholderNode carries { type, side, expectedGender, label }
  → ContactImportScreen opens (single-select)
  → User picks contact
  → Relative created:
      name = contact.displayName
      phone = contact.phones.first
      relationshipType = placeholder.type
      familySide = placeholder.side
      gender = placeholder.expectedGender ?? inferGender(name)
      avatarType = suggestFromRelationship(type, gender)
      priority = suggestPriority(type)
  → Relative saved to Supabase
  → FamilyGraphService.inferEdges() creates graph edges
  → AutoReminderService.createAutoReminders() schedules reminders
  → FamilyTreeLayoutService.computeLayout() recomputes
  → PlaceholderSpawnService generates new placeholders
  → Tree repaints with filled node + new placeholders
```

---

## Section 9: Edge Cases

| Scenario | Behavior |
|----------|----------|
| User has no contacts on phone | Contact picker shows empty state with "أدخل الاسم يدوي" (manual entry) text field |
| User picks same contact twice | Duplicate check on phone number before creating Relative. Show "هالشخص موجود بالفعل" |
| Name gender inference fails | Fall back to `PlaceholderNode.expectedGender`. If that's also null (e.g., sibling placeholder), accept either gender — no prompt. |
| User skips parents, wants to add uncle directly | Uncle placeholders only appear after a parent is filled (since uncle = parent's sibling). Use FAB fallback for out-of-order additions. |
| Tree has 50+ nodes + many placeholders | Layout service caps visible placeholders to prevent clutter. Show `+` buttons for deep branches instead of full placeholder circles. Cap: ~15 visible placeholders max. |
| User deletes a filled node | Re-evaluate spawn rules. If father is deleted, paternal grandparent and عم placeholders return to hidden (they depend on father existing). Sibling placeholder stays if mother exists. |

---

## Summary

The family tree stops being a read-only visualization and becomes the primary interface for building your family. Every gap is a tappable invitation. Every tap is two steps from a filled node. The app never asks a question it can answer from context.
