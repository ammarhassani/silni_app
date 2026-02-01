import '../../features/family_tree/models/family_graph.dart';
import '../../features/family_tree/services/family_graph_service.dart';
import '../models/relative_model.dart';

/// Compute the display label for a relative, using the family graph if available.
///
/// When graph data exists, uses [FamilyGraphService.getLabelForViewer] to
/// produce perspective-shifted Arabic labels (e.g. "عمي" instead of "عم/خال").
///
/// Falls back to [Relative.relationshipType.arabicName] when:
/// - [graph] is null (no edges table data yet)
/// - [relativesMap] is null
/// - The graph returns an empty string for the target
String getRelationshipLabel({
  required Relative relative,
  required String viewerId,
  FamilyGraph? graph,
  Map<String, Relative>? relativesMap,
}) {
  if (graph == null || relativesMap == null) {
    return relative.relationshipType.arabicName;
  }

  final label = FamilyGraphService.getLabelForViewer(
    graph: graph,
    viewerId: viewerId,
    targetId: relative.id,
    relativesMap: relativesMap,
  );

  // If getLabelForViewer returns empty, use the canonical arabicName
  return label.isNotEmpty ? label : relative.relationshipType.arabicName;
}
