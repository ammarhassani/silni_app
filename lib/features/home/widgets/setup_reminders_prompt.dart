import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/glass_card.dart';

/// Prompt for new users to set up reminders
class SetupRemindersPrompt extends ConsumerWidget {
  const SetupRemindersPrompt({
    super.key,
    required this.hasReminders,
  });

  final bool hasReminders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If user has reminders, don't show anything
    if (hasReminders) {
      return const SizedBox.shrink();
    }

    final themeColors = ref.watch(themeColorsProvider);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.reminders),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        gradient: LinearGradient(
          colors: [
            themeColors.primary.withValues(alpha: 0.3),
            AppColors.premiumGold.withValues(alpha: 0.2),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.premiumGold.withValues(alpha: 0.3),
              ),
              child: const Center(
                child: Text('🔔', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'اضبط تذكيراتك لتبدأ رحلة الصلة',
                style: AppTypography.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.7),
              size: 16,
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }
}
