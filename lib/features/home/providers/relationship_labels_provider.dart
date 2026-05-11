import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/relationship_label_helper.dart';
import '../../../core/config/supabase_config.dart';
import '../../family_tree/providers/family_graph_providers.dart';
import 'home_providers.dart';

/// Centralized provider for perspective-aware relationship labels.
///
/// Computes Arabic labels (e.g. "\u0639\u0645\u064a", "\u062e\u0627\u0644\u062a\u064a") for all viewer-filtered
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

  final groupInfo = ref.watch(activeFamilyGroupProvider).valueOrNull;
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
