# App Weight Reduction Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Reduce app weight (performance + UX noise) while keeping every feature and the same real-time feel.

**Architecture:** Split HomeScreen's monolithic build into isolated ConsumerWidgets, consolidate duplicate Supabase interaction streams into a single base + derived providers, add equality to FamilyGraph to cache graph computations, and clean up dead code + aggressive paywall timing.

**Tech Stack:** Flutter, Riverpod, Supabase Realtime, go_router

---

## Task 1: Delete Dead Code

**Files:**
- Delete: `lib/core/providers/admin_provider.dart`
- Delete: `lib/features/dev_tools/screens/dev_tools_screen.dart` (and parent directory)
- Delete: `lib/features/auth/screens/reset_password_screen.dart`
- Modify: `lib/core/router/app_router.dart:17,158-161` (remove import + route)
- Modify: `lib/core/router/app_routes.dart:77` (remove `familyGroups` constant)
- Modify: `test/unit/services/placeholder_spawn_service_test.dart:1,4,68` (remove unused imports + fixture)

**Step 1: Delete unused files**

```bash
rm lib/core/providers/admin_provider.dart
rm -r lib/features/dev_tools/
rm lib/features/auth/screens/reset_password_screen.dart
```

**Step 2: Remove reset_password_screen references from router**

In `lib/core/router/app_router.dart`:
- Remove line 17: `import '../../features/auth/screens/reset_password_screen.dart';`
- Remove lines 158-161: the `GoRoute` block for `AppRoutes.resetPassword`

In `lib/core/router/app_routes.dart`:
- Remove line 77: `static const String familyGroups = '/family-groups';`

**Step 3: Clean test file**

In `test/unit/services/placeholder_spawn_service_test.dart`:
- Remove line 1: `import 'dart:ui';`
- Remove line 4: `import 'package:silni_app/features/family_tree/models/placeholder_node.dart';`
- Remove lines 68-73: the `_maternalAunt` fixture variable

**Step 4: Verify**

Run: `flutter analyze`
Expected: 0 new issues (8 pre-existing stay the same or decrease)

Run: `flutter test test/unit/`
Expected: All tests pass

**Step 5: Commit**

```bash
git add -A && git commit -m "chore: remove dead code (admin_provider, reset_password_screen, dev_tools, unused route)"
```

---

## Task 2: Add Equality to FamilyGraph

This prevents downstream providers from recomputing when graph data hasn't actually changed (e.g., logging an interaction doesn't change edges).

**Files:**
- Modify: `lib/features/family_tree/models/family_graph.dart:131-150`
- Create: `test/unit/models/family_graph_equality_test.dart`

**Step 1: Write the failing test**

Create `test/unit/models/family_graph_equality_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/features/family_tree/models/family_graph.dart';
import 'package:silni_app/features/family_tree/services/family_graph_service.dart';

void main() {
  group('FamilyGraph equality', () {
    final edges = [
      FamilyEdge.create(
        userId: 'user-1',
        fromId: 'user-1',
        toId: 'father-1',
        type: EdgeType.parentOf,
      ),
      FamilyEdge.create(
        userId: 'user-1',
        fromId: 'user-1',
        toId: 'mother-1',
        type: EdgeType.parentOf,
      ),
    ];

    test('same edges produce equal graphs', () {
      final g1 = FamilyGraphService.buildGraph(userId: 'user-1', edges: edges);
      final g2 = FamilyGraphService.buildGraph(userId: 'user-1', edges: edges);
      expect(g1, equals(g2));
      expect(g1.hashCode, equals(g2.hashCode));
    });

    test('different edges produce unequal graphs', () {
      final g1 = FamilyGraphService.buildGraph(userId: 'user-1', edges: edges);
      final g2 = FamilyGraphService.buildGraph(
        userId: 'user-1',
        edges: [edges.first], // fewer edges
      );
      expect(g1, isNot(equals(g2)));
    });

    test('different userId produces unequal graphs', () {
      final g1 = FamilyGraphService.buildGraph(userId: 'user-1', edges: edges);
      final g2 = FamilyGraphService.buildGraph(userId: 'user-2', edges: edges);
      expect(g1, isNot(equals(g2)));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/models/family_graph_equality_test.dart -v`
Expected: FAIL — FamilyGraph has no `==` override, so identity check fails

**Step 3: Add equality to FamilyGraph**

In `lib/features/family_tree/models/family_graph.dart`, add after line 150 (closing of constructor), before the query helpers comment:

