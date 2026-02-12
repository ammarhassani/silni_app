# Full Family Sharing Experience - Design Document

**Goal:** Make the entire Silni app recognize shared family members - not just the tree visualization, but home screen and core features.

**Architecture:** Central `UserContext` provider that knows userId, familyGroupId, selfNodeId. All feature providers depend on this to decide personal vs shared data access.

**Tech Stack:** Flutter/Riverpod, Supabase (Postgres + RLS)

---

## Implemented Features

### 1. UserContext Provider
**File:** `lib/core/providers/user_context_provider.dart`

Central provider for family-aware context:
```dart
class UserContext {
  final String userId;
  final String? familyGroupId;
  final String? selfNodeId;
  bool get isInGroup => familyGroupId != null;
}
```

### 2. Clickable Tree Header
**File:** `lib/features/family_tree/screens/family_tree_screen.dart`

- Family name now shows chevron icon when in a group
- Tapping navigates to group details page (like WhatsApp groups)
- Personal tree still allows inline name editing

### 3. Auto-Link Joiners to Tree Nodes
**File:** `lib/features/family_groups/services/family_group_service.dart`

When joining a group without a specific relative ID link:
1. Attempts to auto-match by display name
2. If no match, creates a new self-node for the joiner
3. Always ensures `relative_id_in_tree` is set

This fixes the issue where joiners couldn't see the tree creator (e.g., Ammar missing from Amro's tree).

### 4. Group-Aware Home Screen
**File:** `lib/features/home/screens/home_screen.dart`

- Detects if user is in a family group via `userFamilyGroupProvider`
- Shows shared relatives from `groupRelativesStreamProvider` when in group
- Uses shared graph for relationship labels
- Falls back to personal data when not in a group

---

## Deferred Features (Future Enhancement)

### Shared Interactions Visibility
**Status:** Deferred - requires RLS policy changes on `interactions` table

To show interactions by ANY group member:
- Need RLS policy allowing view of interactions where `relative_id` is in user's group
- New providers to query by relative IDs instead of user_id
- UI changes to show who logged each interaction

### Family Tab in Gamification
**Status:** Deferred - enhancement

- Personal streaks remain unchanged
- Add family leaderboard view
- Family-wide achievements

### AI Features for Shared Relatives
**Status:** Deferred - enhancement

- Include shared relatives in AI context
- Family-wide "who to call" suggestions

### Family Tab in Wrapped Stats
**Status:** Deferred - enhancement

- Personal stats tab (unchanged)
- Family aggregate stats tab

---

## Data Query Pattern

**Before:** `user_id = currentUser`

**After:** Family-group-aware:
```dart
final groupInfo = ref.watch(userFamilyGroupProvider).valueOrNull;
final relatives = groupInfo != null
    ? ref.watch(groupRelativesStreamProvider(groupInfo.groupId))
    : ref.watch(relativesStreamProvider(userId));
```

---

## Testing Strategy

- Manual E2E: Create group → share link → join → verify shared tree and relatives
- Verify tree header navigation works in both personal and group modes
- Verify auto-matching and self-node creation for joiners
