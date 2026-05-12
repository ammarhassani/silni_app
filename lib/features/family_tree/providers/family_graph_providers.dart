import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/supabase_config.dart';
import '../../../shared/models/relative_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_providers.dart';
import '../models/family_graph.dart';
import '../services/family_graph_service.dart';

/// Cache duration for graph provider
const _cacheTimeout = Duration(minutes: 5);

/// Stream provider for the user's family graph edges.
///
/// Watches the `family_edges` table in Supabase and emits a list of
/// [FamilyEdge] objects whenever the data changes.
/// Uses autoDispose with timed cache (same pattern as [relativesStreamProvider]).
final familyEdgesStreamProvider =
    StreamProvider.autoDispose.family<List<FamilyEdge>, String>((ref, userId) {
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
      .eq('user_id', userId)
      .map((data) => data.map((json) => FamilyEdge.fromJson(json)).toList());
});

/// Personal-mode bridged edges: rewrites any edge endpoint that references
/// one of the user's self-nodes (or their auth UUID via legacy dangling
/// data) to point at their personal NULL-scope self-node. This unifies
/// all the user's "selves" into one logical anchor for graph traversal
/// and tree layout. Without this, edges from group-scoped parents (admin
/// group's mom -> admin-self) don't connect to the personal-self anchor
/// and the tree fragments into disconnected components.
///
/// Falls back to raw edges when:
/// - The user has no personal NULL-scope self-node yet (no bridging anchor).
/// - Only one self-node exists and no dangling auth-uid endpoints (passthrough).
///
/// Mirrors the bridging logic of [groupTreeEdgesProvider] but inverted:
/// group mode collapses personal-self into in-group-self; personal mode
/// collapses every in-group-self (plus dangling auth-uid refs) into
/// personal-self.
final personalBridgedEdgesProvider = Provider.autoDispose
    .family<AsyncValue<List<FamilyEdge>>, String>((ref, userId) {
  final edgesAsync = ref.watch(familyEdgesStreamProvider(userId));
  final relativesAsync = ref.watch(relativesStreamProvider(userId));

  if (edgesAsync.isLoading || relativesAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (edgesAsync.hasError) {
    return AsyncValue.error(
      edgesAsync.error!,
      edgesAsync.stackTrace ?? StackTrace.current,
    );
  }

  final edges = edgesAsync.valueOrNull ?? const <FamilyEdge>[];
  final relatives = relativesAsync.valueOrNull ?? const <Relative>[];

  String? personalSelfId;
  final allSelfIds = <String>{};
  for (final r in relatives) {
    if (r.isSelf && r.userId == userId) {
      allSelfIds.add(r.id);
      if (r.familyGroupId == null) {
        personalSelfId = r.id;
      }
    }
  }

  // Defensive: without a personal anchor we can't bridge. Pass through raw.
  if (personalSelfId == null) {
    return AsyncValue.data(edges);
  }

  // Rewrite endpoints that reference the auth uid OR any non-personal
  // self-id to point at the personal self.
  String rewrite(String endpointId) {
    if (endpointId == userId) return personalSelfId!;
    if (endpointId != personalSelfId && allSelfIds.contains(endpointId)) {
      return personalSelfId!;
    }
    return endpointId;
  }

  final rewritten = <FamilyEdge>[];
  for (final e in edges) {
    final newFrom = rewrite(e.fromId);
    final newTo = rewrite(e.toId);
    if (newFrom == e.fromId && newTo == e.toId) {
      rewritten.add(e);
    } else {
      rewritten.add(FamilyEdge(
        id: e.id,
        userId: e.userId,
        fromId: newFrom,
        toId: newTo,
        type: e.type,
        createdAt: e.createdAt,
        familyGroupId: e.familyGroupId,
      ));
    }
  }

  return AsyncValue.data(rewritten);
});

/// Provider that builds a [FamilyGraph] from the user's bridged edges.
///
/// Consumes [personalBridgedEdgesProvider] so all of the user's self-nodes
/// (personal + every in-group self) and any legacy dangling auth-uid edge
/// endpoints collapse onto the personal NULL-scope self-node. This keeps
/// the tree connected even when the user is admin of a group whose edges
/// reference the in-group self rather than the personal self.
///
/// Returns `null` when:
/// - Edges are still loading
/// - No edges exist (new users without graph data)
/// - An error occurred fetching edges
///
/// Consumers should always handle the `null` case and fall back to
/// [RelationshipType.arabicName] for display labels.
final familyGraphProvider =
    Provider.autoDispose.family<FamilyGraph?, String>((ref, userId) {
  final edgesAsync = ref.watch(personalBridgedEdgesProvider(userId));
  final relativesAsync = ref.watch(relativesStreamProvider(userId));

  return edgesAsync.whenData((edges) {
    if (edges.isEmpty) return null;

    // FamilyGraph.getGeneration does BFS from `graph.userId`. After
    // personalBridgedEdgesProvider rewrites edge endpoints to the user's
    // personal NULL-scope self-node relative_id, the graph no longer
    // contains the auth UUID as a node. Anchoring the BFS on auth-uid
    // would never reach any node — every relative would resolve to
    // generation 0 and squish into one row. Use personal-self as the
    // anchor so generations compute correctly.
    String? personalSelfId;
    final ownedRelatives = relativesAsync.valueOrNull;
    if (ownedRelatives != null) {
      for (final r in ownedRelatives) {
        if (r.isSelf && r.familyGroupId == null && r.userId == userId) {
          personalSelfId = r.id;
          break;
        }
      }
    }

    return FamilyGraphService.buildGraph(
      userId: personalSelfId ?? userId,
      edges: edges,
    );
  }).valueOrNull;
});

/// Stream provider for shared family edges (by group ID).
///
/// Watches edges that belong to a specific family group,
/// enabling shared tree rendering across group members.
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

/// Group-context edges: shared group edges + the viewer's own personal edges
/// (`family_group_id IS NULL`). Other group members never see the viewer's
/// personal edges because RLS filters by `user_id`.
///
/// This lets the family tree merge a non-admin member's personal additions
/// (which land in personal scope per Task A1/A2) into their group-tree view.
///
/// **Logical identity bridge**: when the viewer has BOTH a personal NULL-scope
/// self-node AND an in-group self-node (different relative ids for logically
/// the same person), personal edges reference the personal self id but the
/// rendered tree uses the in-group self id as anchor. We rewrite any edge
/// endpoint pointing at the personal self id to the in-group self id so the
/// two halves of the graph join up visually. Idempotent: if the rewrite has
/// already happened, the endpoints simply stay put.
final groupTreeEdgesProvider =
    Provider.autoDispose.family<AsyncValue<List<FamilyEdge>>, String>((ref, groupId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const AsyncValue.data([]);

  final groupAsync = ref.watch(sharedFamilyEdgesStreamProvider(groupId));
  final personalAsync = ref.watch(familyEdgesStreamProvider(user.id));
  // Watch relatives streams to discover both self-node ids for the viewer.
  final groupRelsAsync = ref.watch(groupRelativesStreamProvider(groupId));
  final personalRelsAsync = ref.watch(relativesStreamProvider(user.id));

  if (groupAsync.isLoading && personalAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (groupAsync.hasError && personalAsync.hasError) {
    return AsyncValue.error(
      groupAsync.error!,
      groupAsync.stackTrace ?? StackTrace.current,
    );
  }

  final groupEdges = groupAsync.valueOrNull ?? const <FamilyEdge>[];
  // Keep ONLY the viewer's personal edges (familyGroupId == null).
  // The viewer's owned-edges stream also contains rows scoped to this group
  // (or other groups) — those must NOT be re-included since group edges are
  // already covered by the shared stream.
  final personalEdges = (personalAsync.valueOrNull ?? const <FamilyEdge>[])
      .where((e) => e.familyGroupId == null)
      .toList();

  // Dedup by id (defensive — scopes are disjoint by design).
  final byId = <String, FamilyEdge>{};
  for (final e in groupEdges) {
    byId[e.id] = e;
  }
  for (final e in personalEdges) {
    byId.putIfAbsent(e.id, () => e);
  }

  // --- Bridging: rewrite personalSelfId → inGroupSelfId on edge endpoints. ---
  String? inGroupSelfId;
  for (final r in groupRelsAsync.valueOrNull ?? const <Relative>[]) {
    if (r.isSelf && r.userId == user.id && r.familyGroupId == groupId) {
      inGroupSelfId = r.id;
      break;
    }
  }
  String? personalSelfId;
  for (final r in personalRelsAsync.valueOrNull ?? const <Relative>[]) {
    if (r.isSelf && r.userId == user.id && r.familyGroupId == null) {
      personalSelfId = r.id;
      break;
    }
  }

  final merged = byId.values.toList();
  if (inGroupSelfId == null ||
      personalSelfId == null ||
      inGroupSelfId == personalSelfId) {
    return AsyncValue.data(merged);
  }

  final bridged = <FamilyEdge>[];
  for (final e in merged) {
    final newFrom = e.fromId == personalSelfId ? inGroupSelfId : e.fromId;
    final newTo = e.toId == personalSelfId ? inGroupSelfId : e.toId;
    if (newFrom == e.fromId && newTo == e.toId) {
      bridged.add(e);
    } else {
      bridged.add(FamilyEdge(
        id: e.id,
        userId: e.userId,
        fromId: newFrom,
        toId: newTo,
        type: e.type,
        createdAt: e.createdAt,
        familyGroupId: e.familyGroupId,
      ));
    }
  }
  return AsyncValue.data(bridged);
});

/// Build a shared graph with a specific viewer as anchor.
///
/// [viewerNodeId] is the relative_id_in_tree of the current viewer,
/// used as the userId for graph construction so perspective labels
/// are computed relative to them. If null, uses the first `is_self` node
/// found, or falls back to an empty string (no perspective).
///
/// Sources edges from [groupTreeEdgesProvider] so the viewer's personal
/// additions (scoped `family_group_id IS NULL`) appear alongside the shared
/// group edges. Other members are unaffected (RLS hides personal edges).
final sharedFamilyGraphProvider = Provider.autoDispose
    .family<FamilyGraph?, ({String groupId, String? viewerNodeId})>((ref, params) {
  final edgesAsync = ref.watch(groupTreeEdgesProvider(params.groupId));
  return edgesAsync.whenData((edges) {
    if (edges.isEmpty) return null;
    // Use provided viewerNodeId, or fallback to empty string (observer mode)
    final anchorId = params.viewerNodeId ?? '';
    return FamilyGraphService.buildGraph(
      userId: anchorId,
      edges: edges,
    );
  }).valueOrNull;
});

/// SharedPreferences key for the persistent active-group selection.
const _kActiveGroupIdPrefKey = 'active_group_id';

/// Sentinel value stored in [activeGroupIdProvider] when the user has
/// EXPLICITLY chosen personal mode. Distinct from `null` (unset) so the
/// provider can default to first-group on first launch but respect an
/// explicit personal selection thereafter.
const String kPersonalModeSentinel = '__PERSONAL__';

/// Persistent user-selected active group.
///
/// Three possible states:
/// - `null` — unset (no persisted preference). Downstream falls back to the
///   first available group membership (legacy first-launch behaviour).
/// - [kPersonalModeSentinel] — user explicitly picked personal mode. The
///   downstream [activeFamilyGroupProvider] resolves to `null` regardless
///   of memberships.
/// - `<group-uuid>` — user explicitly picked a specific group.
///
/// Persists across app restarts via shared_preferences.
final activeGroupIdProvider =
    StateNotifierProvider<ActiveGroupNotifier, String?>((ref) {
  return ActiveGroupNotifier();
});

/// Notifier for [activeGroupIdProvider].
///
/// Reads the persisted active-group id from [SharedPreferences] on
/// construction. While the async read is pending, [state] is `null`; the
/// downstream [activeFamilyGroupProvider] uses a "first membership row"
/// fallback so behaviour matches the legacy single-group assumption until
/// the user explicitly picks a different group.
class ActiveGroupNotifier extends StateNotifier<String?> {
  ActiveGroupNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    // Guard against the notifier being disposed before the async load
    // completes (e.g. fast sign-out during cold start).
    if (!mounted) return;
    // state is now:
    //   null  → no persisted preference (unset, default-to-first behaviour)
    //   kPersonalModeSentinel → user explicitly picked personal
    //   <uuid> → user explicitly picked a group
    state = prefs.getString(_kActiveGroupIdPrefKey);
  }

  /// Set the active group id. Pass `null` to explicitly select personal
  /// mode — this persists [kPersonalModeSentinel] so the next launch
  /// honours the choice (instead of falling back to "first group").
  /// Updates state synchronously and persists asynchronously.
  Future<void> setActive(String? groupId) async {
    final persisted = groupId ?? kPersonalModeSentinel;
    state = persisted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kActiveGroupIdPrefKey, persisted);
  }
}

