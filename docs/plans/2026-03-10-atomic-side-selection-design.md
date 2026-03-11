# Atomic Side Selection — Design

## Root Cause

Debug logs confirmed: `familySide` is **NULL at creation time**. The SmartRelationshipPicker uses two separate callbacks (`onChanged` for type, `onSideChanged` for side). The `onChanged` callback resets `_selectedFamilySide = null` before `onSideChanged` can set it. For extended types (cousin, grandfather, grandmother), side is set via separate buttons that the user can skip entirely — no validation blocks save.

Evidence:
```
[CREATE_DEBUG] createRelative: name=AB, type=cousin, familySide=null, json_family_side=null
[HEADER_DEBUG] ABDULLAH MESHAAL ALOTAIBI: relationshipLabel=عمة, familySide=null, type=aunt → showing: عمة
```

## Fix 1: Atomic Callback

Replace the two-callback pattern with a single unified callback.

**SmartRelationshipPicker** (smart_relationship_picker.dart):
- Change `onChanged` from `ValueChanged<RelationshipType>` to `void Function(RelationshipType type, FamilySide? side)`
- Remove `onSideChanged` callback entirely
- Split cards (عمة/خالة) pass both type and side in the single callback
- Side selector buttons for extended types also call the unified callback

**add_relative_screen.dart**:
- Single handler sets both `_selectedRelationship` and `_selectedFamilySide` atomically in one `setState`
- Only reset side when switching to a type that doesn't need one (father, mother, brother, sister, son, daughter, husband, wife, other)

## Fix 2: Save Validation

Types requiring `familySide`:
- uncle, aunt, cousin, grandfather, grandmother

Before save: if type is in this set and `_selectedFamilySide` is null, show validation error: "اختر من طرف أبوك ولا أمك"

## Fix 3: Keep Existing Fixes

- `_generationFromType` for disconnected tree nodes — keep
- `familySide` gap-fill loop in layout service — keep
- All `getSideAwareLabel` replacements — keep
- Existing relatives with null familySide continue to work (fallback to default arabicName)

## Scope

- 2 files changed: `smart_relationship_picker.dart`, `add_relative_screen.dart`
- No enum changes, no DB changes, no migrations
- Remove 3 debug print statements after verification

## Verification

1. Add aunt via خالة card → familySide=maternal, label shows "خالة"
2. Add uncle via عم card → familySide=paternal, label shows "عم"
3. Add cousin → must select side before save, label shows "ابن الخال" or "ابن العم"
4. Try saving cousin without side → blocked with error message
5. Family tree shows aunt at parent generation on correct side
