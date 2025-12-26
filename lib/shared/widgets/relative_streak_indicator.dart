import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/relative_streak_model.dart';
import '../../core/providers/relative_streak_provider.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/theme_provider.dart';

/// Compact widget to display per-relative streak
/// Shows fire emoji + count when healthy, hourglass when endangered
class RelativeStreakIndicator extends ConsumerWidget {
  const RelativeStreakIndicator({
    super.key,
    required this.userId,
    required this.relativeId,
    this.compact = true,
  });

  final String userId;
  final String relativeId;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final streakAsync = ref.watch(
      relativeStreakStreamProvider((userId: userId, relativeId: relativeId)),
    );

    return streakAsync.when(
      data: (streak) {
        if (streak == null || streak.currentStreak == 0) {
          return const SizedBox.shrink();
        }
        return _buildStreakBadge(streak, themeColors);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildStreakBadge(RelativeStreak streak, ThemeColors themeColors) {
    final warningState = streak.warningState;
    final isEndangered = warningState == StreakWarningState.warning ||
        warningState == StreakWarningState.critical;
    final isCritical = warningState == StreakWarningState.critical;

    // Choose emoji and color based on state
    final emoji = isEndangered ? '⏳' : '🔥';
    final glowColor = isEndangered
        ? (isCritical ? AppColors.error : AppColors.joyfulOrange)
        : AppColors.joyfulOrange;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: themeColors.glassBackground.withValues(alpha: 0.9),
        border: Border.all(
          color: isEndangered
              ? glowColor.withValues(alpha: 0.5)
              : themeColors.glassBorder,
          width: 1,
        ),
        boxShadow: streak.currentStreak > 0
            ? [
                BoxShadow(
                  color: glowColor.withValues(alpha: isEndangered ? 0.4 : 0.3),
                  blurRadius: isEndangered ? 8 : 4,
                  spreadRadius: isEndangered ? 1 : 0,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emoji with animation
          _buildEmoji(emoji, streak.currentStreak, isEndangered, isCritical),
          SizedBox(width: compact ? 2 : 4),
          // Streak count
          Text(
            '${streak.currentStreak}',
            style: (compact ? AppTypography.labelSmall : AppTypography.labelMedium)
                .copyWith(
              color: themeColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Show time remaining if endangered
          if (isEndangered && !compact) ...[
            const SizedBox(width: 4),
            Text(
              streak.formattedTimeRemaining,
              style: AppTypography.labelSmall.copyWith(
                color: isCritical ? AppColors.error : AppColors.joyfulOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmoji(
    String emoji,
    int streak,
    bool isEndangered,
    bool isCritical,
  ) {
    Widget emojiWidget = Text(
      emoji,
      style: TextStyle(fontSize: compact ? 12 : 16),
    );

    // Add animations based on state
    if (isCritical) {
      // Critical: shake animation
      return emojiWidget
          .animate(onPlay: (controller) => controller.repeat())
          .shake(
            hz: 3,
            offset: const Offset(1, 0),
            duration: AppAnimations.modal,
          );
    } else if (isEndangered) {
      // Warning: pulse animation
      return emojiWidget
          .animate(onPlay: (controller) => controller.repeat())
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.15, 1.15),
            duration: AppAnimations.celebration,
            curve: Curves.easeInOut,
          )
          .then()
          .scale(
            begin: const Offset(1.15, 1.15),
            end: const Offset(1.0, 1.0),
            duration: AppAnimations.celebration,
            curve: Curves.easeInOut,
          );
    } else if (streak > 0) {
      // Healthy streak: subtle pulse
      return emojiWidget
          .animate(onPlay: (controller) => controller.repeat())
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.08, 1.08),
            duration: AppAnimations.celebration * 1.5,
            curve: Curves.easeInOut,
          )
          .then()
          .scale(
            begin: const Offset(1.08, 1.08),
            end: const Offset(1.0, 1.0),
            duration: AppAnimations.celebration * 1.5,
            curve: Curves.easeInOut,
          );
    }

    return emojiWidget;
  }
}

/// Larger version of the streak indicator for detail screens
class RelativeStreakCard extends ConsumerWidget {
  const RelativeStreakCard({
    super.key,
    required this.userId,
    required this.relativeId,
    required this.relativeName,
  });

  final String userId;
  final String relativeId;
  final String relativeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final streakAsync = ref.watch(
      relativeStreakStreamProvider((userId: userId, relativeId: relativeId)),
    );

    return streakAsync.when(
      data: (streak) => _buildCard(streak, themeColors),
      loading: () => _buildLoadingCard(themeColors),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildCard(RelativeStreak? streak, ThemeColors themeColors) {
    final currentStreak = streak?.currentStreak ?? 0;
    final longestStreak = streak?.longestStreak ?? 0;
    final warningState = streak?.warningState ?? StreakWarningState.safe;
    final isEndangered = warningState == StreakWarningState.warning ||
        warningState == StreakWarningState.critical;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isEndangered
              ? [
                  AppColors.joyfulOrange.withValues(alpha: 0.15),
                  AppColors.error.withValues(alpha: 0.1),
                ]
              : [
                  themeColors.glassHighlight,
                  themeColors.glassBackground,
                ],
        ),
        border: Border.all(
          color: isEndangered
              ? AppColors.joyfulOrange.withValues(alpha: 0.3)
              : themeColors.glassBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Text(
                isEndangered ? '⏳' : '🔥',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'شعلة التواصل مع $relativeName',
                      style: AppTypography.labelMedium.copyWith(
                        color: themeColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isEndangered && streak != null)
                      Text(
                        'متبقي: ${streak.formattedTimeRemaining}',
                        style: AppTypography.labelSmall.copyWith(
                          color: warningState == StreakWarningState.critical
                              ? AppColors.error
                              : AppColors.joyfulOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(
                'الشعلة الحالية',
                '$currentStreak يوم',
                themeColors,
              ),
              Container(
                width: 1,
                height: 32,
                color: themeColors.divider,
              ),
              _buildStat(
                'أطول شعلة',
                '$longestStreak يوم',
                themeColors,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, ThemeColors themeColors) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.headlineSmall.copyWith(
            color: themeColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: themeColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard(ThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: themeColors.glassBackground,
        border: Border.all(color: themeColors.glassBorder),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