/// Provider that returns the user's currently-active family group membership
/// row.
///
/// Watches the `family_group_members` table so it reactively updates when the
/// user joins or leaves a group — no manual invalidation needed.
///
/// Selection logic:
/// 1. If [activeGroupIdProvider] holds a non-null id AND a membership row
///    exists for that group, return that row.
/// 2. Otherwise, fall back to `rows.first` (preserves the legacy single-group
///    behaviour for users who haven't explicitly picked a group yet — e.g.
///    on first app launch before [ActiveGroupNotifier._load] resolves).
/// 3. If the user has no memberships at all, returns `null`.
///
/// Returns the group id, the linked `relative_id_in_tree` (if any), and the
/// membership `role` ('admin' or 'member').
final activeFamilyGroupProvider = StreamProvider.autoDispose<
    ({String groupId, String? nodeId, String? role})?>((ref) {
  final link = ref.keepAlive();
  Timer? timer;

  ref.onDispose(() => timer?.cancel());
  ref.onCancel(() {
    timer = Timer(_cacheTimeout, () => link.close());
  });
  ref.onResume(() => timer?.cancel());

  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) return Stream.value(null);

  final activeId = ref.watch(activeGroupIdProvider);

  return SupabaseConfig.client
      .from('family_group_members')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .map((rows) {
        if (rows.isEmpty) return null;

        // Explicit personal mode → no active group, regardless of
        // memberships. Banner hidden, personal scope.
        if (activeId == kPersonalModeSentinel) return null;

        // Try to find a row matching the user's selected active group id.
        // If activeId is null (no selection yet — first launch) or stale
        // (user left that group), fall back to the first membership row.
        Map<String, dynamic>? data;
        if (activeId != null) {
          for (final row in rows) {
            if (row['group_id'] == activeId) {
              data = row;
              break;
            }
          }
        }
        data ??= rows.first;

        final groupId = data['group_id'] as String?;
        if (groupId == null) return null;
        final nodeId = data['relative_id_in_tree'] as String?;
        final role = data['role'] as String?;
        return (groupId: groupId, nodeId: nodeId, role: role);
      });
});