```dart
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FamilyGraph) return false;
    if (other.userId != userId) return false;
    if (other.edges.length != edges.length) return false;
    // FamilyEdge already has == based on (fromId, toId, type)
    final edgeSet = edges.toSet();
    final otherSet = other.edges.toSet();
    return edgeSet.length == otherSet.length &&
        edgeSet.containsAll(otherSet);
  }

  @override
  int get hashCode => Object.hash(
        userId,
        Object.hashAllUnordered(edges),
      );
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/unit/models/family_graph_equality_test.dart -v`
Expected: All 3 tests PASS

**Step 5: Run full test suite**

Run: `flutter test test/unit/`
Expected: All tests pass

**Step 6: Commit**

```bash
git add lib/features/family_tree/models/family_graph.dart test/unit/models/family_graph_equality_test.dart
git commit -m "perf: add equality to FamilyGraph to prevent redundant recomputation"
```

---

## Task 3: Create Relationship Labels Provider

Move the inline label computation from HomeScreen's build() into a standalone provider. Multiple screens already do this same computation — centralizing it means one computation, many consumers.

**Files:**
- Create: `lib/features/home/providers/relationship_labels_provider.dart`
- Modify: `lib/features/home/screens/home_screen.dart:316-353` (consume new provider instead of inline computation)

**Step 1: Create the provider**

Create `lib/features/home/providers/relationship_labels_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/utils/relationship_label_helper.dart';
import '../../../core/config/supabase_config.dart';
import '../../family_tree/providers/family_graph_providers.dart';
import 'home_providers.dart';

/// Centralized provider for perspective-aware relationship labels.
///
/// Computes Arabic labels (e.g. "عمي", "خالتي") for all viewer-filtered
/// relatives using the family graph. Returns an empty map when graph
/// data isn't available yet.
///
/// Recomputes only when relatives or graph edges change — not on
/// interaction/reminder updates.
final relationshipLabelsProvider =
    Provider.autoDispose<Map<String, String>>((ref) {
  final relatives = ref.watch(viewerFilteredRelativesProvider).valueOrNull;
  if (relatives == null || relatives.isEmpty) return {};

  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) return {};

  final groupInfo = ref.watch(userFamilyGroupProvider).valueOrNull;
  final effectiveViewerId = groupInfo?.nodeId ?? user.id;

  final graph = groupInfo != null
      ? ref.watch(sharedFamilyGraphProvider((
          groupId: groupInfo.groupId,
          viewerNodeId: groupInfo.nodeId,
        )))
      : ref.watch(familyGraphProvider(user.id));

  if (graph == null) return {};

  final relativesMap = {for (final r in relatives) r.id: r};
  return {
    for (final r in relatives)
      r.id: getRelationshipLabel(
        relative: r,
        viewerId: effectiveViewerId,
        graph: graph,
        relativesMap: relativesMap,
      ),
  };
});
```

**Step 2: Update HomeScreen to use the new provider**

In `lib/features/home/screens/home_screen.dart`:

Remove lines 312-353 (the groupInfo, graph, effectiveViewerId, relativesAsync, and relationshipLabels declarations from build()).

Replace with:
```dart
    // Rahim-scoped + self-node-filtered relatives via central provider
    final relativesAsync = ref.watch(viewerFilteredRelativesProvider);

    // Centralized relationship labels — only recomputes when graph/relatives change
    final relationshipLabels = ref.watch(relationshipLabelsProvider);
```

This removes 5 `ref.watch()` calls from HomeScreen: `userFamilyGroupProvider`, `sharedFamilyGraphProvider`, `familyGraphProvider`, and the inline `whenData` computation.

Also remove the now-unused import of `relationship_label_helper.dart` from home_screen.dart and add the new provider import.

**Step 3: Verify**

Run: `flutter analyze`
Expected: 0 new issues

Run: `flutter test test/unit/`
Expected: All tests pass

**Step 4: Commit**

```bash
git add lib/features/home/providers/relationship_labels_provider.dart lib/features/home/screens/home_screen.dart
git commit -m "perf: extract relationshipLabelsProvider from HomeScreen build"
```

---

## Task 4: Decompose HomeScreen into Isolated Sections

Extract the widget sections that combine multiple provider watches into standalone ConsumerWidgets. The parent HomeScreen passes no provider data down — each section watches its own.

