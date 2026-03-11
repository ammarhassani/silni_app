# Atomic Side Selection Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix familySide never being saved by merging type+side into a single atomic callback and adding save validation.

**Architecture:** Replace the two-callback pattern (`onChanged` + `onSideChanged`) in SmartRelationshipPicker with a single `onSelectionChanged(type, side)`. Add validation in add_relative_screen to block saving without a side for types that need one. Remove debug prints.

**Tech Stack:** Flutter, Dart

---

### Task 1: Merge callbacks in SmartRelationshipPicker

**Files:**
- Modify: `lib/features/relatives/widgets/smart_relationship_picker.dart`

**Step 1: Change the callback signature and remove onSideChanged**

Replace lines 50-77 (the widget class fields + constructor) with:

```dart
class SmartRelationshipPicker extends StatefulWidget {
  /// Currently selected relationship type.
  final RelationshipType selected;

  /// Suggested relationship types (4-6 items) based on family tree analysis.
  final List<RelationshipType> suggestions;

  /// Called when the user selects a relationship type and/or side.
  /// Both values are passed atomically to prevent race conditions.
  final void Function(RelationshipType type, FamilySide? side) onSelectionChanged;

  /// Currently selected family side.
  final FamilySide? selectedSide;

  /// Existing relatives — used to hide singleton types that are already filled.
  final List<Relative> existingRelatives;

  const SmartRelationshipPicker({
    super.key,
    required this.selected,
    required this.suggestions,
    required this.onSelectionChanged,
    this.selectedSide,
    this.existingRelatives = const [],
  });

  @override
  State<SmartRelationshipPicker> createState() =>
      _SmartRelationshipPickerState();
}
```

**Step 2: Update _buildRelationshipCard onTap (line 228-235)**

Replace:
```dart
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onChanged(type);
        if (side != null) {
          widget.onSideChanged?.call(side);
        }
      },
```

With:
```dart
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onSelectionChanged(type, side);
      },
```

**Step 3: Update _buildSideSelector condition (line 150-151)**

Replace:
```dart
          if (_extendedFamilyTypes.contains(widget.selected) &&
              widget.onSideChanged != null) ...[
```

With:
```dart
          if (_extendedFamilyTypes.contains(widget.selected)) ...[
```

**Step 4: Update _buildSideButton onTap (line 338-341)**

Replace:
```dart
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onSideChanged?.call(isSelected ? null : side);
      },
```

With:
```dart
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onSelectionChanged(
          widget.selected,
          isSelected ? null : side,
        );
      },
```

**Step 5: Update _buildAllRelationships onTap (line 440-447)**

Replace:
```dart
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onChanged(item.type);
            if (item.side != null) {
              widget.onSideChanged?.call(item.side);
            }
          },
```

With:
```dart
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onSelectionChanged(item.type, item.side);
          },
```

**Step 6: Verify no compile errors**

Run: `flutter analyze lib/features/relatives/widgets/smart_relationship_picker.dart`
Expected: No errors (warnings about add_relative_screen are OK at this stage)

---

### Task 2: Update add_relative_screen to use atomic callback

**Files:**
- Modify: `lib/features/relatives/screens/add_relative_screen.dart`

**Step 1: Define the set of types requiring familySide**

Add near the top of the file (after imports, before the class):

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

**Step 2: Replace the SmartRelationshipPicker callbacks (lines 440-459)**

Replace:
```dart
                        SmartRelationshipPicker(
                          selected: _selectedRelationship,
                          suggestions: suggestions,
                          existingRelatives: existingRelatives,
                          selectedSide: _selectedFamilySide,
                          onChanged: (value) {
                            setState(() {
                              _selectedRelationship = value;
                              // Auto-detect gender based on relationship
                              _selectedGender =
                                  RelationshipInferenceService.genderFromRelationship(value);
                              // Auto-set priority based on relationship closeness
                              _priority = AvatarType.suggestPriority(value);
                              // Reset family side when relationship changes
                              _selectedFamilySide = null;
                            });
                          },
                          onSideChanged: (side) {
                            setState(() => _selectedFamilySide = side);
                          },
                        ),
```