/// Whether the current user is an admin of their active family group.
///
/// Returns `false` when the user is not in a group, has not yet loaded
/// their membership row, or holds a `'member'` role. Returns `true` only
/// when the membership row exists and `role == 'admin'`.
///
/// Drives the default scope for newly-added relatives:
/// - admin -> defaults to shared lineage (`family_group_id = group_id`)
/// - member -> defaults to personal (`family_group_id IS NULL`)
final isAdminOfActiveGroupProvider = Provider.autoDispose<bool>((ref) {
  final groupInfo = ref.watch(activeFamilyGroupProvider).valueOrNull;
  return groupInfo?.role == 'admin';
});

/// Stream provider for the set of node IDs claimed by group members.
///
/// Returns the `relative_id_in_tree` values for all members of [groupId].
/// Used to determine which tree nodes should display a "linked member" badge.
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

/// The set of relative IDs visible to the current viewer via rahim scope.
///
/// Returns `null` when:
/// - User is not in a group (personal mode — no filtering needed)
/// - Viewer has no linked node yet (hasn't claimed a tree node)
/// - Graph data hasn't loaded yet (callers should show all relatives as fallback)
///
/// A non-null result means "only show these IDs" in group mode.
/// This is the **single source of truth** for rahim visibility — every
/// provider / screen that displays group relatives should consult this
/// instead of computing the scope independently.
final rahimVisibleRelativeIdsProvider =
    Provider.autoDispose<Set<String>?>((ref) {
  final groupInfo = ref.watch(activeFamilyGroupProvider).valueOrNull;
  if (groupInfo == null || groupInfo.nodeId == null) return null;

  final graph = ref.watch(sharedFamilyGraphProvider((
    groupId: groupInfo.groupId,
    viewerNodeId: groupInfo.nodeId,
  )));
  if (graph == null) return null;

  final enriched = FamilyGraphService.enrichAllSiblingEdges(graph);
  return FamilyGraphService.computeRahimScope(
    viewerId: groupInfo.nodeId!,
    graph: enriched,
  );
});