**Files:**
- Create: `lib/features/home/widgets/family_circles_section.dart`
- Create: `lib/features/home/widgets/due_reminders_section.dart`
- Create: `lib/features/home/widgets/todays_activity_section.dart`
- Create: `lib/features/home/widgets/setup_reminders_section.dart`
- Create: `lib/features/home/widgets/gamification_listener.dart`
- Modify: `lib/features/home/screens/home_screen.dart` (replace inline sections with new widgets)
- Modify: `lib/features/home/widgets/widgets.dart` (add exports)

**Step 1: Create FamilyCirclesSection**

Create `lib/features/home/widgets/family_circles_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/error_widgets.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../providers/home_providers.dart';
import '../providers/relationship_labels_provider.dart';
import 'widgets.dart';

class FamilyCirclesSection extends ConsumerWidget {
  const FamilyCirclesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relativesAsync = ref.watch(viewerFilteredRelativesProvider);
    final relationshipLabels = ref.watch(relationshipLabelsProvider);

    return relativesAsync.when(
      data: (relatives) => FamilyCirclesWidget(
        relatives: relatives,
        relationshipLabels: relationshipLabels,
      ),
      loading: () => const FamilyCirclesSkeleton(),
      error: (error, _) => InlineErrorWidget(
        message: 'فشل في تحميل بيانات العائلة',
        onRetry: () => ref.invalidate(viewerFilteredRelativesProvider),
      ),
    );
  }
}
```

**Step 2: Create DueRemindersSection**

Create `lib/features/home/widgets/due_reminders_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../family_tree/providers/family_graph_providers.dart';
import '../providers/home_providers.dart';
import '../providers/relationship_labels_provider.dart';
import '../../../shared/providers/interactions_provider.dart';
import 'widgets.dart';

class DueRemindersSection extends ConsumerWidget {
  const DueRemindersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    final relativesAsync = ref.watch(viewerFilteredRelativesProvider);
    final schedulesAsync = ref.watch(reminderSchedulesStreamProvider(user.id));
    final groupInfo = ref.watch(userFamilyGroupProvider).valueOrNull;
    final todayContactedAsync = groupInfo != null
        ? ref.watch(groupTodayContactedRelativesProvider(groupInfo.groupId))
        : ref.watch(todayContactedRelativesProvider(user.id));
    final relationshipLabels = ref.watch(relationshipLabelsProvider);

    return relativesAsync.when(
      data: (relatives) => schedulesAsync.when(
        data: (schedules) => DueRemindersCard(
          userId: user.id,
          relatives: relatives,
          schedules: schedules,
          contactedSet: todayContactedAsync.valueOrNull ?? <String>{},
          relationshipLabels: relationshipLabels,
        ),
        loading: () => const DueRemindersCardSkeleton(),
        error: (_, _) => const SizedBox.shrink(),
      ),
      loading: () => const DueRemindersCardSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
```

**Step 3: Create TodaysActivitySection**

Create `lib/features/home/widgets/todays_activity_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../shared/widgets/error_widgets.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../family_tree/providers/family_graph_providers.dart';
import '../providers/home_providers.dart';
import 'widgets.dart';

class TodaysActivitySection extends ConsumerWidget {
  const TodaysActivitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    final relativesAsync = ref.watch(viewerFilteredRelativesProvider);
    final groupInfo = ref.watch(userFamilyGroupProvider).valueOrNull;
    final todayInteractionsAsync = groupInfo != null
        ? ref.watch(groupTodayInteractionsStreamProvider(groupInfo.groupId))
        : ref.watch(todayInteractionsStreamProvider(user.id));

    return relativesAsync.when(
      data: (relatives) => todayInteractionsAsync.when(
        data: (interactions) => TodaysActivityWidget(
          interactions: interactions,
          relatives: relatives,
        ),
        loading: () => const TodaysActivitySkeleton(),
        error: (error, _) => InlineErrorWidget(
          message: 'فشل في تحميل نشاط اليوم',
          onRetry: () {
            if (groupInfo != null) {
              ref.invalidate(
                  groupTodayInteractionsStreamProvider(groupInfo.groupId));
            } else {
              ref.invalidate(todayInteractionsStreamProvider(user.id));
            }
          },
          compact: true,
        ),
      ),
      loading: () => const TodaysActivitySkeleton(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
```

**Step 4: Create SetupRemindersSection**

