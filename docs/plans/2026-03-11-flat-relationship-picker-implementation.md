# Flat Relationship Picker Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace all relationship pickers with a single unified `FlatRelationshipPicker` widget where every card maps to exactly one (type, side, gender) tuple — one tap, zero ambiguity.

**Architecture:** Create a new `FlatRelationshipPicker` widget with a data-driven card grid grouped by generation. Each card is a `RelationshipEntry` record holding type+side+gender+label+emoji. The widget replaces `SmartRelationshipPicker` in add_relative_screen and family_tree_screen, and replaces the inline selector in `RelationshipSpecificationDialog`. Singleton hiding logic filters out already-filled slots.

**Tech Stack:** Flutter, Dart records, flutter_animate, GlassCard

---

### Task 1: Create the FlatRelationshipPicker widget

**Files:**
- Create: `lib/shared/widgets/flat_relationship_picker.dart`

**Step 1: Create the complete widget file**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../models/relative_model.dart';
import '../../features/family_tree/models/family_graph.dart';

/// A single entry in the flat relationship picker grid.
/// Each entry maps to exactly one (type, side, gender) tuple.
typedef RelationshipEntry = ({
  RelationshipType type,
  FamilySide? side,
  Gender? gender,
  String label,
  String emoji,
});

/// A section grouping entries under a header label.
typedef _Section = ({String header, List<RelationshipEntry> entries});

/// All possible relationship entries, grouped by generation.
/// Order matters — this is the display order.
List<_Section> _buildSections() {
  return [
    (
      header: 'الأهل',
      entries: [
        (type: RelationshipType.father, side: null, gender: Gender.male, label: 'أب', emoji: '🧔'),
        (type: RelationshipType.mother, side: null, gender: Gender.female, label: 'أم', emoji: '🧕'),
        (type: RelationshipType.grandfather, side: FamilySide.paternal, gender: Gender.male, label: 'جد أبوي', emoji: '👴'),
        (type: RelationshipType.grandmother, side: FamilySide.paternal, gender: Gender.female, label: 'جدة أبوية', emoji: '👵'),
        (type: RelationshipType.grandfather, side: FamilySide.maternal, gender: Gender.male, label: 'جد أمي', emoji: '👴'),
        (type: RelationshipType.grandmother, side: FamilySide.maternal, gender: Gender.female, label: 'جدة أمية', emoji: '👵'),
      ],
    ),
    (
      header: 'الزوج',
      entries: [
        (type: RelationshipType.husband, side: null, gender: Gender.male, label: 'زوج', emoji: '🧔'),
        (type: RelationshipType.wife, side: null, gender: Gender.female, label: 'زوجة', emoji: '🧕'),
      ],
    ),
    (
      header: 'الإخوان',
      entries: [
        (type: RelationshipType.brother, side: null, gender: Gender.male, label: 'أخ', emoji: '👨'),
        (type: RelationshipType.sister, side: null, gender: Gender.female, label: 'أخت', emoji: '🧕'),
      ],
    ),
    (
      header: 'الأعمام والأخوال',
      entries: [
        (type: RelationshipType.uncle, side: FamilySide.paternal, gender: Gender.male, label: 'عم', emoji: '🧔'),
        (type: RelationshipType.uncle, side: FamilySide.maternal, gender: Gender.male, label: 'خال', emoji: '🧔'),
        (type: RelationshipType.aunt, side: FamilySide.paternal, gender: Gender.female, label: 'عمة', emoji: '🧕'),
        (type: RelationshipType.aunt, side: FamilySide.maternal, gender: Gender.female, label: 'خالة', emoji: '🧕'),
      ],
    ),
    (
      header: 'أبناء العم والخال',
      entries: [
        (type: RelationshipType.cousin, side: FamilySide.paternal, gender: Gender.male, label: 'ابن العم', emoji: '👨'),
        (type: RelationshipType.cousin, side: FamilySide.paternal, gender: Gender.female, label: 'بنت العم', emoji: '👩'),
        (type: RelationshipType.cousin, side: FamilySide.maternal, gender: Gender.male, label: 'ابن الخال', emoji: '👨'),
        (type: RelationshipType.cousin, side: FamilySide.maternal, gender: Gender.female, label: 'بنت الخال', emoji: '👩'),
      ],
    ),
    (
      header: 'الأبناء',
      entries: [
        (type: RelationshipType.son, side: null, gender: Gender.male, label: 'ابن', emoji: '👦'),
        (type: RelationshipType.daughter, side: null, gender: Gender.female, label: 'ابنة', emoji: '👧'),
      ],
    ),
    (
      header: 'أبناء الإخوان',
      entries: [
        (type: RelationshipType.nephew, side: null, gender: Gender.male, label: 'ابن أخ/أخت', emoji: '🧑'),
        (type: RelationshipType.niece, side: null, gender: Gender.female, label: 'ابنة أخ/أخت', emoji: '👧'),
      ],
    ),
    (
      header: 'أخرى',
      entries: [
        (type: RelationshipType.other, side: null, gender: null, label: 'أخرى', emoji: '👤'),
      ],
    ),
  ];
}

