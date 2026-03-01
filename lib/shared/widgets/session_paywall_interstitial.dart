import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/providers/subscription_provider.dart';
import '../../features/subscription/screens/paywall_screen.dart';
import '../utils/trial_helpers.dart';

/// Session-based paywall interstitial shown every 3rd app open (or every 5th after 5 skips).
///
/// Displays a modal bottom sheet with MAX subscription highlights and a CTA
/// to open the full paywall screen.
class SessionPaywallInterstitial {
  SessionPaywallInterstitial._();

  static const _openCountKey = 'silni_app_open_count';
  static const _skipCountKey = 'silni_paywall_skip_count';

  /// Call on each app open. Shows the interstitial if the session threshold is met.
  static Future<void> maybeShow(BuildContext context, {String? userId}) async {
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();

    // Scope keys to user to prevent counter leakage across sessions
    final openCountKey = '${_openCountKey}_$userId';
    final skipCountKey = '${_skipCountKey}_$userId';

    final openCount = (prefs.getInt(openCountKey) ?? 0) + 1;
    await prefs.setInt(openCountKey, openCount);

    final skipCount = prefs.getInt(skipCountKey) ?? 0;

    // After 5 skips, reduce frequency to every 10th open
    final interval = skipCount >= 5 ? 10 : 7;

    if (openCount % interval != 0) return;

    if (!context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PaywallSheet(
        onSkip: () async {
          final updatedSkipCount = (prefs.getInt(skipCountKey) ?? 0) + 1;
          await prefs.setInt(skipCountKey, updatedSkipCount);
        },
      ),
    );
  }
}

class _PaywallSheet extends ConsumerWidget {
  final Future<void> Function() onSkip;

  const _PaywallSheet({required this.onSkip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTrialEligible = ref.watch(isTrialEligibleProvider);
    final introPrice = ref.watch(introPriceProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),

            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Gold star icon in circle
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.premiumGold, AppColors.premiumGoldDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.premiumGold.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.star_rounded,
                color: Colors.white,
                size: 32,
              ),
            ).animate().scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                ),

            const SizedBox(height: AppSpacing.md),

            // Headline in gold
            Text(
              isTrialEligible
                  ? 'جرّب صِلني MAX'
                  : 'عودتك تفرحنا! \u{1F90D}',
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.premiumGold,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),

            const SizedBox(height: AppSpacing.xs),

            // Subtitle
            Text(
              isTrialEligible
                  ? 'مجاناً بـ ٠ ريال لمدة ${TrialHelpers.formatDuration(introPrice)}'
                  : 'الميزات اللي جربتها تنتظرك',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white70,
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: AppSpacing.lg),

            // Feature bullets
            _FeatureRow(
              icon: LucideIcons.brain,
              text: 'ذكاء اصطناعي يحلل علاقاتك',
              delay: 250.ms,
            ),
            const SizedBox(height: AppSpacing.md),
            _FeatureRow(
              icon: LucideIcons.bell,
              text: 'تذكيرات بلا حدود لكل أقاربك',
              delay: 350.ms,
            ),
            const SizedBox(height: AppSpacing.md),
            _FeatureRow(
              icon: LucideIcons.barChart2,
              text: 'تحليلات وتقارير متقدمة',
              delay: 450.ms,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Gold gradient CTA button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.premiumGold, AppColors.premiumGoldDark],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.premiumGold.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PaywallScreen(),
                        ),
                      );
                    },
                    child: Center(
                      child: Text(
                        isTrialEligible ? 'ابدأ التجربة المجانية' : 'عرض الخطط',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),

            const SizedBox(height: AppSpacing.sm),

            // Skip button
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onSkip();
                Navigator.of(context).pop();
              },
              child: Text(
                'تخطي',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white38,
                ),
              ),
            ),

            SizedBox(height: bottomPadding > 0 ? bottomPadding : AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Duration delay;

  const _FeatureRow({
    required this.icon,
    required this.text,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.premiumGold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            icon,
            color: AppColors.premiumGold,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyLarge.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: delay).slideX(begin: 0.1);
  }
}
