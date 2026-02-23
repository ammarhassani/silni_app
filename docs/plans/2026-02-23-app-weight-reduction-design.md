# App Weight Reduction — Surgical Optimization Design

**Date**: 2026-02-23
**Approach**: Keep all features, same feel, fix the engine underneath
**Goal**: Real-time UI + performance, zero feature removal

---

## Problem Statement

The app audit revealed 4 categories of unnecessary weight:

1. **HomeScreen cascade rebuilds** — 13 `ref.watch()` calls in one build method. Any provider change rebuilds all 15+ widgets.
2. **Duplicate Supabase streams** — 4+ independent `.stream()` subscriptions for the same `interactions` table, each creating a separate WebSocket channel.
3. **Uncached graph computation** — O(n^2) BFS re-runs on every relative/edge change, even when topology hasn't changed.
4. **Dead code + aggressive paywall** — Unused files, unreachable screens, and paywall interstitial every 3 app opens.

---

## Pillar 1: HomeScreen Widget Decomposition

### Current State
HomeScreen's `build()` watches 13 providers: `currentUserProvider`, `themeColorsProvider`, `gamificationEventsStreamProvider`, `aiAutoPreloadProvider`, `userFamilyGroupProvider`, `sharedFamilyGraphProvider`/`familyGraphProvider`, `viewerFilteredRelativesProvider`, `todayInteractionsStreamProvider`/`groupTodayInteractionsStreamProvider`, `reminderSchedulesStreamProvider`, `todayContactedRelativesProvider`/`groupTodayContactedRelativesProvider`.

Every change in ANY of these triggers a full rebuild of all child widgets.

### Design
Extract sections that combine multiple provider watches into isolated `ConsumerWidget` subclasses:

```
HomeScreen (StatefulWidget — minimal watches: currentUser, theme, gamification listener)
├── HomeHeaderWidget          (existing — watches: currentUserProvider)
├── PremiumUpgradeBanner      (existing — watches: subscriptionProvider)
├── MessageWidget x3          (existing — no provider watches)
├── IslamicReminderWidget     (existing — local state only)
├── OccasionCard              (existing — userId param only)
├── ProactiveInsightCard      (existing — own provider)
├── QuickActionsWidget        (existing — no watches)
├── FamilyCirclesSection      [NEW] watches: viewerFilteredRelativesProvider, graph
├── AIPriorityContactsWidget  (existing — own provider)
├── DueRemindersSection       [NEW] watches: relatives, schedules, contacted
├── TodaysActivitySection     [NEW] watches: relatives, interactions
├── AIInsightCard             (existing — own provider)
└── SetupRemindersSection     [NEW] watches: schedules only
```

### Key Changes
- Move `gamificationEventsStreamProvider` listener into a `ProviderListener` wrapper or its own widget
- Move `relationshipLabels` computation into a dedicated `relationshipLabelsProvider`
- Create `homeContextProvider` to resolve group-vs-personal mode once (graph, viewerId)
- Each [NEW] section is a ConsumerWidget watching only 1-2 providers

### Result
When a reminder changes → only DueRemindersSection rebuilds.
When an interaction is logged → only TodaysActivitySection and FamilyCirclesSection rebuild.
No cascade. Same real-time feel.

---

## Pillar 2: Consolidated Interactions Stream

### Current State
4+ independent Supabase `.stream()` subscriptions for the interactions table:
- `todayInteractionsStreamProvider` (home_providers.dart)
- `groupTodayInteractionsStreamProvider` (home_providers.dart)
- `todayContactedRelativesProvider` (interactions_provider.dart)
- `detailedStatsProvider` — fetches ALL history, no date filter (stats_provider.dart)
- 3 additional queries in stats_provider for type/recent/monthly breakdowns

### Design
Single base stream, derived providers:

