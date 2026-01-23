import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/subscription_tier.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../premium_onboarding/providers/onboarding_provider.dart';
import '../../premium_onboarding/screens/premium_onboarding_screen.dart';
import '../widgets/subscription_congrats_dialog.dart';

/// Price info from RevenueCat
class _PriceInfo {
  final double price;
  final String priceString;
  final String currencyCode;

  _PriceInfo({
    required this.price,
    required this.priceString,
    required this.currencyCode,
  });
}

/// Paywall screen for subscription purchase
/// Follows glassmorphism design pattern
class PaywallScreen extends ConsumerStatefulWidget {
  /// Feature that triggered the paywall (for analytics)
  final String? featureToUnlock;

  const PaywallScreen({
    super.key,
    this.featureToUnlock,
  });

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isAnnual = true;
  bool _isPurchasing = false;

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);
    final offerings = ref.watch(offeringsProvider);
    final isLoading = ref.watch(subscriptionLoadingProvider);

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(animated: true, child: SizedBox.expand()),
          SafeArea(
            child: Column(
              children: [
                // Header with close button
                _buildHeader(themeColors),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    child: Column(
                      children: [
                        // Trial banner
                        _buildTrialBanner(themeColors),

                        const SizedBox(height: AppSpacing.sm),

                        // Billing toggle (moved up for better sales funnel)
                        _buildBillingToggle(themeColors, offerings),

                        const SizedBox(height: AppSpacing.sm),

                        // Pricing cards (moved up - see pricing before features)
                        _buildPricingCards(themeColors, offerings),

                        const SizedBox(height: AppSpacing.md),

                        // Feature comparison (moved after pricing)
                        _buildFeatureComparison(themeColors),

                        const SizedBox(height: AppSpacing.md),

                        // Restore purchases
                        _buildRestoreButton(themeColors),

                        const SizedBox(height: AppSpacing.xs),

                        // Legal links (required by App Store)
                        _buildLegalLinks(),

                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                ),

                // Purchase button
                _buildPurchaseButton(themeColors, offerings, isLoading),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(dynamic themeColors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: themeColors.textOnGradient),
          ),
          const Spacer(),
          Text(
            'الاشتراك المميز',
            style: AppTypography.headlineMedium.copyWith(
              color: themeColors.textOnGradient,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balance close button
        ],
      ),
    );
  }

  Widget _buildTrialBanner(dynamic themeColors) {
    return GlassCard(
      gradient: LinearGradient(
        colors: [
          AppColors.premiumGold.withValues(alpha: 0.3),
          AppColors.premiumGoldDark.withValues(alpha: 0.2),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.premiumGold,
            ),
            child: const Icon(Icons.star_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'جرب مجاناً لمدة 7 أيام',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'استكشف جميع الميزات بدون التزام',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildFeatureComparison(dynamic themeColors) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مقارنة الخطط',
            style: AppTypography.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Header row
          _buildFeatureHeaderRow(),
          const Divider(color: Colors.white24, height: 24),
          // Feature rows - Free vs MAX
          _buildFeatureRow('إدارة الأقارب', true, true),
          _buildFeatureRow('شجرة العائلة', true, true),
          _buildFeatureRow('المظاهر المخصصة', true, true),
          _buildFeatureRow('التذكيرات', '3', '∞'),
          _buildFeatureRow('مساعد AI', false, true),
          _buildFeatureRow('كتابة الرسائل', false, true),
          _buildFeatureRow('تحليل العلاقات', false, true),
          _buildFeatureRow('إحصائيات متقدمة', false, true),
          _buildFeatureRow('لوحة المتصدرين', false, true),
          _buildFeatureRow('تصدير البيانات', false, true),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildFeatureHeaderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Expanded(flex: 3, child: SizedBox()),
          Expanded(
            child: Text(
              'مجاني',
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              'MAX',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.premiumGold,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String feature, dynamic free, dynamic max) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              feature,
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
          ),
          Expanded(child: _buildFeatureCell(free)),
          Expanded(child: _buildFeatureCell(max)),
        ],
      ),
    );
  }

  Widget _buildFeatureCell(dynamic value) {
    if (value is bool) {
      return Icon(
        value ? Icons.check_circle : Icons.remove_circle_outline,
        color: value ? Colors.green : Colors.grey,
        size: 20,
      );
    }
    return Text(
      value.toString(),
      style: AppTypography.bodySmall.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Calculate savings percentage from offerings
  int? _calculateSavingsPercent(rc.Offerings? offerings) {
    final maxMonthly = _getPriceFromOfferings(offerings, SubscriptionProducts.maxMonthly);
    final maxAnnual = _getPriceFromOfferings(offerings, SubscriptionProducts.maxAnnual);

    if (maxAnnual != null && maxMonthly != null && maxMonthly.price > 0) {
      final yearlyIfMonthly = maxMonthly.price * 12;
      return ((yearlyIfMonthly - maxAnnual.price) / yearlyIfMonthly * 100).round();
    }
    return null;
  }

  Widget _buildBillingToggle(dynamic themeColors, rc.Offerings? offerings) {
    final savingsPercent = _calculateSavingsPercent(offerings);

    return GlassCard(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          // Monthly option
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _isAnnual = false);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isAnnual ? AppColors.premiumGold : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'شهري',
                    style: AppTypography.bodyMedium.copyWith(
                      color: !_isAnnual ? Colors.black : Colors.white70,
                      fontWeight: !_isAnnual ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Annual option with savings badge
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _isAnnual = true);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isAnnual ? AppColors.premiumGold : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'سنوي',
                      style: AppTypography.bodyMedium.copyWith(
                        color: _isAnnual ? Colors.black : Colors.white70,
                        fontWeight: _isAnnual ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (savingsPercent != null && savingsPercent > 0) ...[
                      const SizedBox(width: 6),
                      // Dynamic savings badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _isAnnual ? Colors.green : Colors.green.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'وفر $savingsPercent%',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get price info from offerings for a specific product
  _PriceInfo? _getPriceFromOfferings(rc.Offerings? offerings, String productId) {
    if (offerings?.current == null) return null;

    for (final pkg in offerings!.current!.availablePackages) {
      if (pkg.storeProduct.identifier == productId) {
        return _PriceInfo(
          price: pkg.storeProduct.price,
          priceString: pkg.storeProduct.priceString,
          currencyCode: pkg.storeProduct.currencyCode,
        );
      }
    }
    return null;
  }

  Widget _buildPricingCards(dynamic themeColors, rc.Offerings? offerings) {
    // Get dynamic prices from offerings (localized by RevenueCat based on user's region)
    final maxMonthly = _getPriceFromOfferings(offerings, SubscriptionProducts.maxMonthly);
    final maxAnnual = _getPriceFromOfferings(offerings, SubscriptionProducts.maxAnnual);

    // Show loading if prices aren't ready
    final isLoadingPrices = maxMonthly == null && maxAnnual == null;

    final priceInfo = _isAnnual ? maxAnnual : maxMonthly;
    final period = _isAnnual ? 'سنوياً' : 'شهرياً';

    // Calculate monthly equivalent for annual plan
    final monthlyEquivalent = (maxAnnual != null) ? maxAnnual.price / 12 : null;

    return GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.premiumGold.withValues(alpha: 0.3),
          AppColors.premiumGoldDark.withValues(alpha: 0.15),
        ],
      ),
      border: Border.all(color: AppColors.premiumGold, width: 2.5),
      child: Column(
        children: [
          // MAX badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.premiumGold, AppColors.premiumGoldDark],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.premiumGold.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              'صلني MAX',
              style: AppTypography.titleMedium.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Price
          if (isLoadingPrices)
            const SizedBox(
              height: 48,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.premiumGold,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            Text(
              priceInfo?.priceString ?? '---',
              style: const TextStyle(
                color: AppColors.premiumGold,
                fontWeight: FontWeight.bold,
                fontSize: 40,
              ),
            ),
          Text(
            period,
            style: AppTypography.bodyMedium.copyWith(color: Colors.white54),
          ),
          // Monthly equivalent for annual
          if (_isAnnual && monthlyEquivalent != null && priceInfo != null) ...[
            const SizedBox(height: 4),
            Text(
              '≈ ${monthlyEquivalent.toStringAsFixed(0)} ${priceInfo.currencyCode}/شهرياً',
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white38,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          const Divider(color: Colors.white24),
          const SizedBox(height: AppSpacing.sm),
          // Key features
          _buildFeatureItem('مساعد الذكاء الاصطناعي'),
          _buildFeatureItem('كتابة الرسائل الذكية'),
          _buildFeatureItem('تحليل العلاقات'),
          _buildFeatureItem('تذكيرات غير محدودة'),
          _buildFeatureItem('إحصائيات متقدمة'),
          _buildFeatureItem('تصدير البيانات'),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.premiumGold, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildRestoreButton(dynamic themeColors) {
    return TextButton(
      onPressed: _isPurchasing ? null : _restorePurchases,
      child: Text(
        'استعادة المشتريات',
        style: AppTypography.bodyMedium.copyWith(
          color: Colors.white70,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildLegalLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () => launchUrl(
            Uri.parse('https://ammarhassani.github.io/silni_app/privacy-policy-ar.html'),
            mode: LaunchMode.externalApplication,
          ),
          child: Text(
            'سياسة الخصوصية',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white54,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        Text(
          ' | ',
          style: AppTypography.bodySmall.copyWith(color: Colors.white38),
        ),
        TextButton(
          onPressed: () => launchUrl(
            Uri.parse('https://ammarhassani.github.io/silni_app/terms-ar.html'),
            mode: LaunchMode.externalApplication,
          ),
          child: Text(
            'الشروط والأحكام',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white54,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseButton(
    dynamic themeColors,
    rc.Offerings? offerings,
    bool isLoading,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      child: ElevatedButton(
        onPressed: _isPurchasing || isLoading ? null : () => _purchase(offerings),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.premiumGold,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: AppColors.premiumGold.withValues(alpha: 0.5),
        ),
        child: _isPurchasing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.black),
                ),
              )
            : Text(
                'ابدأ التجربة المجانية',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _purchase(rc.Offerings? offerings) async {
    if (offerings == null) {
      _showError('لا توجد عروض متاحة حالياً');
      return;
    }

    setState(() => _isPurchasing = true);

    try {
      final offering = offerings.current;
      if (offering == null) {
        _showError('لا توجد عروض متاحة حالياً');
        return;
      }

      // Find the MAX package (only tier now)
      rc.Package? package;
      final productSuffix = _isAnnual ? 'annual' : 'monthly';
      final targetPackageId = 'max_$productSuffix'; // e.g., "max_monthly"

      // Try to find the specific package by package identifier
      for (final pkg in offering.availablePackages) {
        if (pkg.identifier == targetPackageId) {
          package = pkg;
          break;
        }
      }

      // Fallback to default packages
      if (package == null) {
        package = _isAnnual ? offering.annual : offering.monthly;
      }

      if (package != null) {
        final success = await SubscriptionService.instance.purchase(package);
        if (success && mounted) {
          // Force refresh all subscription providers
          ref.invalidate(subscriptionStateProvider);

          // Show congratulations dialog with confetti
          await SubscriptionCongratsDialog.show(context, isAnnual: _isAnnual);

          if (mounted) {
            Navigator.of(context).pop(true);

            // Trigger premium onboarding for new MAX subscribers
            final shouldShowOnboarding = ref.read(shouldShowOnboardingProvider);
            if (shouldShowOnboarding && mounted) {
              await PremiumOnboardingScreen.show(context);
            }
          }
        }
      } else {
        _showError('المنتج غير متاح - تأكد من إكمال بيانات المنتج في App Store Connect');
      }
    } catch (e) {
      _showError('حدث خطأ أثناء الشراء');
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isPurchasing = true);

    try {
      final restored = await SubscriptionService.instance.restorePurchases();

      if (mounted) {
        // Force refresh all subscription providers
        ref.invalidate(subscriptionStateProvider);

        if (restored) {
          // Show congratulations dialog for restored subscription
          await SubscriptionCongratsDialog.show(context, isAnnual: true);

          if (mounted) {
            Navigator.of(context).pop(true);

            // Trigger premium onboarding for restored MAX subscribers
            final shouldShowOnboarding = ref.read(shouldShowOnboardingProvider);
            if (shouldShowOnboarding && mounted) {
              await PremiumOnboardingScreen.show(context);
            }
          }
        } else {
          UIHelpers.showSnackBar(
            context,
            'لم يتم العثور على مشتريات سابقة',
            isError: false,
            backgroundColor: Colors.orange,
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    UIHelpers.showSnackBar(
      context,
      message,
      isError: true,
    );
  }
}
