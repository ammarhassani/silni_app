import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/relative_model.dart';

/// Health status badge showing relationship health
/// Displays colored indicator: 🟢 healthy, 🟡 needs attention, 🔴 at risk
class HealthBadge extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final status = relative.healthStatus2;
    final score = relative.healthScore ?? 50;

    final color = _getColor(status);
    final label = _getLabel(status);

    if (showLabel || showScore) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            if (showLabel) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (showScore) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${score.toInt()}%',
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Simple dot badge
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: AppColors.islamicGreenDark,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Color _getColor(RelationshipHealthStatus status) {
    switch (status) {
      case RelationshipHealthStatus.healthy:
        return const Color(0xFF4CAF50); // Green
      case RelationshipHealthStatus.needsAttention:
        return const Color(0xFFFFC107); // Amber
      case RelationshipHealthStatus.atRisk:
        return const Color(0xFFE53935); // Red
      case RelationshipHealthStatus.unknown:
        return const Color(0xFF9E9E9E); // Grey
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
class HealthDetailCard extends StatelessWidget {
  final Relative relative;
  final VoidCallback? onImprove;

  const HealthDetailCard({
    super.key,
    required this.relative,
    this.onImprove,
  });

  @override
  Widget build(BuildContext context) {
    final score = relative.healthScore ?? 50;
    final status = relative.healthStatus2;
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
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
                color: color,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'صحة العلاقة',
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
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
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '${score.toInt()}%',
                  style: AppTypography.titleMedium.copyWith(
                    color: color,
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
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Metrics breakdown
          _buildMetricRow(
            'التواصل',
            Icons.phone_rounded,
            _getContactScore(),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildMetricRow(
            'القرب العاطفي',
            Icons.favorite_border_rounded,
            (relative.emotionalCloseness ?? 3) / 5 * 100,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildMetricRow(
            'جودة التواصل',
            Icons.chat_bubble_outline_rounded,
            (relative.communicationQuality ?? 3) / 5 * 100,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildMetricRow(
            'الدعم',
            Icons.handshake_rounded,
            (relative.supportLevel ?? 3) / 5 * 100,
          ),

          if (onImprove != null && status != RelationshipHealthStatus.healthy) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onImprove,
                icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                label: const Text('نصائح لتحسين العلاقة'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.islamicGreenLight,
                  backgroundColor: AppColors.islamicGreenPrimary.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, IconData icon, double percentage) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: Colors.white70),
          ),
        ),
        SizedBox(
          width: 80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                _getPercentageColor(percentage),
              ),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        SizedBox(
          width: 35,
          child: Text(
            '${percentage.toInt()}%',
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white54,
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

  Color _getPercentageColor(double percentage) {
    if (percentage >= 70) return const Color(0xFF4CAF50);
    if (percentage >= 40) return const Color(0xFFFFC107);
    return const Color(0xFFE53935);
  }

  Color _getStatusColor(RelationshipHealthStatus status) {
    switch (status) {
      case RelationshipHealthStatus.healthy:
        return const Color(0xFF4CAF50);
      case RelationshipHealthStatus.needsAttention:
        return const Color(0xFFFFC107);
      case RelationshipHealthStatus.atRisk:
        return const Color(0xFFE53935);
      case RelationshipHealthStatus.unknown:
        return const Color(0xFF9E9E9E);
    }
  }
}
