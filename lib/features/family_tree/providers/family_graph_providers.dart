import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
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
/// are computed relative to them.
final sharedFamilyGraphProvider = Provider.autoDispose
    .family<FamilyGraph?, ({String groupId, String viewerNodeId})>((ref, params) {
  final edgesAsync = ref.watch(sharedFamilyEdgesStreamProvider(params.groupId));
  return edgesAsync.whenData((edges) {
    if (edges.isEmpty) return null;
    return FamilyGraphService.buildGraph(
      userId: params.viewerNodeId,
      edges: edges,
    );
  }).valueOrNull;
});

/// Provider that returns the user's family group membership info.
///
/// Queries for the first group where the user has a `relative_id_in_tree`
/// set (meaning they've been linked to a node in the shared tree).
/// Returns null if the user is not in any shared tree.
final userFamilyGroupProvider =
    FutureProvider.autoDispose<({String groupId, String nodeId})?>(
      (ref) async {
  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) return null;

  final data = await SupabaseConfig.client
      .from('family_group_members')
      .select('group_id, relative_id_in_tree')
      .eq('user_id', user.id)
      .not('relative_id_in_tree', 'is', null)
      .limit(1)
      .maybeSingle();

  if (data == null) return null;
  final groupId = data['group_id'] as String?;
  final nodeId = data['relative_id_in_tree'] as String?;
  if (groupId == null || nodeId == null) return null;
  return (groupId: groupId, nodeId: nodeId);
});
