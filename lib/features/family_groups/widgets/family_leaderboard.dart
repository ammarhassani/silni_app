import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silni_app/features/widgets/home_widget_service.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/premium_loading_indicator.dart';
import '../../../shared/widgets/share_card_widget.dart';
import '../../../shared/widgets/shareable_card_generator.dart';
import '../providers/leaderboard_provider.dart';
import '../services/leaderboard_service.dart';

/// Displays the weekly family group interaction leaderboard.
///
/// Shows ranked entries with medal emojis for top 3, interaction counts
/// in Arabic numerals, and a share button for the #1 position.
/// Uses GlassCard with a gold tint for the first-place entry.
class FamilyLeaderboard extends ConsumerWidget {
  final String groupId;

  const FamilyLeaderboard({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final leaderboardAsync = ref.watch(weeklyLeaderboardProvider(groupId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section title
        Text(
          '\u{1F3C6} ترتيب الأسبوع',
          style: AppTypography.titleMedium.copyWith(
            color: themeColors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        leaderboardAsync.when(
          data: (entries) => _buildLeaderboard(context, themeColors, entries),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: PremiumLoadingIndicator(),
            ),
          ),
          error: (error, _) => GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'حدث خطأ في تحميل الترتيب',
              style: AppTypography.bodyMedium.copyWith(
                color: themeColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboard(
    BuildContext context,
    dynamic themeColors,
    List<LeaderboardEntry> entries,
  ) {
    // Filter out entries with zero interactions
    final activeEntries =
        entries.where((e) => e.interactionCount > 0).toList();

    if (activeEntries.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            const Text(
              '\u{1F4AD}',
              style: TextStyle(fontSize: 32),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'ما فيه تواصل هالأسبوع بعد\nكن أول واحد يتواصل!',
              style: AppTypography.bodyMedium.copyWith(
                color: themeColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: activeEntries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _LeaderboardEntryCard(
            entry: entry,
            groupId: groupId,
          ),
        );
      }).toList(),
    );
  }
}

/// A single leaderboard entry card.
///
/// Shows rank medal/number, user ID, interaction summary in Arabic,
/// and a share button for the #1 position. First place gets a gold tint.
class _LeaderboardEntryCard extends ConsumerWidget {
  final LeaderboardEntry entry;
  final String groupId;

  const _LeaderboardEntryCard({
    required this.entry,
    required this.groupId,
  });

  /// Get the medal emoji for top 3 ranks, or the rank number for others.
  String _rankDisplay(int rank) {
    switch (rank) {
      case 1:
        return '\u{1F947}'; // gold medal
      case 2:
        return '\u{1F948}'; // silver medal
      case 3:
        return '\u{1F949}'; // bronze medal
      default:
        return HomeWidgetService.toArabicNumerals(rank);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final isFirstPlace = entry.rank == 1;
    final arabicCount =
        HomeWidgetService.toArabicNumerals(entry.uniqueRelatives);

    return GlassCard(
      // Gold tint for first place
      gradient: isFirstPlace
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                themeColors.secondary.withValues(alpha: 0.3),
                themeColors.glassBackground,
              ],
            )
          : null,
      border: isFirstPlace
          ? Border.all(
              color: themeColors.secondary.withValues(alpha: 0.5),
              width: 1.5,
            )
          : null,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Rank medal or number
          SizedBox(
            width: AppSpacing.avatarSm,
            child: Text(
              _rankDisplay(entry.rank),
              style: entry.rank <= 3
                  ? const TextStyle(fontSize: 24)
                  : AppTypography.titleMedium.copyWith(
                      color: themeColors.onSurface,
                    ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Avatar
          CircleAvatar(
            radius: AppSpacing.avatarSm / 2,
            backgroundColor: isFirstPlace
                ? themeColors.secondary.withValues(alpha: 0.3)
                : themeColors.onSurface.withValues(alpha: 0.15),
            child: Icon(
              Icons.person_rounded,
              size: AppSpacing.iconSm,
              color: isFirstPlace ? themeColors.secondary : themeColors.onSurface,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Member info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName ?? entry.userId,
                  style: AppTypography.bodyMedium.copyWith(
                    color: themeColors.onSurface,
                    fontWeight:
                        isFirstPlace ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '\u0643\u0644\u0645 $arabicCount \u0623\u0642\u0627\u0631\u0628 \u0647\u0627\u0644\u0623\u0633\u0628\u0648\u0639', // كلم X أقارب هالأسبوع
                  style: AppTypography.bodySmall.copyWith(
                    color: themeColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Share button (only for #1)
          if (isFirstPlace)
            IconButton(
              onPressed: () => _shareLeaderboardWin(context),
              icon: Icon(
                Icons.share_rounded,
                size: AppSpacing.iconSm,
                color: themeColors.secondary,
              ),
              tooltip: 'شارك الإنجاز',
            ),
        ],
      ),
    );
  }

  /// Share the #1 position as a branded card image.
  void _shareLeaderboardWin(BuildContext context) {
    final displayName = entry.displayName ?? 'أحد الأعضاء';
    final arabicCount =
        HomeWidgetService.toArabicNumerals(entry.uniqueRelatives);

    final cardData = ShareableCardData(
      emoji: '\u{1F947}', // gold medal
      title: '$displayName \u{1F947}', // name + medal
      subtitle:
          '\u0643\u0644\u0645 $arabicCount \u0623\u0642\u0627\u0631\u0628 \u0647\u0627\u0644\u0623\u0633\u0628\u0648\u0639!', // كلم X أقارب هالأسبوع!
      shareText:
          '$displayName \u0643\u0644\u0645 $arabicCount \u0623\u0642\u0627\u0631\u0628 \u0647\u0627\u0644\u0623\u0633\u0628\u0648\u0639 \u{1F947} #\u0635\u0650\u0644\u0646\u064A', // name كلم X أقارب هالأسبوع 🥇 #صِلني
    );

    ShareCardWidget.captureAndShare(context, cardData);
  }
}
