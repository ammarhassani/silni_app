import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/models/relative_model.dart';

/// Stats card showing last contact, interactions count, and status
class RelativeStatsCard extends ConsumerWidget {
  const RelativeStatsCard({
    super.key,
    required this.relative,
  });

  final Relative relative;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final daysSince = relative.daysSinceLastContact;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Flexible(
            child: _StatItem(
              icon: Icons.calendar_today,
              label: 'آخر تواصل',
              value: daysSince == null
                  ? 'لم يتم'
                  : daysSince == 0
                      ? 'اليوم'
                      : 'منذ $daysSince يوم',
              color: relative.needsContact ? Colors.red : themeColors.primary,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          Flexible(
            child: _StatItem(
              icon: Icons.timeline,
              label: 'التفاعلات',
              value: '${relative.interactionCount}',
              color: AppColors.premiumGold,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          Flexible(
            child: _StatItem(
              icon: Icons.access_time,
              label: 'الحالة',
              value: relative.needsContact ? 'يحتاج تواصل' : 'تم التواصل',
              color: relative.needsContact ? Colors.orange : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: Colors.white70),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
