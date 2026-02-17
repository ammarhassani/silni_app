import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/subscription_tier.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../subscription/screens/paywall_screen.dart';

/// Compact premium subscription card.
///
/// For MAX subscribers: horizontal layout with glowing badge,
/// gradient "MAX" text, breathing glow border, and shimmer sweep.
/// For free users: static card with grey badge and upgrade CTA.
class SubscriptionCard extends ConsumerStatefulWidget {
  const SubscriptionCard({super.key});

  @override
  ConsumerState<SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends ConsumerState<SubscriptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _glowBlur;
  late Animation<double> _glowOpacity;
  late Animation<double> _borderOpacity;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    final curve = CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    );

    _glowBlur = Tween<double>(begin: 16.0, end: 24.0).animate(curve);
    _glowOpacity = Tween<double>(begin: 0.4, end: 0.6).animate(curve);
    _borderOpacity = Tween<double>(begin: 0.3, end: 0.5).animate(curve);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTier = ref.watch(subscriptionTierProvider);
    final isTrialActive = ref.watch(isTrialActiveProvider);
    final trialDays = ref.watch(trialDaysRemainingProvider);
    final expirationDate = ref.watch(subscriptionExpirationProvider);
    final themeColors = ref.watch(themeColorsProvider);
    final isFreeUser = currentTier == SubscriptionTier.free;

    // Start/stop breathing animation based on tier
    if (currentTier.isMax && !_breathingController.isAnimating) {
      _breathingController.repeat(reverse: true);
    } else if (!currentTier.isMax && _breathingController.isAnimating) {
      _breathingController.stop();
      _breathingController.reset();
    }

    if (isFreeUser) {
      return _buildFreeCard(themeColors);
    }

    return _buildMaxCard(
      themeColors: themeColors,
      currentTier: currentTier,
      isTrialActive: isTrialActive,
      trialDays: trialDays,
      expirationDate: expirationDate,
    );
  }

  // ── MAX / Paid Card ──────────────────────────────────────────────

  Widget _buildMaxCard({
    required dynamic themeColors,
    required SubscriptionTier currentTier,
    required bool isTrialActive,
    required int trialDays,
    required DateTime? expirationDate,
  }) {
    final canUpgrade =
        currentTier.canUpgrade && currentTier != SubscriptionTier.free;

    return AnimatedBuilder(
      animation: _breathingController,
      builder: (context, _) {
        return GlassCard(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppColors.premiumGold.withValues(alpha: 0.15),
              AppColors.premiumGoldDark.withValues(alpha: 0.08),
            ],
          ),
          border: Border.all(
            color:
                AppColors.premiumGold.withValues(alpha: _borderOpacity.value),
            width: 1.5,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Crown badge (compact)
                  _buildCrownBadge(),
                  const SizedBox(width: AppSpacing.md),

                  // Title + MAX badge + description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'الاشتراك',
                              style: AppTypography.titleMedium.copyWith(
                                color: themeColors.textOnGradient,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            // Gradient "MAX" badge
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppColors.goldenGradient
                                      .createShader(bounds),
                              child: Text(
                                'MAX',
                                style: AppTypography.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isTrialActive
                              ? 'تجربة مجانية - متبقي $trialDays أيام'
                              : currentTier.arabicDescription,
                          style: AppTypography.bodySmall.copyWith(
                            color: themeColors.textOnGradient
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        if (expirationDate != null) ...[
                          const SizedBox(height: 1),
                          Text(
                            'ينتهي في: ${_formatDate(expirationDate)}',
                            style: AppTypography.labelSmall.copyWith(
                              color: themeColors.textOnGradient
                                  .withValues(alpha: 0.54),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Action row
              Row(
                children: [
                  // Manage button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _openSubscriptionManagement(context),
                      icon: const Icon(Icons.settings_outlined, size: 16),
                      label: const Text('إدارة'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: themeColors.textOnGradient,
                        side: BorderSide(
                          color: AppColors.premiumGold
                              .withValues(alpha: 0.5),
                        ),
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  if (canUpgrade) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openPaywall(context),
                        icon: const Icon(Icons.arrow_upward_rounded,
                            size: 16),
                        label: const Text('ترقية لـ MAX'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.premiumGold,
                          foregroundColor: Colors.black87,
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Restore purchases
              Center(
                child: TextButton(
                  onPressed: () => _restorePurchases(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'استعادة المشتريات',
                    style: AppTypography.labelSmall.copyWith(
                      color: themeColors.textOnGradient
                          .withValues(alpha: 0.54),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          delay: 2.seconds,
          duration: 1500.ms,
          color: AppColors.premiumGold.withValues(alpha: 0.15),
        )
        .animate()
        .fadeIn(duration: AppAnimations.normal)
        .slideY(
          begin: 0.1,
          end: 0,
          duration: AppAnimations.normal,
          curve: AppAnimations.enterCurve,
        );
  }

  Widget _buildCrownBadge() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.premiumGoldDark, AppColors.premiumGold],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.premiumGold
                .withValues(alpha: _glowOpacity.value),
            blurRadius: _glowBlur.value,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.workspace_premium,
          color: Colors.black87,
          size: 24,
        ),
      ),
    );
  }

  // ── Free Card ────────────────────────────────────────────────────

  Widget _buildFreeCard(dynamic themeColors) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Grey badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.grey, Colors.grey.shade700],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.person, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'الاشتراك',
                          style: AppTypography.titleMedium.copyWith(
                            color: themeColors.textOnGradient,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Free',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ترقية للحصول على ميزات أكثر',
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            themeColors.textOnGradient.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Gold upgrade button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _openPaywall(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.premiumGold,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'ترقية الآن',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppAnimations.normal);
  }

  // ── Actions ──────────────────────────────────────────────────────

  void _openPaywall(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PaywallScreen(),
      ),
    );
  }

  Future<void> _openSubscriptionManagement(BuildContext context) async {
    HapticFeedback.lightImpact();
    final themeColors = ref.read(themeColorsProvider);

    if (Platform.isIOS || Platform.isMacOS) {
      final uri = Uri.parse('https://apps.apple.com/account/subscriptions');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          UIHelpers.showSnackBar(
            context,
            'افتح الإعدادات > Apple ID > الاشتراكات',
            backgroundColor: themeColors.statusInfo,
          );
        }
      }
    } else if (Platform.isAndroid) {
      final uri =
          Uri.parse('https://play.google.com/store/account/subscriptions');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          UIHelpers.showSnackBar(
            context,
            'افتح متجر Google Play > الاشتراكات',
            backgroundColor: themeColors.statusInfo,
          );
        }
      }
    }
  }

  Future<void> _restorePurchases(BuildContext context) async {
    HapticFeedback.lightImpact();
    final themeColors = ref.read(themeColorsProvider);

    UIHelpers.showSnackBar(
      context,
      'جاري استعادة المشتريات...',
      backgroundColor: themeColors.statusInfo,
    );

    try {
      final restored =
          await SubscriptionService.instance.restorePurchases();
      ref.invalidate(subscriptionStateProvider);

      if (context.mounted) {
        UIHelpers.showSnackBar(
          context,
          restored
              ? 'تم استعادة الاشتراك بنجاح!'
              : 'لم يتم العثور على مشتريات سابقة',
          isError: !restored,
          backgroundColor:
              restored ? themeColors.statusSuccess : themeColors.statusWarning,
        );
      }
    } catch (e) {
      if (context.mounted) {
        UIHelpers.showSnackBar(
          context,
          'حدث خطأ أثناء استعادة المشتريات',
          isError: true,
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
