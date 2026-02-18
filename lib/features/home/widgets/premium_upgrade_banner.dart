import 'dart:async';

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
/// Auto-rotates through teaser messages every 5 seconds.
/// Tapping navigates to the PaywallScreen.
class PremiumUpgradeBanner extends ConsumerStatefulWidget {
  const PremiumUpgradeBanner({super.key});

  @override
  ConsumerState<PremiumUpgradeBanner> createState() =>
      _PremiumUpgradeBannerState();
}

class _PremiumUpgradeBannerState extends ConsumerState<PremiumUpgradeBanner> {
  static const _teaserMessages = [
    'ذكاء اصطناعي يحلل علاقاتك ويقترح متى تتواصل',
    'تذكيرات ذكية بلا حدود لكل أفراد عائلتك',
    'تحليلات متقدمة لتواصلك مع عائلتك',
    'تقارير أسبوعية وتنافس عائلي في صلة الرحم',
  ];

  int _currentIndex = 0;
  Timer? _rotationTimer;

  @override
  void initState() {
    super.initState();
    _rotationTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (mounted) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % _teaserMessages.length;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _rotationTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMax = ref.watch(isMaxProvider);

    if (isMax) {
      return const SizedBox.shrink();
    }

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
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      _teaserMessages[_currentIndex],
                      key: ValueKey<int>(_currentIndex),
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
