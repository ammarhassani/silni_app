import 'package:silni_app/shared/models/interaction_model.dart';

/// Monthly Wrapped summary data — the "Spotify Wrapped" of family connections.
///
/// Contains aggregated stats for a single calendar month plus a
/// personality label derived from the user's interaction patterns.
class MonthlyWrapped {
  /// First day of the summarised month.
  final DateTime month;

  /// Total number of interactions recorded this month.
  final int totalInteractions;

  /// Number of distinct relatives contacted this month.
  final int uniqueRelativesContacted;

  /// Fraction of all relatives that were contacted (0.0 - 1.0).
  final double relativesCoverage;

  /// Name of the relative with the most interactions, or null if none.
  final String? mostContactedRelativeName;

  /// Interaction count for the most-contacted relative, or null if none.
  final int? mostContactedRelativeCount;

  /// Longest run of consecutive days with at least one interaction.
  final int longestStreak;

  /// Arabic personality label (e.g. "ملك الزيارات") — deterministic fallback.
  final String personalityLabel;

  /// Emoji representing the personality label — deterministic fallback.
  final String personalityEmoji;

  /// Per-type breakdown of interactions (e.g. {call: 5, visit: 3}).
  final Map<InteractionType, int> interactionBreakdown;

  /// The interaction type used most often, or null if no interactions.
  final InteractionType? mostUsedInteractionType;

  /// The weekday with the most interactions (1=Mon…7=Sun), or null.
  final int? busiestDayOfWeek;

  /// Average interactions per week during this month.
  final double averageInteractionsPerWeek;

  /// AI-generated creative personality title, or null if not yet generated.
  final String? aiPersonalityTitle;

  /// AI-generated personality emoji, or null if not yet generated.
  final String? aiPersonalityEmoji;

  const MonthlyWrapped({
    required this.month,
    required this.totalInteractions,
    required this.uniqueRelativesContacted,
    required this.relativesCoverage,
    this.mostContactedRelativeName,
    this.mostContactedRelativeCount,
    required this.longestStreak,
    required this.personalityLabel,
    required this.personalityEmoji,
    required this.interactionBreakdown,
    this.mostUsedInteractionType,
    this.busiestDayOfWeek,
    this.averageInteractionsPerWeek = 0.0,
    this.aiPersonalityTitle,
    this.aiPersonalityEmoji,
  });

  /// Returns the AI-generated title if available, otherwise the deterministic label.
  String get effectivePersonalityLabel => aiPersonalityTitle ?? personalityLabel;

  /// Returns the AI-generated emoji if available, otherwise the deterministic one.
  String get effectivePersonalityEmoji => aiPersonalityEmoji ?? personalityEmoji;

  /// Creates a copy with overridden AI personality fields.
  MonthlyWrapped copyWith({
    String? aiPersonalityTitle,
    String? aiPersonalityEmoji,
  }) {
    return MonthlyWrapped(
      month: month,
      totalInteractions: totalInteractions,
      uniqueRelativesContacted: uniqueRelativesContacted,
      relativesCoverage: relativesCoverage,
      mostContactedRelativeName: mostContactedRelativeName,
      mostContactedRelativeCount: mostContactedRelativeCount,
      longestStreak: longestStreak,
      personalityLabel: personalityLabel,
      personalityEmoji: personalityEmoji,
      interactionBreakdown: interactionBreakdown,
      mostUsedInteractionType: mostUsedInteractionType,
      busiestDayOfWeek: busiestDayOfWeek,
      averageInteractionsPerWeek: averageInteractionsPerWeek,
      aiPersonalityTitle: aiPersonalityTitle ?? this.aiPersonalityTitle,
      aiPersonalityEmoji: aiPersonalityEmoji ?? this.aiPersonalityEmoji,
    );
  }

  /// Arabic month names (1-indexed: index 0 is unused).
  static const List<String> arabicMonthNames = [
    '', // placeholder for 0-index
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  /// Arabic weekday names (1-indexed: 1=Monday…7=Sunday, index 0 unused).
  static const List<String> arabicWeekdayNames = [
    '',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  /// The Arabic name for this month (e.g. "يناير").
  String get arabicMonthName => arabicMonthNames[month.month];
}