Create `lib/features/home/widgets/setup_reminders_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../providers/home_providers.dart';
import 'widgets.dart';

class SetupRemindersSection extends ConsumerWidget {
  const SetupRemindersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    final schedulesAsync = ref.watch(reminderSchedulesStreamProvider(user.id));

    return schedulesAsync.when(
      data: (schedules) => SetupRemindersPrompt(
        hasReminders: schedules.isNotEmpty,
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
```

**Step 5: Create GamificationListener**

Create `lib/features/home/widgets/gamification_listener.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/gamification_event.dart';
import '../../../core/providers/gamification_events_provider.dart';
import '../../../core/config/supabase_config.dart';

/// Invisible widget that listens to gamification events and calls [onEvent].
///
/// Isolates the gamification stream watch from the rest of HomeScreen,
/// preventing cascade rebuilds when events fire.
class GamificationListener extends ConsumerWidget {
  final void Function(GamificationEvent event) onEvent;

  const GamificationListener({super.key, required this.onEvent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = SupabaseConfig.client.auth.currentUser?.id;

    ref.listen<AsyncValue<GamificationEvent>>(
      gamificationEventsStreamProvider,
      (previous, next) {
        next.whenData((event) {
          if (event.userId != userId) return;
          onEvent(event);
        });
      },
    );

    return const SizedBox.shrink();
  }
}
```

**Step 6: Update widgets.dart barrel export**

In `lib/features/home/widgets/widgets.dart`, add:

```dart
export 'family_circles_section.dart';
export 'due_reminders_section.dart';
export 'todays_activity_section.dart';
export 'setup_reminders_section.dart';
export 'gamification_listener.dart';
```

**Step 7: Rewrite HomeScreen build method**

In `lib/features/home/screens/home_screen.dart`, replace the build method body (lines 275-539) with a simplified version that:
- Watches only `currentUserProvider` and `themeColorsProvider`
- Uses `GamificationListener` widget for events (instead of `ref.listen`)
- Keeps `ref.watch(autoRealtimeSubscriptionsProvider)` and `ref.watch(aiAutoPreloadProvider)` (side-effect providers)
- Replaces all inline `relativesAsync.when(...)` blocks with the new section widgets
- Removes all unused imports: `interactions_provider.dart`, `relationship_label_helper.dart`, `family_graph_providers.dart`

The Column children become:

```dart
children: [
  HomeHeaderWidget(displayName: displayName, userId: userId),
  const SizedBox(height: AppSpacing.sm),
  const PremiumUpgradeBanner(),
  const SizedBox(height: AppSpacing.sm),
  const MessageWidget(position: 'home_top'),
  const SizedBox(height: AppSpacing.sm),
  const MessageWidget(screenPath: '/home'),
  const SizedBox(height: AppSpacing.md),
  IslamicReminderWidget(hadith: _dailyHadith, isLoading: _isLoadingHadith),
  const SizedBox(height: AppSpacing.md),
  OccasionCard(userId: userId),
  const SizedBox(height: AppSpacing.md),
  ProactiveInsightCard(userId: userId),
  const SizedBox(height: AppSpacing.md),
  const QuickActionsWidget(),
  const SizedBox(height: AppSpacing.lg),
  const FamilyCirclesSection(),
  const SizedBox(height: AppSpacing.md),
  AIPriorityContactsWidget(userId: userId),
  const SizedBox(height: AppSpacing.md),
  const DueRemindersSection(),
  const SizedBox(height: AppSpacing.lg),
  const TodaysActivitySection(),
  const SizedBox(height: AppSpacing.md),
  const AIInsightCard(),
  const SizedBox(height: AppSpacing.md),
  const SetupRemindersSection(),
  const SizedBox(height: AppSpacing.md),
  const MessageWidget(position: 'home_bottom'),
  SizedBox(height: PersistentBottomNav.totalHeight),
],
```

**Step 8: Verify**

Run: `flutter analyze`
Expected: 0 new issues

Run: `flutter test test/unit/`
Expected: All tests pass

**Step 9: Commit**

```bash
git add lib/features/home/
git commit -m "perf: decompose HomeScreen into isolated ConsumerWidget sections"
```

---

## Task 5: Consolidate Group Interaction Streams

Replace `groupTodayInteractionsStreamProvider` and `groupTodayContactedRelativesProvider` with a single base stream + derived providers.

**Files:**
- Modify: `lib/features/home/providers/home_providers.dart:174-249` (replace 2 providers with 1 base + 2 derived)

**Step 1: Replace the two group interaction providers**