/// Relationship types that can only exist once total.
const _singletonTypes = {
  RelationshipType.father,
  RelationshipType.mother,
  RelationshipType.husband,
  RelationshipType.wife,
};

/// Types that exist once per family side (paternal + maternal = 2 max).
const _perSideSingletonTypes = {
  RelationshipType.grandfather,
  RelationshipType.grandmother,
};

/// A flat, visual relationship picker where every card maps to exactly one
/// (type, side, gender) tuple. One tap, zero ambiguity.
///
/// Used in add-relative, contact-import, and family-tree flows.
class FlatRelationshipPicker extends StatelessWidget {
  const FlatRelationshipPicker({
    super.key,
    required this.selectedType,
    required this.onSelectionChanged,
    this.selectedSide,
    this.selectedGender,
    this.existingRelatives = const [],
  });

  final RelationshipType selectedType;
  final FamilySide? selectedSide;
  final Gender? selectedGender;
  final List<Relative> existingRelatives;
  final void Function(RelationshipType type, FamilySide? side, Gender? gender) onSelectionChanged;

  /// Entries that should be hidden because the slot is already filled.
  Set<RelationshipEntry> _hiddenEntries(List<_Section> sections) {
    final hidden = <RelationshipEntry>{};
    final existingTypes = existingRelatives.map((r) => r.relationshipType).toSet();

    for (final section in sections) {
      for (final entry in section.entries) {
        // Simple singletons: hide if type already exists
        if (_singletonTypes.contains(entry.type) && existingTypes.contains(entry.type)) {
          hidden.add(entry);
          continue;
        }

        // Per-side singletons: hide if this specific (type, side) is filled
        if (_perSideSingletonTypes.contains(entry.type)) {
          final filled = existingRelatives.any(
            (r) => r.relationshipType == entry.type && r.familySide == entry.side,
          );
          if (filled) hidden.add(entry);
        }
      }
    }
    return hidden;
  }

