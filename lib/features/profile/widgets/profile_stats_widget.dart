import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/app_themes.dart';
import '../../../shared/models/relative_model.dart';
import '../../../shared/models/interaction_model.dart';
import '../../../shared/widgets/glass_card.dart';

/// Widget displaying user statistics grid
class ProfileStatsWidget extends StatelessWidget {
  const ProfileStatsWidget({
    super.key,
    required this.relatives,
    required this.interactions,
    required this.themeColors,
  });

  final List<Relative> relatives;
  final List<Interaction> interactions;
  final ThemeColors themeColors;

  @override
  Widget build(BuildContext context) {
    final thisMonth = DateTime.now();
    final monthStart = DateTime(thisMonth.year, thisMonth.month, 1);
    final thisMonthInteractions = interactions
        .where((i) => i.date.isAfter(monthStart))
        .length;

    final needsContact = relatives.where((r) => r.needsContact).length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ProfileStatCard(
                icon: Icons.people_rounded,
                label: 'إجمالي الأقارب',
                value: '${relatives.length}',
                gradient: themeColors.primaryGradient,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ProfileStatCard(
                icon: Icons.call_rounded,
                label: 'تواصل هذا الشهر',
                value: '$thisMonthInteractions',
                gradient: themeColors.goldenGradient,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _ProfileStatCard(
                icon: Icons.timeline_rounded,
                label: 'إجمالي التفاعلات',
                value: '${interactions.length}',
                gradient: LinearGradient(
                  colors: [themeColors.accent, themeColors.primaryLight],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ProfileStatCard(
                icon: Icons.notifications_active_rounded,
                label: 'يحتاجون تواصل',
                value: '$needsContact',
                gradient: needsContact > 0
                    ? AppColors.streakFire
                    : themeColors.primaryGradient,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
  });

  final IconData icon;
  final String label;
  final String value;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      gradient: gradient,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.headlineLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }
}
