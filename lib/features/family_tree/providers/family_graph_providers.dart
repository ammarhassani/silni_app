import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Provider that builds a [FamilyGraph] from the user's edges.
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
  final edgesAsync = ref.watch(familyEdgesStreamProvider(userId));
  return edgesAsync.whenData((edges) {
    if (edges.isEmpty) return null;
    return FamilyGraphService.buildGraph(userId: userId, edges: edges);
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
final groupTreeEdgesProvider =
    Provider.autoDispose.family<AsyncValue<List<FamilyEdge>>, String>((ref, groupId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const AsyncValue.data([]);

  final groupAsync = ref.watch(sharedFamilyEdgesStreamProvider(groupId));
  final personalAsync = ref.watch(familyEdgesStreamProvider(user.id));

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

  return AsyncValue.data(byId.values.toList());
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

/// Provider that returns the user's family group membership info.
///
/// Watches the `family_group_members` table so it reactively updates
/// when the user joins or leaves a group — no manual invalidation needed.
/// Returns the group ID and optionally the `relative_id_in_tree` if linked.
final userFamilyGroupProvider =
    StreamProvider.autoDispose<({String groupId, String? nodeId})?>(
      (ref) {
  final link = ref.keepAlive();
  Timer? timer;

  ref.onDispose(() => timer?.cancel());
  ref.onCancel(() {
    timer = Timer(_cacheTimeout, () => link.close());
  });
  ref.onResume(() => timer?.cancel());

  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) return Stream.value(null);

  return SupabaseConfig.client
      .from('family_group_members')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .map((rows) {
        if (rows.isEmpty) return null;
        final data = rows.first;
        final groupId = data['group_id'] as String?;
        if (groupId == null) return null;
        final nodeId = data['relative_id_in_tree'] as String?;
        return (groupId: groupId, nodeId: nodeId);
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
final isAdminOfActiveGroupProvider =
    StreamProvider.autoDispose<bool>((ref) {
  final link = ref.keepAlive();
  Timer? timer;

  ref.onDispose(() => timer?.cancel());
  ref.onCancel(() {
    timer = Timer(_cacheTimeout, () => link.close());
  });
  ref.onResume(() => timer?.cancel());

  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) return Stream.value(false);

  return SupabaseConfig.client
      .from('family_group_members')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .map((rows) {
        if (rows.isEmpty) return false;
        final role = rows.first['role'] as String?;
        return role == 'admin';
      });
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
  final groupInfo = ref.watch(userFamilyGroupProvider).valueOrNull;
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

  return AsyncValue.data(byId.values.toList());
});
