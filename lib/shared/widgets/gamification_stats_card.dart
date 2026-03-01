import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/theme/app_themes.dart';
import '../../core/config/supabase_config.dart';
import '../../core/models/gamification_event.dart';
import '../../core/utils/badge_prestige.dart';
import '../../core/providers/gamification_events_provider.dart';
import 'glass_card.dart';

/// Widget to display user's gamification stats (points, level, streak, badges)
class GamificationStatsCard extends ConsumerStatefulWidget {
  final String userId;
  final bool compact;

  const GamificationStatsCard({
    super.key,
    required this.userId,
    this.compact = false,
  });

  @override
  ConsumerState<GamificationStatsCard> createState() => _GamificationStatsCardState();
}

class _GamificationStatsCardState extends ConsumerState<GamificationStatsCard> {
  int _refreshKey = 0;

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);

    // Listen to gamification events to trigger refresh
    ref.listen<AsyncValue<GamificationEvent>>(
      gamificationEventsStreamProvider,
      (previous, next) {
        next.whenData((event) {
          // Only refresh for this user's events
          if (event.userId == widget.userId) {
            // Trigger rebuild by updating key
            if (mounted) {
              setState(() {
                _refreshKey++;
              });
            }
          }
        });
      },
    );

    return StreamBuilder<Map<String, dynamic>>(
      key: ValueKey(_refreshKey), // Force rebuild when key changes
      stream: SupabaseConfig.client
          .from('users')
          .stream(primaryKey: ['id'])
          .eq('id', widget.userId)
          .map((data) => data.isNotEmpty ? data.first : {}),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final userData = snapshot.data!;
        final int points = userData['points'] ?? 0;
        final int level = userData['level'] ?? 1;
        final int currentStreak = userData['current_streak'] ?? 0;
        final int longestStreak = userData['longest_streak'] ?? 0;
        final List<String> badges = List<String>.from(userData['badges'] ?? []);

        if (widget.compact) {
          return _buildCompactView(themeColors, points, level, currentStreak, badges);
        }

        return _buildFullView(themeColors, points, level, currentStreak, longestStreak, badges);
      },
    );
  }

  Widget _buildCompactView(
    ThemeColors themeColors,
    int points,
    int level,
    int currentStreak,
    List<String> badges,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: '🔥',
            label: 'التواصل',
            value: '$currentStreak',
            color: AppColors.streakFire.colors.first,
          ),
          _buildStatItem(
            icon: '🎖️',
            label: 'الأوسمة',
            value: '${badges.length}',
            color: themeColors.primaryLight,
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildFullView(
    ThemeColors themeColors,
    int points,
    int level,
    int currentStreak,
    int longestStreak,
    List<String> badges,
  ) {
    return Column(
      children: [
        // Streaks
        Row(
          children: [
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                gradient: AppColors.streakFire,
                child: Column(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$currentStreak',
                      style: AppTypography.headlineLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'يوم تواصل',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideX(begin: -0.1, end: 0),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    const Text('🏅', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$longestStreak',
                      style: AppTypography.headlineLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'أطول سلسلة',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideX(begin: 0.1, end: 0),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Badges
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🎖️', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'الأوسمة (${badges.length})',
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (badges.isEmpty)
                Text(
                  'لم تحصل على أي أوسمة بعد. استمر في التواصل مع أقاربك!',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                )
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: badges.map((badge) => _buildBadgeChip(badge, themeColors)).toList(),
                ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.1, end: 0),
      ],
    );
  }

  Widget _buildStatItem({
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeChip(String badge, ThemeColors themeColors) {
    final badgeInfo = _getBadgeInfo(badge);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: themeColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(badgeInfo['emoji'] ?? '🏆', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: AppSpacing.xs),
          Text(
            badgeInfo['name'] ?? badge,
            style: AppTypography.labelMedium.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _getBadgeInfo(String badge) {
    // Use centralized BadgePrestige for consistent badge info across app
    final info = BadgePrestige.getBadgeInfo(badge);
    return {'emoji': info.emoji, 'name': info.name};
  }
}
