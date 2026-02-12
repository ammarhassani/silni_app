import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/proactive_insight_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/home_providers.dart';

/// SharedPreferences key for storing the date of the last dismissal.
const _dismissedDateKey = 'proactive_insight_dismissed_date';

/// Locally-generated insight card shown to ALL users (no subscription needed).
///
/// Generates one insight per day by analyzing the user's relative and
/// interaction data using [ProactiveInsightService]. The user can dismiss
/// the card for the rest of the day by tapping the close button.
class ProactiveInsightCard extends ConsumerStatefulWidget {
  const ProactiveInsightCard({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  ConsumerState<ProactiveInsightCard> createState() =>
      _ProactiveInsightCardState();
}

class _ProactiveInsightCardState extends ConsumerState<ProactiveInsightCard> {
  bool _dismissed = false;
  bool _checkedDismissState = false;

  @override
  void initState() {
    super.initState();
    _checkDismissState();
  }

  Future<void> _checkDismissState() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedDate = prefs.getString(_dismissedDateKey);
    if (dismissedDate != null) {
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month}-${today.day}';
      if (dismissedDate == todayStr) {
        if (mounted) {
          setState(() {
            _dismissed = true;
          });
        }
      }
    }
    if (mounted) {
      setState(() {
        _checkedDismissState = true;
      });
    }
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    await prefs.setString(_dismissedDateKey, todayStr);
    if (mounted) {
      setState(() {
        _dismissed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't render until we've checked dismiss state
    if (!_checkedDismissState || _dismissed) {
      return const SizedBox.shrink();
    }

    final relativesAsync = ref.watch(viewerFilteredRelativesProvider);
    final recentInteractionsAsync =
        ref.watch(recentInteractionsStreamProvider(widget.userId));

    return relativesAsync.when(
      data: (relatives) => recentInteractionsAsync.when(
        data: (interactions) {
          final insight = ProactiveInsightService.generateInsight(
            relatives: relatives,
            interactions: interactions,
          );

          if (insight == null) return const SizedBox.shrink();

          return _buildCard(context, insight);
        },
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildCard(BuildContext context, ProactiveInsight insight) {
    final themeColors = ref.watch(themeColorsProvider);

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji
          Text(
            insight.emoji,
            style: AppTypography.headlineSmall,
          ),
          const SizedBox(width: AppSpacing.sm),

          // Insight text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نظرة سريعة',
                  style: AppTypography.labelMedium.copyWith(
                    color: themeColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  insight.message,
                  style: AppTypography.bodyMedium.copyWith(
                    color: themeColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Dismiss button
          GestureDetector(
            onTap: _dismiss,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Icon(
                LucideIcons.x,
                size: 16,
                color: themeColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppAnimations.normal)
        .slideY(begin: 0.1, end: 0);
  }
}
