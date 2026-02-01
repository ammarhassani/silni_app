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

  /// Arabic personality label (e.g. "ملك الزيارات").
  final String personalityLabel;

  /// Emoji representing the personality label.
  final String personalityEmoji;

  /// Per-type breakdown of interactions (e.g. {call: 5, visit: 3}).
  final Map<InteractionType, int> interactionBreakdown;

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
  });

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

  /// The Arabic name for this month (e.g. "يناير").
  String get arabicMonthName => arabicMonthNames[month.month];
}