```
todayInteractionsBaseProvider [StreamProvider]
  └── .stream() on interactions WHERE date = today
      ├── todayInteractionsProvider        → passes through raw list
      ├── todayContactedRelativeIdsProvider → derives Set<String>
      └── todayInteractionsByTypeProvider   → groups by InteractionType

groupTodayInteractionsBaseProvider(groupId) [StreamProvider.family]
  └── same pattern for group mode
```

For `detailedStatsProvider`: add `.gte('date', sixMonthsAgo)` filter to stop loading entire history.

### Result
1 WebSocket channel instead of 4. Derived providers update instantly from the same base emission. Same real-time feedback, 75% fewer DB subscriptions.

---

## Pillar 3: Graph Computation Caching

### Current State
- `computeRahimScope()` — O(n^2) BFS traversal, runs on every relative/edge change
- `enrichAllSiblingEdges()` — iterates all edges, runs on every change
- `getLabelForViewer()` — runs per-relative inside HomeScreen build()
- No equality checks on FamilyGraph — Riverpod always treats it as changed

### Design

1. **Add `==` and `hashCode` to FamilyGraph model** so Riverpod's equality check prevents downstream recomputation when graph data hasn't actually changed (e.g., interaction logged but no edges changed).

2. **Create standalone `relationshipLabelsProvider`** instead of computing inline:
```dart
final relationshipLabelsProvider = Provider<Map<String, String>>((ref) {
  final relatives = ref.watch(viewerFilteredRelativesProvider).valueOrNull;
  final context = ref.watch(homeContextProvider);
  if (relatives == null || context.graph == null) return {};
  final enriched = FamilyGraphService.enrichAllSiblingEdges(context.graph!);
  return {
    for (final r in relatives)
      r.id: FamilyGraphService.getLabelForViewer(
        graph: enriched,
        targetNodeId: r.id,
        viewerNodeId: context.viewerId,
      ),
  };
});
```

3. **Rahim scope cached via provider identity** — `rahimVisibleRelativeIdsProvider` already exists and is derived from graph. With proper `==` on FamilyGraph, it won't recompute when unrelated data changes.

### Result
Graph BFS only re-runs when edges actually change. Labels recompute only when relatives or edges change. Logging interactions no longer triggers O(n^2) graph traversal.

---

## Pillar 4: Lazy Loading + Dead Code Cleanup

### Lazy Loading
Wrap below-fold heavy widgets with `VisibilityDetector`:
- `AIInsightCard` — only fetch AI insight when scrolled into view
- `AIPriorityContactsWidget` — only compute priority when visible
- `ProactiveInsightCard` — only run insight rules when visible

These are below the fold for most users. Deferring their load speeds up initial paint by avoiding 3 provider computations during first frame.

### Dead Code Removal
| Item | File | Action |
|------|------|--------|
| Unused admin provider | `lib/core/providers/admin_provider.dart` | Delete file |
| Unreachable reset password screen | `lib/features/auth/screens/reset_password_screen.dart` | Delete file + remove route |
| Orphaned dev tools | `lib/features/dev_tools/` | Delete directory |
| Unused route constant | `lib/core/router/app_routes.dart:77` | Remove `familyGroups` |
| Unused test fixtures | `test/unit/services/placeholder_spawn_service_test.dart` | Remove `_maternalAunt`, unused imports |

### Paywall Tuning
- Change session interstitial frequency: every 3rd open → every 7th
- Remove 5-second rotation timer on premium banner → static text (less visual noise)

---

## Summary

| Pillar | What Changes | What Stays | Expected Impact |
|--------|-------------|------------|-----------------|
| Widget decomposition | HomeScreen delegates to sub-widgets | Same UI, same layout | ~60% fewer widget rebuilds |
| Stream consolidation | 1 base stream, derived providers | Same real-time updates | ~75% fewer DB subscriptions |
| Graph caching | Equality checks prevent redundant BFS | Same labels, same scope | O(1) for non-graph changes |
| Lazy load + cleanup | Heavy cards defer until visible | Same cards, same content | ~200ms faster initial paint |

**Total expected improvement**: ~30-40% faster perceived performance, ~25-30% less server load, same feature set, same UX feel.
