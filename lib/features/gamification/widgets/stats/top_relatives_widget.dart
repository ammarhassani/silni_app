import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Widget displaying top relatives by interaction count
class TopRelativesWidget extends ConsumerWidget {
  const TopRelativesWidget({
    super.key,
    required this.topRelatives,
  });

  final List<Map<String, dynamic>> topRelatives;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    if (topRelatives.isEmpty) {
      return GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Icon(
                Icons.people_rounded,
                color: themeColors.textOnGradient.withValues(alpha: 0.54),
                size: 48,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'لا توجد بيانات عن الأقارب',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: themeColors.textOnGradient.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الأقارب الأكثر تواصلاً',
              style: AppTypography.titleLarge.copyWith(
                color: themeColors.textOnGradient,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...topRelatives.take(5).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final relative = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            themeColors.primary,
                            themeColors.primaryLight,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: AppTypography.titleMedium.copyWith(
                            color: themeColors.textOnGradient,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            relative['name'] as String,
                            style: AppTypography.bodyMedium.copyWith(
                              color: themeColors.textOnGradient,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${relative['count']} تفاعل',
                            style: AppTypography.bodySmall.copyWith(
                              color: themeColors.textOnGradient.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
