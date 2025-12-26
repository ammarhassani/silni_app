import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/streak_freeze_model.dart';
import '../../core/providers/streak_freeze_provider.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/theme_provider.dart';

/// Compact widget to display freeze inventory in header/bar
class FreezeInventoryBadge extends ConsumerWidget {
  const FreezeInventoryBadge({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final inventoryAsync = ref.watch(freezeInventoryStreamProvider(userId));

    return inventoryAsync.when(
      data: (inventory) {
        if (inventory.freezeCount == 0) {
          return const SizedBox.shrink();
        }
        return _buildBadge(inventory, themeColors);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildBadge(FreezeInventory inventory, ThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: themeColors.glassBackground.withValues(alpha: 0.9),
        border: Border.all(
          color: AppColors.calmBlue.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.calmBlue.withValues(alpha: 0.2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('❄️', style: TextStyle(fontSize: 14))
              .animate(onPlay: (c) => c.repeat())
              .shimmer(
                duration: 2.seconds,
                color: AppColors.calmBlue.withValues(alpha: 0.3),
              ),
          const SizedBox(width: 4),
          Text(
            '${inventory.freezeCount}',
            style: AppTypography.labelSmall.copyWith(
              color: themeColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full freeze inventory card for settings/profile screens
class FreezeInventoryCard extends ConsumerWidget {
  const FreezeInventoryCard({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);
    final inventoryAsync = ref.watch(freezeInventoryStreamProvider(userId));

    return inventoryAsync.when(
      data: (inventory) => _buildCard(inventory, themeColors),
      loading: () => _buildLoadingCard(themeColors),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildCard(FreezeInventory inventory, ThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.calmBlue.withValues(alpha: 0.1),
            themeColors.glassBackground,
          ],
        ),
        border: Border.all(color: themeColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.calmBlue.withValues(alpha: 0.15),
                ),
                child: const Text('❄️', style: TextStyle(fontSize: 24))
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(
                      duration: 3.seconds,
                      color: AppColors.calmBlue.withValues(alpha: 0.4),
                    ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'حماية الشعلة',
                      style: AppTypography.titleMedium.copyWith(
                        color: themeColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'تحمي شعلتك عند نسيان التفاعل',
                      style: AppTypography.labelSmall.copyWith(
                        color: themeColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(
                'متاحة',
                '${inventory.freezeCount}',
                themeColors,
                AppColors.calmBlue,
              ),
              Container(
                width: 1,
                height: 32,
                color: themeColors.divider,
              ),
              _buildStat(
                'مستخدمة',
                '${inventory.freezesUsedTotal}',
                themeColors,
                themeColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Info text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: themeColors.surfaceVariant.withValues(alpha: 0.5),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: themeColors.textHint,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'احصل على حماية شعلة عند 7، 30، و100 يوم',
                    style: AppTypography.labelSmall.copyWith(
                      color: themeColors.textHint,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppAnimations.fast)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildStat(
    String label,
    String value,
    ThemeColors themeColors,
    Color valueColor,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.headlineMedium.copyWith(
            color: valueColor,
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
