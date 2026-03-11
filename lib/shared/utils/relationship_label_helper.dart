import '../../features/family_tree/models/family_graph.dart';
import '../../features/family_tree/services/family_graph_service.dart';
import '../models/relative_model.dart';

/// Resolve a specific Arabic label using [RelationshipType] + [FamilySide].
///
/// When [side] is known, disambiguates generic labels:
///   uncle + paternal → "عم",  uncle + maternal → "خال"
///   aunt  + paternal → "عمة", aunt  + maternal → "خالة"
/// Falls back to [type.arabicName] when side is null or type is unambiguous.
String getSideAwareLabel(RelationshipType type, FamilySide? side, Gender? gender) {
  if (side == null) return type.arabicName;

  switch (type) {
    case RelationshipType.uncle:
      return side == FamilySide.paternal ? 'عم' : 'خال';
    case RelationshipType.aunt:
      return side == FamilySide.paternal ? 'عمة' : 'خالة';
    case RelationshipType.cousin:
      if (side == FamilySide.paternal) {
        return gender == Gender.female ? 'بنت العم' : 'ابن العم';
      }
      return gender == Gender.female ? 'بنت الخال' : 'ابن الخال';
    default:
      return type.arabicName;
  }
}

/// Compute the display label for a relative, using the family graph if available.
///
/// When graph data exists, uses [FamilyGraphService.getLabelForViewer] to
/// produce perspective-shifted Arabic labels (e.g. "عمي" instead of "عم/خال").
///
/// Falls back to [getSideAwareLabel] when:
/// - [graph] is null (no edges table data yet)
/// - [relativesMap] is null
String getRelationshipLabel({
  required Relative relative,
  required String viewerId,
  FamilyGraph? graph,
  Map<String, Relative>? relativesMap,
}) {
  if (graph == null || relativesMap == null) {
    return getSideAwareLabel(relative.relationshipType, relative.familySide, relative.gender);
  }

  final label = FamilyGraphService.getLabelForViewer(
    graph: graph,
    viewerId: viewerId,
    targetId: relative.id,
    relativesMap: relativesMap,
  );

  // If getLabelForViewer returns empty, use the side-aware label
  return label.isNotEmpty
      ? label
      : getSideAwareLabel(relative.relationshipType, relative.familySide, relative.gender);
}

/// Convert first-person possessive label (عمي) to second-person (عمك).
///
/// Used when واصل (the AI) speaks TO the user about their relative.
String toSecondPerson(String label) {
  if (label == 'أبي') return 'والدك';
  if (label == 'أخوي') return 'أخوك';
  if (label.endsWith('ي')) {
    return '${label.substring(0, label.length - 1)}ك';
  }
  return label;
}