  bool _isSelected(RelationshipEntry entry) {
    if (entry.type != selectedType) return false;
    if (entry.side != null && entry.side != selectedSide) return false;
    if (entry.gender != null && entry.gender != selectedGender) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections();
    final hidden = _hiddenEntries(sections);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in sections) ...[
          // Filter out hidden entries for this section
          if (section.entries.any((e) => !hidden.contains(e))) ...[
            // Section header
            Padding(
              padding: const EdgeInsets.only(
                bottom: AppSpacing.xs,
                top: AppSpacing.sm,
              ),
              child: Text(
                section.header,
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),

            // Card grid (3 columns)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.3,
              children: [
                for (final (i, entry) in section.entries.where((e) => !hidden.contains(e)).indexed)
                  _RelationshipCard(
                    entry: entry,
                    isSelected: _isSelected(entry),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onSelectionChanged(entry.type, entry.side, entry.gender);
                    },
                    animationDelay: Duration(milliseconds: 30 * i),
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

class _RelationshipCard extends StatelessWidget {
  const _RelationshipCard({
    required this.entry,
    required this.isSelected,
    required this.onTap,
    required this.animationDelay,
  });

  final RelationshipEntry entry;
  final bool isSelected;
  final VoidCallback onTap;
  final Duration animationDelay;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        curve: AppAnimations.toggleCurve,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppColors.islamicGreenLight
                : Colors.white.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.islamicGreenPrimary.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              entry.emoji,
              style: TextStyle(fontSize: isSelected ? 26 : 22),
            ),
            const SizedBox(height: 4),
            Text(
              entry.label,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    )
        .animate(delay: animationDelay)
        .fadeIn(duration: AppAnimations.normal)
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          duration: AppAnimations.normal,
        );
  }
}
```

**Step 2: Verify compilation**

Run: `flutter analyze lib/shared/widgets/flat_relationship_picker.dart`
Expected: No errors

---

### Task 2: Replace SmartRelationshipPicker in add_relative_screen

**Files:**
- Modify: `lib/features/relatives/screens/add_relative_screen.dart`

**Step 1: Update import**

Replace the SmartRelationshipPicker import with FlatRelationshipPicker:

```dart
// Remove:
import '../../relatives/widgets/smart_relationship_picker.dart';
// Add:
import '../../../shared/widgets/flat_relationship_picker.dart';
```

Note: The exact import path may differ — search for `smart_relationship_picker` in the imports.

**Step 2: Replace the SmartRelationshipPicker widget (~line 462-479)**

Replace:
```dart
                        SmartRelationshipPicker(
                          selected: _selectedRelationship,
                          suggestions: suggestions,
                          existingRelatives: existingRelatives,
                          selectedSide: _selectedFamilySide,
                          onSelectionChanged: (type, side) {
                            setState(() {
                              final typeChanged = type != _selectedRelationship;
                              _selectedRelationship = type;
                              _selectedFamilySide = side;
                              if (typeChanged) {
                                _selectedGender =
                                    RelationshipInferenceService.genderFromRelationship(type);
                                _priority = AvatarType.suggestPriority(type);
                              }
                            });
                          },
                        ),
```

With:
```dart
                        FlatRelationshipPicker(
                          selectedType: _selectedRelationship,
                          selectedSide: _selectedFamilySide,
                          selectedGender: _selectedGender,
                          existingRelatives: existingRelatives,
                          onSelectionChanged: (type, side, gender) {
                            setState(() {
                              _selectedRelationship = type;
                              _selectedFamilySide = side;
                              if (gender != null) _selectedGender = gender;
                              _priority = AvatarType.suggestPriority(type);
                            });
                          },
                        ),
```

**Step 3: Remove the `_sideRequiredTypes` constant and side validation**

The side validation near line 172 is no longer needed — the picker cards already bake in the correct side. Remove:

```dart
/// Relationship types that require a family side selection.
const _sideRequiredTypes = {
  RelationshipType.uncle,
  RelationshipType.aunt,
  RelationshipType.cousin,
  RelationshipType.grandfather,
  RelationshipType.grandmother,
};
```

And remove the validation block:
```dart
      // Validate family side for extended family types
      if (_sideRequiredTypes.contains(_selectedRelationship) && _selectedFamilySide == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('اختر من طرف أبوك ولا أمك'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
```

**Step 4: Clean up unused imports**

Remove unused imports for `SmartRelationshipPicker`, `RelationshipInferenceService.suggestRelationships`, and the `suggestions` variable if it's no longer used elsewhere in the file. Check the file for other uses first.

**Step 5: Verify compilation**

Run: `flutter analyze lib/features/relatives/screens/add_relative_screen.dart`
Expected: No errors

---

### Task 3: Replace SmartRelationshipPicker in family_tree_screen

**Files:**
- Modify: `lib/features/family_tree/screens/family_tree_screen.dart`

**Step 1: Update import**

Replace the SmartRelationshipPicker import:

```dart
// Remove:
import '../../relatives/widgets/smart_relationship_picker.dart';
// Add:
import '../../../shared/widgets/flat_relationship_picker.dart';
```

**Step 2: Replace the picker in the bottom sheet (~line 731-742)**

Find the `SmartRelationshipPicker` usage inside the `showModalBottomSheet`. Replace:

```dart
                      child: SmartRelationshipPicker(
                        selected: selectedType ?? (suggestions.isNotEmpty ? suggestions.first : RelationshipType.other),
                        suggestions: suggestions,
                        existingRelatives: relatives,
                        selectedSide: selectedSide,
                        onSelectionChanged: (type, side) {
                          setSheetState(() {
                            selectedType = type;
                            selectedSide = side;
                          });
                        },
                      ),
```

With:

```dart
                      child: FlatRelationshipPicker(
                        selectedType: selectedType ?? RelationshipType.other,
                        selectedSide: selectedSide,
                        selectedGender: selectedGender,
                        existingRelatives: relatives,
                        onSelectionChanged: (type, side, gender) {
                          setSheetState(() {
                            selectedType = type;
                            selectedSide = side;
                            selectedGender = gender;
                          });
                        },
                      ),
```

Also add `Gender? selectedGender;` next to the existing `selectedType` and `selectedSide` declarations (~line 701-702).

**Step 3: Pass selectedGender to PlaceholderNode (~line 805)**

The `expectedGender` field should use `selectedGender` instead of inferring from name:

```dart
    final gender = selectedGender ?? RelationshipInferenceService.inferGender(fullName.trim());
```

**Step 4: Clean up unused `suggestions` variable**

If `suggestions` is no longer used anywhere after removing SmartRelationshipPicker, remove the line:
```dart
    final suggestions =
        RelationshipInferenceService.suggestRelationships(relatives);
```

**Step 5: Verify compilation**

Run: `flutter analyze lib/features/family_tree/screens/family_tree_screen.dart`
Expected: No errors (info-level warnings OK)

---

### Task 4: Replace inline selector in RelationshipSpecificationDialog

**Files:**
- Modify: `lib/shared/widgets/relationship_specification_dialog.dart`

**Step 1: Add import**

```dart
import 'flat_relationship_picker.dart';
```

**Step 2: Replace `_buildRelationshipSelector` calls and remove side/gender selectors**

In `_buildContactCard` (around line 284-311), replace the relationship selector + side selector + gender selector sections with a single `FlatRelationshipPicker`:

Replace everything from `_buildRelationshipSelector(index, relationshipType, themeColors)` through the end of the gender selector block with:

```dart
          FlatRelationshipPicker(
            selectedType: relationshipType,
            selectedSide: contactWithRel.familySide,
            selectedGender: gender,
            existingRelatives: const [], // No singleton hiding in import flow
            onSelectionChanged: (type, side, pickerGender) {
              setState(() {
                _contactsWithRelationship[index].relationshipType = type;
                _contactsWithRelationship[index].familySide = side;
                _contactsWithRelationship[index].gender = pickerGender;
              });
            },
          ),
```

Keep the "custom relationship" text field for `RelationshipType.other`.

**Step 3: Delete dead code**

Remove these methods that are no longer called:
- `_buildRelationshipSelector`
- `_buildFamilySideSelector`
- `_buildGenderSelector`
- `_getRelationshipArabicName`
- `_updateRelationshipType`
- `_updateFamilySide`
- `_updateGender`

Remove these constants that are no longer used:
- `_extendedFamilyTypes`
- `_splitFamilyTypes`

**Step 4: Verify compilation**

Run: `flutter analyze lib/shared/widgets/relationship_specification_dialog.dart`
Expected: No errors

---

### Task 5: Delete SmartRelationshipPicker

**Files:**
- Delete: `lib/features/relatives/widgets/smart_relationship_picker.dart`

**Step 1: Verify no remaining references**

Run: `grep -r "SmartRelationshipPicker\|smart_relationship_picker" lib/`
Expected: No matches

**Step 2: Delete the file**

```bash
rm lib/features/relatives/widgets/smart_relationship_picker.dart
```

**Step 3: Full project analysis**

Run: `flutter analyze lib/`
Expected: No errors (info-level warnings OK)

---

### Task 6: Verify and commit

**Step 1: Hot restart the app**

**Step 2: Test add-relative flow**

- Tap add relative → see flat grid with all cards grouped by generation
- Tap "خالة" → card highlights with gradient glow
- Save → verify detail screen shows "خالة" label
- Tap "ابن الخال" → card highlights, save → verify label shows "ابن الخال"
- Try to add father when father already exists → أب card should be hidden

**Step 3: Test contact import flow**

- Import a contact → relationship specification dialog shows same flat grid
- Select "عم" → save → verify label shows "عم" on relatives list

**Step 4: Test family tree flow**

- Tap FAB on family tree → bottom sheet shows flat grid
- Select relationship → confirm → contact picker → verify correct type/side/gender saved

**Step 5: Commit**

```bash
git add lib/shared/widgets/flat_relationship_picker.dart \
       lib/features/relatives/screens/add_relative_screen.dart \
       lib/features/family_tree/screens/family_tree_screen.dart \
       lib/shared/widgets/relationship_specification_dialog.dart \
       lib/features/contacts/screens/contact_import_screen.dart \
       docs/plans/2026-03-11-flat-relationship-picker-design.md \
       docs/plans/2026-03-11-flat-relationship-picker-implementation.md
git rm lib/features/relatives/widgets/smart_relationship_picker.dart
git commit -m "feat: replace relationship pickers with unified flat visual grid

Flatten all relationship choices into distinct cards (عم, خال, عمة, خالة, etc.)
grouped by generation. Each card maps to exactly one (type, side, gender) tuple.
Eliminates side picker, gender picker, and show-all toggle. One tap, zero ambiguity.

Replaces SmartRelationshipPicker and inline dialog selector with shared
FlatRelationshipPicker widget used in add-relative, contact-import, and
family-tree flows."
```
