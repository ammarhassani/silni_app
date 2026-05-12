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

  // Personal mode: the viewer in the bridged graph is the user's personal
  // NULL-scope self-node relative_id, NOT their auth UUID. If we pass the
  // auth uid here, BFS from the viewer finds nothing and getLabelForViewer
  // falls back to target.fullName for every relative — labels render as
  // names ("Dad❤️" instead of "أبي", "testprodjoiner" instead of "زوجتي").
  String? personalSelfId;
  if (groupInfo == null) {
    final ownedRelatives =
        ref.watch(relativesStreamProvider(user.id)).valueOrNull ?? const [];
    for (final r in ownedRelatives) {
      if (r.isSelf && r.familyGroupId == null && r.userId == user.id) {
        personalSelfId = r.id;
        break;
      }
    }
  }
  final effectiveViewerId = groupInfo?.nodeId ?? personalSelfId ?? user.id;

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
