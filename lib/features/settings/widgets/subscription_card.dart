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
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/glass_dialog.dart';
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
///
/// [compact] true: render a slim status row when MAX (no breathing border,
/// no shimmer, no upgrade-CTA buttons). The free path always shows the full
/// card with its CTA — those users still need the upgrade affordance.
class SubscriptionCard extends ConsumerStatefulWidget {
  const SubscriptionCard({super.key, this.compact = false});

  final bool compact;

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

    // Phase 9.X.D.B hot-fix #12 (heat): the MAX breathing glow ran a 3s
    // reverse-repeat AnimationController forever on home + settings screens
    // for every MAX subscriber. Combined with the shimmer loop below, that's
    // two always-on animations per MAX user. Stopped — the glass card itself
    // signals MAX status; subtle motion isn't worth the GPU.
    if (_breathingController.isAnimating) {
      _breathingController.stop();
      _breathingController.reset();
    }

    if (isFreeUser) {
      return _buildFreeCard(themeColors);
    }

    if (widget.compact) {
      return _buildMaxStatusRow(
        themeColors: themeColors,
        isTrialActive: isTrialActive,
        trialDays: trialDays,
        expirationDate: expirationDate,
      );
    }

    return _buildMaxCard(
      themeColors: themeColors,
      currentTier: currentTier,
      isTrialActive: isTrialActive,
      trialDays: trialDays,
      expirationDate: expirationDate,
    );
  }

  // ── MAX / Slim status row (compact mode) ─────────────────────────

  Widget _buildMaxStatusRow({
    required dynamic themeColors,
    required bool isTrialActive,
    required int trialDays,
    required DateTime? expirationDate,
  }) {
    final subtitle = isTrialActive
        ? 'تجربة مجانية — متبقي $trialDays أيام'
        : (expirationDate != null
            ? 'يجدّد ${_formatDate(expirationDate)}'
            : 'مفعّل');

    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.premiumGoldDark, AppColors.premiumGold],
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.workspace_premium,
                color: Colors.black87,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'الاشتراك',
                      style: AppTypography.bodyMedium.copyWith(
                        color: themeColors.textOnGradient,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.goldenGradient.createShader(bounds),
                      child: Text(
                        'MAX',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: AppTypography.labelSmall.copyWith(
                    color: themeColors.textOnGradient.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _openSubscriptionManagement(context),
            child: Text(
              'إدارة',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.premiumGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
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
                  Expanded(
                    child: GlassActionButton(
                      text: 'إدارة',
                      icon: Icons.settings_outlined,
                      onPressed: () => _openSubscriptionManagement(context),
                    ),
                  ),
                  if (canUpgrade) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: GradientButton(
                        text: 'ترقية لـ MAX',
                        icon: Icons.arrow_upward_rounded,
                        onPressed: () => _openPaywall(context),
                        textColor: Colors.black87,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.premiumGoldLight,
                            AppColors.premiumGold,
                            AppColors.premiumGoldDark,
                          ],
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
        // Phase 9.X.D.B hot-fix #12: dropped infinite shimmer loop (heat).
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
          GradientButton(
            text: 'ترقية الآن',
            icon: Icons.star_rounded,
            onPressed: () => _openPaywall(context),
            textColor: Colors.black87,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.premiumGoldLight,
                AppColors.premiumGold,
                AppColors.premiumGoldDark,
              ],
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
