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

  /// Arabic personality label (e.g. "ملك الزيارات").
  final String personalityLabel;

  /// Emoji representing the personality label.
  final String personalityEmoji;

  /// Per-type breakdown of interactions (e.g. {call: 5, visit: 3}).
  final Map<InteractionType, int> interactionBreakdown;

  /// Number of distinct calendar days with at least one interaction.
  final int totalActiveDays;

  /// Per-month interaction totals (key: month number 1-12, value: count).
  final Map<int, int> monthlyTotals;

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
  });
}