/// Stream provider for all relatives in a family group.
///
/// Returns all relatives that belong to a specific family group,
/// regardless of which user added them. This allows group members
/// to see the entire shared tree, not just their own relatives.
final groupRelativesStreamProvider =
    StreamProvider.autoDispose.family<List<Relative>, String>((ref, groupId) {
  final link = ref.keepAlive();
  Timer? timer;

  ref.onDispose(() => timer?.cancel());
  ref.onCancel(() {
    timer = Timer(_cacheTimeout, () => link.close());
  });
  ref.onResume(() => timer?.cancel());

  return SupabaseConfig.client
      .from('relatives')
      .stream(primaryKey: ['id'])
      .eq('family_group_id', groupId)
      .map((data) => data
          .map((json) => Relative.fromJson(json))
          .where((r) => !r.isArchived)
          .toList());
});

/// Group-context relatives: shared group relatives + the viewer's own
/// personal relatives (`family_group_id IS NULL`).
///
/// When a non-admin member adds a relative it lands in personal scope
/// (Task A1/A2), so the shared-tree stream alone would hide their own
/// additions. This provider merges both. Other members never see the
/// viewer's personal rows because the underlying personal stream is
/// filtered by `user_id` at the RLS layer.
final groupTreeRelativesProvider =
    Provider.autoDispose.family<AsyncValue<List<Relative>>, String>((ref, groupId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const AsyncValue.data([]);

  final groupAsync = ref.watch(groupRelativesStreamProvider(groupId));
  final personalAsync = ref.watch(relativesStreamProvider(user.id));

  if (groupAsync.isLoading && personalAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (groupAsync.hasError && personalAsync.hasError) {
    return AsyncValue.error(
      groupAsync.error!,
      groupAsync.stackTrace ?? StackTrace.current,
    );
  }

  final groupList = groupAsync.valueOrNull ?? const <Relative>[];
  // Keep ONLY the viewer's personal rows. The owned-rows stream also
  // contains rows the viewer added to this (or another) group; those are
  // already covered by the shared stream for this group, so we drop any
  // row with a non-null family_group_id here.
  final personalList = (personalAsync.valueOrNull ?? const <Relative>[])
      .where((r) => r.familyGroupId == null)
      .toList();

  // Dedup by id (defensive — scopes are disjoint by design).
  final byId = <String, Relative>{};
  for (final r in groupList) {
    byId[r.id] = r;
  }
  for (final r in personalList) {
    byId.putIfAbsent(r.id, () => r);
  }

  // Logical identity bridge: the viewer's personal NULL-scope self-node is
  // "merged" into the in-group self for display. The in-group self is the
  // visible anchor; the personal self-row would otherwise render as a
  // duplicate of the viewer (and its edges have been rewritten to point at
  // the in-group self in [groupTreeEdgesProvider]).
  final filtered = byId.values
      .where((r) =>
          !(r.isSelf && r.familyGroupId == null && r.userId == user.id))
      .toList();

  return AsyncValue.data(filtered);
});