With:
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

**Step 3: Add validation before save**

Find the save method (around line 130, the `_saveRelative` or submit handler). Look for the existing form validation check. After the `_formKey.currentState!.validate()` check, add:

```dart
      // Validate family side for extended family types
      if (_sideRequiredTypes.contains(_selectedRelationship) && _selectedFamilySide == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('اختر من طرف أبوك ولا أمك'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
```

**Step 4: Verify no compile errors**

Run: `flutter analyze lib/features/relatives/screens/add_relative_screen.dart lib/features/relatives/widgets/smart_relationship_picker.dart`
Expected: No errors

---

### Task 3: Remove debug prints

**Files:**
- Modify: `lib/shared/utils/relationship_label_helper.dart`
- Modify: `lib/shared/repositories/relatives_repository.dart`
- Modify: `lib/features/relatives/widgets/detail/relative_header_widget.dart`

**Step 1: Remove debug print from relationship_label_helper.dart**

Remove these lines (12-15):
```dart
  // DEBUG: Remove after investigation
  if (type == RelationshipType.aunt || type == RelationshipType.uncle || type == RelationshipType.cousin) {
    print('[LABEL_DEBUG] getSideAwareLabel called: type=${type.value}, side=$side, gender=$gender → ${side == null ? "FALLBACK to arabicName: ${type.arabicName}" : "RESOLVED"}');
  }
```

**Step 2: Remove debug print from relatives_repository.dart**

Remove this line (around line 182):
```dart
    // DEBUG: Remove after investigation
    print('[CREATE_DEBUG] createRelative: name=${newRelative.fullName}, type=${newRelative.relationshipType.value}, familySide=${newRelative.familySide}, json_family_side=${newRelative.toJson()['family_side']}');
```

**Step 3: Restore relative_header_widget.dart to clean version**

Replace the Builder/debug wrapper (lines 106-114) back to:
```dart
            child: Text(
              relationshipLabel ?? getSideAwareLabel(relative.relationshipType, relative.familySide, relative.gender),
              style: AppTypography.titleMedium.copyWith(color: themeColors.onPrimary),
            ),
```

**Step 4: Verify clean compile**

Run: `flutter analyze lib/shared/utils/relationship_label_helper.dart lib/shared/repositories/relatives_repository.dart lib/features/relatives/widgets/detail/relative_header_widget.dart`
Expected: No errors

---

### Task 4: Manual verification

**Step 1: Hot restart the app**

**Step 2: Test aunt creation**
- Tap add relative → tap "خالة" card
- Verify the card highlights AND no separate side picker appears (side is auto-set)
- Fill name, save
- Verify label shows "خالة" (not "عمة") on relatives list, detail screen, and carousel

**Step 3: Test cousin creation**
- Tap add relative → tap "cousin" card
- Verify side picker appears ("طرف أبوي" / "طرف أمي")
- Try to save WITHOUT selecting side → should show error snackbar
- Select "طرف أمي", save
- Verify label shows "ابن الخال" or "بنت الخال"

**Step 4: Test family tree**
- Verify aunt appears at parent generation on correct side
- Verify cousin appears at same generation on correct side

**Step 5: Commit**

```bash
git add lib/features/relatives/widgets/smart_relationship_picker.dart \
       lib/features/relatives/screens/add_relative_screen.dart \
       lib/shared/utils/relationship_label_helper.dart \
       lib/shared/repositories/relatives_repository.dart \
       lib/features/relatives/widgets/detail/relative_header_widget.dart
git commit -m "fix: merge type+side into atomic callback, add save validation

Root cause: SmartRelationshipPicker used separate onChanged/onSideChanged
callbacks. onChanged reset familySide to null before onSideChanged could
set it. For extended types (cousin), no validation prevented saving with
null familySide.

Fix: Single onSelectionChanged(type, side) callback carries both values
atomically. Save blocked when side-required types have no side selected."
```
