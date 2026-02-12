import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../shared/models/relative_model.dart';
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

/// Build a shared graph with a specific viewer as anchor.
///
/// [viewerNodeId] is the relative_id_in_tree of the current viewer,
/// used as the userId for graph construction so perspective labels
/// are computed relative to them. If null, uses the first `is_self` node
/// found, or falls back to an empty string (no perspective).
final sharedFamilyGraphProvider = Provider.autoDispose
    .family<FamilyGraph?, ({String groupId, String? viewerNodeId})>((ref, params) {
  final edgesAsync = ref.watch(sharedFamilyEdgesStreamProvider(params.groupId));
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

/// Stream provider for the set of node IDs claimed by group members.
///
/// Returns the `relative_id_in_tree` values for all members of [groupId].
/// Used to determine which tree nodes should display a "linked member" badge.
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