In `lib/features/home/providers/home_providers.dart`, replace lines 174-249 (both `groupTodayInteractionsStreamProvider` and `groupTodayContactedRelativesProvider`) with:

```dart
/// Base stream for group-wide today's interactions.
///
/// Single Supabase real-time subscription for all today's interactions visible
/// via RLS in this group. Both interaction list and contacted-set providers
/// derive from this, avoiding duplicate WebSocket channels.
final _groupTodayInteractionsBaseProvider =
    StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, groupId) {
  final link = ref.keepAlive();
  Timer? timer;

  ref.onDispose(() => timer?.cancel());
  ref.onCancel(() {
    timer = Timer(_cacheTimeout, () => link.close());
  });
  ref.onResume(() => timer?.cancel());

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);

  return SupabaseConfig.client
      .from('interactions')
      .stream(primaryKey: ['id'])
      .gte('date', startOfDay.toUtc().toIso8601String())
      .order('date', ascending: false);
});

/// Group today's interactions as typed models, filtered to rahim-visible relatives.
final groupTodayInteractionsStreamProvider =
    StreamProvider.autoDispose.family<List<Interaction>, String>((ref, groupId) {
  final rahimScope = ref.watch(rahimVisibleRelativeIdsProvider);
  final groupRelativeIds = rahimScope ?? (ref
      .watch(groupRelativesStreamProvider(groupId))
      .valueOrNull
      ?.map((r) => r.id)
      .toSet() ?? <String>{});

  return ref.watch(_groupTodayInteractionsBaseProvider(groupId)).asStream().map(
    (asyncValue) => asyncValue.valueOrNull
        ?.map((json) => Interaction.fromJson(json))
        .where((i) => groupRelativeIds.contains(i.relativeId))
        .toList() ?? [],
  );
});

/// Group today's contacted relative IDs, derived from the same base stream.
final groupTodayContactedRelativesProvider =
    Provider.autoDispose.family<AsyncValue<Set<String>>, String>((ref, groupId) {
  final rahimScope = ref.watch(rahimVisibleRelativeIdsProvider);
  final groupRelativeIds = rahimScope ?? (ref
      .watch(groupRelativesStreamProvider(groupId))
      .valueOrNull
      ?.map((r) => r.id)
      .toSet() ?? <String>{});

  return ref.watch(_groupTodayInteractionsBaseProvider(groupId)).whenData((data) {
    return data
        .map((i) => i['relative_id'] as String?)
        .where((id) => id != null && id.isNotEmpty && groupRelativeIds.contains(id))
        .cast<String>()
        .toSet();
  });
});
```

Note: `groupTodayContactedRelativesProvider` changes from `StreamProvider` to `Provider<AsyncValue<Set<String>>>`. Update consumers accordingly — the `.when()` / `.valueOrNull` API is the same since both yield `AsyncValue`.

**Step 2: Update consumers of groupTodayContactedRelativesProvider**

Check all consumers — the provider now returns `AsyncValue<Set<String>>` via `Provider` instead of `StreamProvider`. Since both are watched and yield `AsyncValue`, consumers using `.valueOrNull` work unchanged. Verify by searching for `groupTodayContactedRelativesProvider` and ensuring each call site uses `.valueOrNull` or `.when()`.

**Step 3: Verify**

Run: `flutter analyze`
Expected: 0 new issues

Run: `flutter test test/unit/`
Expected: All tests pass

**Step 4: Commit**

```bash
git add lib/features/home/providers/home_providers.dart
git commit -m "perf: consolidate group interaction streams into single base provider"
```

---

## Task 6: Add Date Filter to DetailedStats Provider

**Files:**
- Modify: `lib/features/gamification/providers/stats_provider.dart:67-71`

**Step 1: Add date filter to the all-interactions query**

In `lib/features/gamification/providers/stats_provider.dart`, change lines 68-71 from:

```dart
  final interactionsResponse = await SupabaseConfig.client
      .from('interactions')
      .select('type, relative_id, date')
      .eq('user_id', user.id);
```

To:

```dart
  final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
  final interactionsResponse = await SupabaseConfig.client
      .from('interactions')
      .select('type, relative_id, date')
      .eq('user_id', user.id)
      .gte('date', sixMonthsAgo.toIso8601String());
```

