import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/relative_model.dart';

/// Health status badge showing relationship health using theme gradients
/// Displays gradient indicator: healthy, needs attention, at risk
class HealthBadge extends ConsumerWidget {
  final Relative relative;
  final double size;
  final bool showLabel;
  final bool showScore;

  const HealthBadge({
    super.key,
    required this.relative,
    this.size = 12,
    this.showLabel = false,
    this.showScore = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final status = relative.healthStatus2;
    final score = relative.healthScore ?? 50;

    final gradient = _getGradient(status, themeColors);
    final label = _getLabel(status);
    final icon = _getIcon(status);

    if (showLabel || showScore) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: themeColors.onPrimary,
              size: 14,
            ),
            if (showLabel) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: themeColors.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (showScore) ...[
              const SizedBox(width: 4),
              Text(
                '${score.toInt()}%',
                style: AppTypography.labelSmall.copyWith(
                  color: themeColors.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Simple dot badge with gradient
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        border: Border.all(
          color: themeColors.glassBorder,
          width: 1.5,
        ),
      ),
    );
  }

  LinearGradient _getGradient(RelationshipHealthStatus status, ThemeColors themeColors) {
    switch (status) {
      case RelationshipHealthStatus.healthy:
        return themeColors.healthyGradient;
      case RelationshipHealthStatus.needsAttention:
        return themeColors.warningGradient;
      case RelationshipHealthStatus.atRisk:
        return themeColors.dangerGradient;
      case RelationshipHealthStatus.unknown:
        // Use glass background style for unknown
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeColors.glassBackground,
            themeColors.glassBackground,
          ],
        );
    }
  }

  IconData _getIcon(RelationshipHealthStatus status) {
    switch (status) {
      case RelationshipHealthStatus.healthy:
        return LucideIcons.heart;
      case RelationshipHealthStatus.needsAttention:
        return LucideIcons.alertCircle;
      case RelationshipHealthStatus.atRisk:
        return LucideIcons.alertTriangle;
      case RelationshipHealthStatus.unknown:
        return LucideIcons.helpCircle;
    }
  }

  String _getLabel(RelationshipHealthStatus status) {
    switch (status) {
      case RelationshipHealthStatus.healthy:
        return 'جيدة';
      case RelationshipHealthStatus.needsAttention:
        return 'تحتاج اهتمام';
      case RelationshipHealthStatus.atRisk:
        return 'معرضة للخطر';
      case RelationshipHealthStatus.unknown:
        return 'غير معروف';
    }
  }
}

/// Health detail card showing breakdown of health metrics
class HealthDetailCard extends ConsumerWidget {
  final Relative relative;
  final VoidCallback? onImprove;

  const HealthDetailCard({
    super.key,
    required this.relative,
    this.onImprove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final score = relative.healthScore ?? 50;
    final status = relative.healthStatus2;
    final gradient = _getGradient(status, themeColors);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: themeColors.glassBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: themeColors.glassBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with score
          Row(
            children: [
              Icon(
                Icons.favorite_rounded,
                color: themeColors.textPrimary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'صحة العلاقة',
                style: AppTypography.titleMedium.copyWith(
                  color: themeColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '${score.toInt()}%',
                  style: AppTypography.titleMedium.copyWith(
                    color: themeColors.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: themeColors.glassBackground,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerRight,
                widthFactor: score / 100,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Metrics breakdown
          _buildMetricRow(
            'التواصل',
            Icons.phone_rounded,
            _getContactScore(),
            themeColors,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildMetricRow(
            'القرب العاطفي',
            Icons.favorite_border_rounded,
            (relative.emotionalCloseness ?? 3) / 5 * 100,
            themeColors,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildMetricRow(
            'جودة التواصل',
            Icons.chat_bubble_outline_rounded,
            (relative.communicationQuality ?? 3) / 5 * 100,
            themeColors,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildMetricRow(
            'الدعم',
            Icons.handshake_rounded,
            (relative.supportLevel ?? 3) / 5 * 100,
            themeColors,
          ),

          if (onImprove != null && status != RelationshipHealthStatus.healthy) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: themeColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: TextButton.icon(
                  onPressed: onImprove,
                  icon: Icon(Icons.auto_fix_high_rounded, size: 18, color: themeColors.onPrimary),
                  label: Text(
                    'نصائح لتحسين العلاقة',
                    style: TextStyle(color: themeColors.onPrimary),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, IconData icon, double percentage, ThemeColors themeColors) {
    final gradient = _getPercentageGradient(percentage, themeColors);

    return Row(
      children: [
        Icon(icon, color: themeColors.textSecondary, size: 16),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: themeColors.textSecondary),
          ),
        ),
        SizedBox(
          width: 80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: themeColors.glassBackground,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerRight,
                widthFactor: percentage / 100,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        SizedBox(
          width: 35,
          child: Text(
            '${percentage.toInt()}%',
            style: AppTypography.labelSmall.copyWith(
              color: themeColors.textSecondary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  double _getContactScore() {
    final daysSinceContact = relative.daysSinceLastContact;
    if (daysSinceContact == null) return 50;

    // Score based on priority thresholds
    final threshold = switch (relative.priority) {
      1 => 7, // High priority: contact every 7 days
      2 => 14, // Medium: every 14 days
      _ => 30, // Low: every 30 days
    };

    if (daysSinceContact <= threshold ~/ 2) return 100;
    if (daysSinceContact <= threshold) return 70;
    if (daysSinceContact <= threshold * 2) return 40;
    return 20;
  }

  LinearGradient _getPercentageGradient(double percentage, ThemeColors themeColors) {
    if (percentage >= 70) return themeColors.healthyGradient;
    if (percentage >= 40) return themeColors.warningGradient;
    return themeColors.dangerGradient;
  }

  LinearGradient _getGradient(RelationshipHealthStatus status, ThemeColors themeColors) {
    switch (status) {
      case RelationshipHealthStatus.healthy:
        return themeColors.healthyGradient;
      case RelationshipHealthStatus.needsAttention:
        return themeColors.warningGradient;
      case RelationshipHealthStatus.atRisk:
        return themeColors.dangerGradient;
      case RelationshipHealthStatus.unknown:
        return LinearGradient(
          colors: [themeColors.glassBackground, themeColors.glassBackground],
        );
    }
  }
}
