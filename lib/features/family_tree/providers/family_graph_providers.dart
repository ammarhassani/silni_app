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