Also remove the duplicate `sixMonthsAgo` declaration on line 101 (it's now declared earlier).

**Step 2: Verify**

Run: `flutter analyze`
Expected: 0 new issues

Run: `flutter test test/unit/`
Expected: All tests pass

**Step 3: Commit**

```bash
git add lib/features/gamification/providers/stats_provider.dart
git commit -m "perf: add 6-month date filter to detailedStats query"
```

---

## Task 7: Reduce Paywall Aggressiveness

**Files:**
- Modify: `lib/shared/widgets/session_paywall_interstitial.dart:38` (change interval)
- Modify: `lib/features/home/widgets/premium_upgrade_banner.dart:27-50` (remove rotation timer)

**Step 1: Change interstitial frequency**

In `lib/shared/widgets/session_paywall_interstitial.dart`, change line 38 from:

```dart
    final interval = skipCount >= 5 ? 5 : 3;
```

To:

```dart
    final interval = skipCount >= 5 ? 10 : 7;
```

**Step 2: Remove rotation timer from premium banner**

In `lib/features/home/widgets/premium_upgrade_banner.dart`:

Remove the `_currentIndex` field (line 34), `_rotationTimer` field (line 35), the `initState` method (lines 37-50), and the `dispose` method (lines 52-57).

Change the class from `_PremiumUpgradeBannerState` with timer to a simpler state that uses a fixed message. Replace the `_teaserMessages[_currentIndex]` reference in the build with a single static message:

```dart
static const _teaserMessage = 'استمتع بجميع المزايا — جرّب صلني MAX مجاناً';
```

This eliminates the `setState` call every 5 seconds which was causing a rebuild of the banner (and with it, triggering the parent HomeScreen to check if it needs to rebuild).

**Step 3: Verify**

Run: `flutter analyze`
Expected: 0 new issues

**Step 4: Commit**

```bash
git add lib/shared/widgets/session_paywall_interstitial.dart lib/features/home/widgets/premium_upgrade_banner.dart
git commit -m "ux: reduce paywall frequency and remove banner rotation timer"
```

---

## Task 8: Add keepAlive to groupMemberNodeIdsProvider

**Files:**
- Modify: `lib/features/family_tree/providers/family_graph_providers.dart:132-142`

**Step 1: Add keepAlive pattern**

In `lib/features/family_tree/providers/family_graph_providers.dart`, replace lines 132-142:

```dart
final groupMemberNodeIdsProvider =
    StreamProvider.autoDispose.family<Set<String>, String>((ref, groupId) {
  return SupabaseConfig.client
      .from('family_group_members')
      .stream(primaryKey: ['id'])
      .eq('group_id', groupId)
      .map((data) => data
          .map((m) => m['relative_id_in_tree'] as String?)
          .whereType<String>()
          .toSet());
});
```

With:

```dart
final groupMemberNodeIdsProvider =
    StreamProvider.autoDispose.family<Set<String>, String>((ref, groupId) {
  final link = ref.keepAlive();
  Timer? timer;

  ref.onDispose(() => timer?.cancel());
  ref.onCancel(() {
    timer = Timer(_cacheTimeout, () => link.close());
  });
  ref.onResume(() => timer?.cancel());

  return SupabaseConfig.client
      .from('family_group_members')
      .stream(primaryKey: ['id'])
      .eq('group_id', groupId)
      .map((data) => data
          .map((m) => m['relative_id_in_tree'] as String?)
          .whereType<String>()
          .toSet());
});
```

**Step 2: Verify**

Run: `flutter analyze`
Expected: 0 new issues

**Step 3: Commit**

```bash
git add lib/features/family_tree/providers/family_graph_providers.dart
git commit -m "perf: add keepAlive to groupMemberNodeIdsProvider"
```

---

## Task 9: Final Verification

**Step 1: Run full analysis**

Run: `flutter analyze`
Expected: No new issues

**Step 2: Run full unit test suite**

Run: `flutter test test/unit/`
Expected: All tests pass

**Step 3: Manual smoke test checklist**

Verify these flows still work with real-time updates:
- [ ] Home screen loads without delay
- [ ] Log an interaction → TodaysActivity updates instantly, other cards don't flicker
- [ ] Add a reminder → DueReminders updates instantly, family circles don't rebuild
- [ ] Family tree labels still show Arabic perspective labels
- [ ] Paywall interstitial appears less frequently (every 7th open)
- [ ] Premium banner shows static text, no rotation

**Step 4: Commit any final fixes**

```bash
git add -A && git commit -m "chore: final verification and cleanup"
```
