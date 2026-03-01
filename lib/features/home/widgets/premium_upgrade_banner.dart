import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../subscription/screens/paywall_screen.dart';

/// Persistent gold-gradient banner shown to free users on the home screen.
///
/// Displays a static teaser message. Tapping navigates to the PaywallScreen.
class PremiumUpgradeBanner extends ConsumerWidget {
  const PremiumUpgradeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMax = ref.watch(isMaxProvider);
    final isTrialEligible = ref.watch(isTrialEligibleProvider);

    if (isMax) {
      return const SizedBox.shrink();
    }

    final teaserMessage = isTrialEligible
        ? 'استمتع بجميع المزايا — جرّب صلني MAX مجاناً'
        : 'الميزات اللي جربتها تنتظرك — ارجع لصلني MAX';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const PaywallScreen(),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.premiumGold.withValues(alpha: 0.2),
              AppColors.premiumGoldDark.withValues(alpha: 0.15),
            ],
          ),
          border: Border.all(
            color: AppColors.premiumGold.withValues(alpha: 0.4),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Gold star icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.premiumGold,
                    AppColors.premiumGoldDark,
                  ],
                ),
              ),
              child: const Icon(
                Icons.star_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Text column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'صِلني MAX',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.premiumGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    teaserMessage,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Arrow icon
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.premiumGold,
              size: 16,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(
          begin: 0.1,
          end: 0,
          duration: 600.ms,
          curve: Curves.easeOut,
        );
  }
}
