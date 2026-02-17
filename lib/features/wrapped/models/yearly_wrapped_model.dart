import 'package:silni_app/shared/models/interaction_model.dart';

/// Yearly Wrapped summary data — the "Spotify Wrapped" of family connections,
/// aggregated over an entire calendar year.
///
/// Contains the same core stats as [MonthlyWrapped] plus year-specific
/// fields like [totalActiveDays] and [monthlyTotals].
class YearlyWrapped {
  /// The calendar year summarised (e.g. 2025).
  final int year;

  /// Total number of interactions recorded this year.
  final int totalInteractions;

  /// Number of distinct relatives contacted this year.
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

  /// Number of distinct calendar days with at least one interaction.
  final int totalActiveDays;

  /// Per-month interaction totals (key: month number 1-12, value: count).
  final Map<int, int> monthlyTotals;

  /// The interaction type used most often, or null if no interactions.
  final InteractionType? mostUsedInteractionType;

  /// The weekday with the most interactions (1=Mon…7=Sun), or null.
  final int? busiestDayOfWeek;

  /// Average interactions per month across the year.
  final double averageInteractionsPerMonth;

  /// The month (1-12) with the highest interaction count, or null.
  final int? peakMonth;

  /// The interaction count for the peak month, or null.
  final int? peakMonthCount;

  /// AI-generated creative personality title, or null if not yet generated.
  final String? aiPersonalityTitle;

  /// AI-generated personality emoji, or null if not yet generated.
  final String? aiPersonalityEmoji;

  const YearlyWrapped({
    required this.year,
    required this.totalInteractions,
    required this.uniqueRelativesContacted,
    required this.relativesCoverage,
    this.mostContactedRelativeName,
    this.mostContactedRelativeCount,
    required this.longestStreak,
    required this.personalityLabel,
    required this.personalityEmoji,
    required this.interactionBreakdown,
    required this.totalActiveDays,
    required this.monthlyTotals,
    this.mostUsedInteractionType,
    this.busiestDayOfWeek,
    this.averageInteractionsPerMonth = 0.0,
    this.peakMonth,
    this.peakMonthCount,
    this.aiPersonalityTitle,
    this.aiPersonalityEmoji,
  });

  /// Returns the AI-generated title if available, otherwise the deterministic label.
  String get effectivePersonalityLabel => aiPersonalityTitle ?? personalityLabel;

  /// Returns the AI-generated emoji if available, otherwise the deterministic one.
  String get effectivePersonalityEmoji => aiPersonalityEmoji ?? personalityEmoji;

  /// Creates a copy with overridden AI personality fields.
  YearlyWrapped copyWith({
    String? aiPersonalityTitle,
    String? aiPersonalityEmoji,
  }) {
    return YearlyWrapped(
      year: year,
      totalInteractions: totalInteractions,
      uniqueRelativesContacted: uniqueRelativesContacted,
      relativesCoverage: relativesCoverage,
      mostContactedRelativeName: mostContactedRelativeName,
      mostContactedRelativeCount: mostContactedRelativeCount,
      longestStreak: longestStreak,
      personalityLabel: personalityLabel,
      personalityEmoji: personalityEmoji,
      interactionBreakdown: interactionBreakdown,
      totalActiveDays: totalActiveDays,
      monthlyTotals: monthlyTotals,
      mostUsedInteractionType: mostUsedInteractionType,
      busiestDayOfWeek: busiestDayOfWeek,
      averageInteractionsPerMonth: averageInteractionsPerMonth,
      peakMonth: peakMonth,
      peakMonthCount: peakMonthCount,
      aiPersonalityTitle: aiPersonalityTitle ?? this.aiPersonalityTitle,
      aiPersonalityEmoji: aiPersonalityEmoji ?? this.aiPersonalityEmoji,
    );
  }
}
