import '../../shared/models/interaction_model.dart';
import '../../shared/models/relative_model.dart';
import 'contact_priority_service.dart';

/// A locally-generated insight about the user's family contact patterns.
///
/// Unlike [AIInsightCard] (which requires MAX subscription and cloud AI),
/// proactive insights work for ALL users using pure local pattern analysis.
class ProactiveInsight {
  /// The type of insight: 'gap', 'pattern', 'positive', 'suggestion'.
  final String type;

  /// The human-readable insight message (Arabic / Saudi dialect).
  final String message;

  /// An emoji representing the insight visually.
  final String emoji;

  /// Optional relative ID for navigation (e.g., tapping the card).
  final String? relativeId;

  const ProactiveInsight({
    required this.type,
    required this.message,
    required this.emoji,
    this.relativeId,
  });
}

/// Pure static service that generates one proactive insight per invocation.
///
/// Rules are checked in priority order; the first match wins:
///   1. Gap detection — high-priority relative not contacted in 5+ days
///   2. Imbalance detection — one parent contacted 3x more than the other
///   3. Positive reinforcement — family pulse >= 0.8
///   4. Variety suggestion — 80%+ of recent interactions are calls
///   5. null — no actionable pattern found
class ProactiveInsightService {
  ProactiveInsightService._();

  /// Generates one insight based on the user's relatives and interactions.
  ///
  /// Returns `null` when no actionable pattern is detected.
  static ProactiveInsight? generateInsight({
    required List<Relative> relatives,
    required List<Interaction> interactions,
  }) {
    final active = relatives.where((r) => !r.isArchived).toList();
    if (active.isEmpty) return null;

    // 1. Gap detection
    final gapInsight = _detectGap(active);
    if (gapInsight != null) return gapInsight;

    // 2. Imbalance detection
    final imbalanceInsight = _detectImbalance(active, interactions);
    if (imbalanceInsight != null) return imbalanceInsight;

    // 3. Positive reinforcement
    final positiveInsight = _detectPositive(active);
    if (positiveInsight != null) return positiveInsight;

    // 4. Variety suggestion
    final varietyInsight = _detectVariety(interactions);
    if (varietyInsight != null) return varietyInsight;

    return null;
  }

  // ---------------------------------------------------------------
  // 1. Gap detection
  // ---------------------------------------------------------------

  /// Finds priority-1 relatives (parents/spouse) not contacted in 5+ days.
  /// Returns the insight for the most overdue one.
  static ProactiveInsight? _detectGap(List<Relative> active) {
    final highPriority = active.where((r) => r.priority == 1).toList();
    if (highPriority.isEmpty) return null;

    // Sort by days since last contact descending (most overdue first)
    Relative? mostOverdue;
    int maxDays = 0;

    for (final relative in highPriority) {
      final days = relative.daysSinceLastContact;
      if (days != null && days >= 5 && days > maxDays) {
        mostOverdue = relative;
        maxDays = days;
      }
    }

    if (mostOverdue == null) return null;

    return ProactiveInsight(
      type: 'gap',
      message: 'ما كلمت ${mostOverdue.fullName} من $maxDays يوم، وش رأيك تسلم عليهم؟',
      emoji: '📞',
      relativeId: mostOverdue.id,
    );
  }

  // ---------------------------------------------------------------
  // 2. Imbalance detection
  // ---------------------------------------------------------------

  /// Checks if one parent is contacted 3x more than the other this month.
  static ProactiveInsight? _detectImbalance(
    List<Relative> active,
    List<Interaction> interactions,
  ) {
    // Find parents (father & mother)
    final parents = active.where((r) =>
        r.relationshipType == RelationshipType.father ||
        r.relationshipType == RelationshipType.mother).toList();

    if (parents.length < 2) return null;

    // Count interactions for each parent in last 30 days
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recentInteractions =
        interactions.where((i) => i.date.isAfter(thirtyDaysAgo)).toList();

    final parentCounts = <String, int>{};
    for (final parent in parents) {
      parentCounts[parent.id] =
          recentInteractions.where((i) => i.relativeId == parent.id).length;
    }

    // Find the parent with the most and least interactions
    Relative? moreContacted;
    Relative? lessContacted;
    int maxCount = 0;
    int minCount = 999999;

    for (final parent in parents) {
      final count = parentCounts[parent.id] ?? 0;
      if (count >= maxCount) {
        maxCount = count;
        moreContacted = parent;
      }
      if (count <= minCount) {
        minCount = count;
        lessContacted = parent;
      }
    }

    if (moreContacted == null || lessContacted == null) return null;
    if (moreContacted.id == lessContacted.id) return null;

    // Check 3x ratio: more >= 3 * less (and less must be > 0 or more >= 3)
    if (maxCount >= 3 && (minCount == 0 || maxCount >= 3 * minCount)) {
      final lessCountText = minCount == 0
          ? 'ولا مرة'
          : minCount == 1
              ? 'مرة واحدة'
              : '$minCount مرات';
      final moreCountText = '$maxCount مرات';

      return ProactiveInsight(
        type: 'pattern',
        message:
            '${lessContacted.fullName} ممكن يحتاج اهتمام أكثر، كلمته $lessCountText هالشهر بينما ${moreContacted.fullName} كلمته $moreCountText',
        emoji: '⚖️',
        relativeId: lessContacted.id,
      );
    }

    return null;
  }

  // ---------------------------------------------------------------
  // 3. Positive reinforcement
  // ---------------------------------------------------------------

  /// Shows a positive message when family pulse is >= 0.8.
  static ProactiveInsight? _detectPositive(List<Relative> active) {
    final pulse = ContactPriorityService.getFamilyPulse(active);
    if (pulse >= 0.8) {
      return const ProactiveInsight(
        type: 'positive',
        message: 'ما شاء الله، تواصلك مع العائلة ممتاز هالفترة! 💚',
        emoji: '🌟',
      );
    }
    return null;
  }

  // ---------------------------------------------------------------
  // 4. Variety suggestion
  // ---------------------------------------------------------------

  /// Suggests visits if 80%+ of recent interactions are calls.
  static ProactiveInsight? _detectVariety(List<Interaction> interactions) {
    if (interactions.isEmpty) return null;

    // Only look at last 30 days
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recent =
        interactions.where((i) => i.date.isAfter(thirtyDaysAgo)).toList();

    if (recent.length < 5) return null; // Need enough data to judge

    final callCount =
        recent.where((i) => i.type == InteractionType.call).length;
    final callRatio = callCount / recent.length;

    if (callRatio >= 0.8) {
      return const ProactiveInsight(
        type: 'suggestion',
        message: 'جرّب تزور أحد من عائلتك بدل المكالمة، الزيارات لها طعم ثاني',
        emoji: '🏠',
      );
    }

    return null;
  }
}
