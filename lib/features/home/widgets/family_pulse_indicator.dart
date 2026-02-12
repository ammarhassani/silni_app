import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/contact_priority_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../providers/home_providers.dart';

/// Compact circular indicator showing overall family relationship health.
///
/// Color coding:
/// - Green (>= 0.7): healthy
/// - Amber (>= 0.4): needs attention
/// - Red (< 0.4): at risk
class FamilyPulseIndicator extends ConsumerWidget {
  const FamilyPulseIndicator({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final relativesAsync = ref.watch(viewerFilteredRelativesProvider);

    return relativesAsync.when(
      data: (relatives) {
        if (relatives.isEmpty) return const SizedBox.shrink();

        final pulse = ContactPriorityService.getFamilyPulse(relatives);
        return _buildIndicator(pulse, themeColors);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildIndicator(double pulse, dynamic themeColors) {
    final percentage = (pulse * 100).round();
    final color = _pulseColor(pulse, themeColors);

    return Semantics(
      label: 'نبض العائلة: $percentage بالمئة',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: pulse,
                  strokeWidth: 4,
                  backgroundColor: color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Text(
                  '$percentage%',
                  style: AppTypography.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'نبض العائلة',
            style: AppTypography.labelMedium.copyWith(
              color: themeColors.textSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Color _pulseColor(double pulse, dynamic themeColors) {
    if (pulse >= 0.7) return themeColors.statusSuccess;
    if (pulse >= 0.4) return themeColors.statusWarning;
    return themeColors.statusError;
  }
}
