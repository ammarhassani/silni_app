import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/services/auth_service.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/subscription_tier.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/dynamic_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/theme_aware_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../../subscription/screens/paywall_screen.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../shared/widgets/message_widget.dart';
import '../../../core/config/env/env.dart';

/// Admin email for showing environment badge
const _adminEmail = 'azahrani337@gmail.com';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeKey = ref.watch(themeKeyProvider);
    final themeColors = ref.watch(themeColorsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Semantics(
        label: 'شاشة الإعدادات',
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'الإعدادات',
                      style: AppTypography.headlineMedium.copyWith(
                        color: themeColors.textOnGradient,
                      ),
                    ),
                  ],
                ),
              ),

            // Settings list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // In-App Messages
                  const MessageWidget(screenPath: '/settings'),
                  const SizedBox(height: AppSpacing.md),
                  // Subscription Card
                  _buildSubscriptionCard(context, ref, themeColors),
                  const SizedBox(height: AppSpacing.md),

                  // Theme Selector
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.palette,
                              color: AppColors.premiumGold,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'المظهر',
                              style: AppTypography.titleLarge.copyWith(
                                color: themeColors.textOnGradient,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'اختر المظهر المفضل لديك',
                          style: AppTypography.bodyMedium.copyWith(
                            color: themeColors.textOnGradient.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Theme Grid - Dynamic themes with scrollable support
                        _buildThemeGrid(context, ref, currentThemeKey),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Profile
                  GlassCard(
                    child: ListTile(
                      leading: Icon(Icons.person, color: themeColors.textOnGradient),
                      title: Text(
                        'الملف الشخصي',
                        style: AppTypography.titleMedium.copyWith(
                          color: themeColors.textOnGradient,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: themeColors.textOnGradient.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      onTap: () {
                        context.push(AppRoutes.profile);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Notifications
                  GlassCard(
                    child: ListTile(
                      leading: Icon(
                        Icons.notifications,
                        color: themeColors.textOnGradient,
                      ),
                      title: Text(
                        'الإشعارات',
                        style: AppTypography.titleMedium.copyWith(
                          color: themeColors.textOnGradient,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: themeColors.textOnGradient.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      onTap: () {
                        context.push(AppRoutes.notifications);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Change Password
                  GlassCard(
                    child: ListTile(
                      leading: Icon(Icons.lock_outline, color: themeColors.textOnGradient),
                      title: Text(
                        'تغيير كلمة المرور',
                        style: AppTypography.titleMedium.copyWith(
                          color: themeColors.textOnGradient,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: themeColors.textOnGradient.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      onTap: () => _showChangePasswordDialog(context, ref),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Logout
                  GlassCard(
                    child: ListTile(
                      leading: Icon(Icons.logout, color: themeColors.textOnGradient),
                      title: Text(
                        'تسجيل الخروج',
                        style: AppTypography.titleMedium.copyWith(
                          color: themeColors.textOnGradient,
                        ),
                      ),
                      onTap: () async {
                        final authService = ref.read(authServiceProvider);
                        await authService.signOut();
                        if (context.mounted) {
                          context.go(AppRoutes.login);
                        }
                      },
                    ),
                  ),

                  // Environment badge for admin user
                  _buildAdminEnvBadge(ref, themeColors),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// Build environment badge for admin user only
  Widget _buildAdminEnvBadge(WidgetRef ref, dynamic themeColors) {
    // Use the provider instead of directly accessing Supabase
    final user = ref.watch(currentUserProvider);
    final isAdmin = user?.email == _adminEmail;

    if (!isAdmin) return const SizedBox.shrink();

    final isProduction = Env.appEnv == 'production';
    final envLabel = isProduction ? 'PRODUCTION' : 'STAGING';
    final envColor = isProduction ? Colors.red : Colors.orange;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: envColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: envColor, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isProduction ? Icons.warning_rounded : Icons.bug_report_rounded,
                color: envColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                envLabel,
                style: AppTypography.labelMedium.copyWith(
                  color: envColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, WidgetRef ref, dynamic themeColors) {
    final currentTier = ref.watch(subscriptionTierProvider);
    final isTrialActive = ref.watch(isTrialActiveProvider);
    final trialDays = ref.watch(trialDaysRemainingProvider);
    final expirationDate = ref.watch(subscriptionExpirationProvider);
    final isFreeUser = currentTier == SubscriptionTier.free;
    final canUpgrade = currentTier.canUpgrade && currentTier != SubscriptionTier.free;

    // Determine badge color based on tier
    final badgeColor = currentTier.isMax
        ? AppColors.premiumGold
        : Colors.grey;

    return GlassCard(
      gradient: currentTier.isMax
          ? LinearGradient(
              colors: [
                AppColors.premiumGold.withValues(alpha: 0.2),
                AppColors.premiumGoldDark.withValues(alpha: 0.1),
              ],
            )
          : null,
      border: isFreeUser ? null : Border.all(color: badgeColor.withValues(alpha: 0.5)),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isFreeUser
                        ? [Colors.grey, Colors.grey.shade700]
                        : currentTier.isMax
                            ? [AppColors.premiumGold, AppColors.premiumGoldDark]
                            : [AppColors.islamicGreenPrimary, AppColors.islamicGreenDark],
                  ),
                ),
                child: Icon(
                  isFreeUser ? Icons.person : Icons.workspace_premium,
                  color: isFreeUser ? Colors.white : (currentTier.isMax ? Colors.black87 : Colors.white),
                  size: 24,
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
                          style: AppTypography.titleLarge.copyWith(
                            color: themeColors.textOnGradient,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: currentTier.isMax
                                ? AppColors.goldenGradient
                                : null,
                            color: currentTier.isMax ? null : badgeColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            currentTier.englishName,
                            style: AppTypography.labelSmall.copyWith(
                              color: currentTier.isMax ? Colors.black87 : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTrialActive
                          ? 'تجربة مجانية - متبقي $trialDays أيام'
                          : isFreeUser
                              ? 'ترقية للحصول على ميزات أكثر'
                              : currentTier.arabicDescription,
                      style: AppTypography.bodySmall.copyWith(
                        color: themeColors.textOnGradient.withValues(alpha: 0.7),
                      ),
                    ),
                    // Show expiration date for paid users
                    if (!isFreeUser && expirationDate != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'ينتهي في: ${_formatDate(expirationDate)}',
                        style: AppTypography.labelSmall.copyWith(
                          color: themeColors.textOnGradient.withValues(alpha: 0.54),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Action buttons
          if (isFreeUser) ...[
            // Free user - show upgrade button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _openPaywall(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.premiumGold,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'ترقية الآن',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Paid user - show manage and optionally upgrade
            Row(
              children: [
                // Manage subscription button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openSubscriptionManagement(context, ref),
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    label: const Text('إدارة'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: themeColors.textOnGradient,
                      side: BorderSide(color: themeColors.textOnGradient.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                // Upgrade button (only for PRO users, not MAX)
                if (canUpgrade) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openPaywall(context),
                      icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                      label: const Text('ترقية لـ MAX'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.premiumGold,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            // Restore purchases link
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                onPressed: () => _restorePurchases(context, ref),
                child: Text(
                  'استعادة المشتريات',
                  style: AppTypography.bodySmall.copyWith(
                    color: themeColors.textOnGradient.withValues(alpha: 0.54),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _openPaywall(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PaywallScreen(),
      ),
    );
  }

  Future<void> _openSubscriptionManagement(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    final themeColors = ref.read(themeColorsProvider);

    // iOS App Store subscription management URL
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
      // Google Play subscription management
      final uri = Uri.parse('https://play.google.com/store/account/subscriptions');
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

  Future<void> _restorePurchases(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    final themeColors = ref.read(themeColorsProvider);

    UIHelpers.showSnackBar(
      context,
      'جاري استعادة المشتريات...',
      backgroundColor: themeColors.statusInfo,
    );

    try {
      final restored = await SubscriptionService.instance.restorePurchases();
      ref.invalidate(subscriptionStateProvider);

      if (context.mounted) {
        UIHelpers.showSnackBar(
          context,
          restored
              ? 'تم استعادة الاشتراك بنجاح!'
              : 'لم يتم العثور على مشتريات سابقة',
          isError: !restored,
          backgroundColor: restored ? themeColors.statusSuccess : themeColors.statusWarning,
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

  Future<void> _showChangePasswordDialog(BuildContext context, WidgetRef ref) async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    await showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final themeColors = ref.watch(themeColorsProvider);

          return ThemeAwareAlertDialog(
            title: 'تغيير كلمة المرور',
            titleIcon: Icon(
              Icons.lock_outline,
              color: themeColors.primary,
              size: 32,
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Current password
                    _buildThemedPasswordField(
                      controller: currentPasswordController,
                      label: 'كلمة المرور الحالية',
                      obscureText: obscureCurrentPassword,
                      onToggleVisibility: () => setState(() => obscureCurrentPassword = !obscureCurrentPassword),
                      themeColors: themeColors,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال كلمة المرور الحالية';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // New password
                    _buildThemedPasswordField(
                      controller: newPasswordController,
                      label: 'كلمة المرور الجديدة',
                      obscureText: obscureNewPassword,
                      onToggleVisibility: () => setState(() => obscureNewPassword = !obscureNewPassword),
                      themeColors: themeColors,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال كلمة المرور الجديدة';
                        }
                        if (value.length < 8) {
                          return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
                        }
                        if (!RegExp(r'[A-Z]').hasMatch(value)) {
                          return 'يجب أن تحتوي على حرف كبير واحد على الأقل';
                        }
                        if (!RegExp(r'[a-z]').hasMatch(value)) {
                          return 'يجب أن تحتوي على حرف صغير واحد على الأقل';
                        }
                        if (!RegExp(r'[0-9]').hasMatch(value)) {
                          return 'يجب أن تحتوي على رقم واحد على الأقل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Confirm new password
                    _buildThemedPasswordField(
                      controller: confirmPasswordController,
                      label: 'تأكيد كلمة المرور الجديدة',
                      obscureText: obscureConfirmPassword,
                      onToggleVisibility: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                      themeColors: themeColors,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء تأكيد كلمة المرور الجديدة';
                        }
                        if (value != newPasswordController.text) {
                          return 'كلمة المرور غير متطابقة';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'إلغاء',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        setState(() => isLoading = true);

                        try {
                          final authService = ref.read(authServiceProvider);
                          final user = authService.currentUser;

                          if (user?.email == null) {
                            throw Exception('المستخدم غير موجود');
                          }

                          // Re-authenticate with current password first
                          await authService.signInWithEmail(
                            email: user!.email!,
                            password: currentPasswordController.text,
                          );

                          // Update to new password
                          await authService.updatePassword(newPasswordController.text);

                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }

                          if (context.mounted) {
                            UIHelpers.showSnackBar(
                              context,
                              'تم تغيير كلمة المرور بنجاح',
                              backgroundColor: themeColors.statusSuccess,
                            );
                          }
                        } on AuthException catch (e) {
                          setState(() => isLoading = false);
                          if (context.mounted) {
                            UIHelpers.showSnackBar(
                              context,
                              AuthService.getErrorMessage(e.message),
                              isError: true,
                            );
                          }
                        } catch (e) {
                          setState(() => isLoading = false);
                          if (context.mounted) {
                            UIHelpers.showSnackBar(
                              context,
                              'حدث خطأ أثناء تغيير كلمة المرور',
                              isError: true,
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('تغيير'),
              ),
            ],
          );
        },
      ),
    );
    // Note: Controllers are local variables and will be garbage collected.
    // Manual dispose was removed because it caused issues when the dialog
    // is still animating out after Navigator.pop() is called.
  }

  /// Build a themed password field with visibility toggle
  Widget _buildThemedPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required dynamic themeColors,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 14,
        ),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: Colors.white.withValues(alpha: 0.7),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          onPressed: onToggleVisibility,
        ),
        filled: true,
        fillColor: themeColors.background2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: themeColors.primary.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: themeColors.primary.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: themeColors.primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: Colors.red, width: 2.0),
        ),
        errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
      validator: validator,
    );
  }

  /// Build the theme grid with dynamic themes and scrollable support
  Widget _buildThemeGrid(
    BuildContext context,
    WidgetRef ref,
    String currentThemeKey,
  ) {
    final themes = ref.watch(dynamicThemesProvider);
    final hasMoreThanSix = themes.length > 6;

    return Column(
      children: [
        // Fixed height container for ~2 visible rows, scrollable if more themes
        // ClipRect prevents content from overflowing when scrolled
        ClipRect(
          child: SizedBox(
            height: hasMoreThanSix ? 300 : null,
            child: GridView.builder(
              clipBehavior: Clip.none, // Allow selection ring overflow within visible area
              padding: const EdgeInsets.all(6), // Space for selection ring (4px + 2px buffer)
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.85,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
              ),
              shrinkWrap: !hasMoreThanSix,
              physics: hasMoreThanSix
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              itemCount: themes.length,
              itemBuilder: (context, index) {
                final theme = themes[index];
                final isSelected = currentThemeKey == theme.key;
                return _buildThemeCard(context, ref, theme, isSelected);
              },
            ),
          ),
        ),
        // Scroll hint if more than 6 themes
        if (hasMoreThanSix)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.swipe_vertical,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  'اسحب للمزيد',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    WidgetRef ref,
    DynamicTheme theme,
    bool isSelected,
  ) {
    final themeColors = theme.colors;
    final hasThemeAccess = ref.watch(featureAccessProvider(FeatureIds.customThemes));

    // Free themes or users with access can use the theme
    final isLocked = theme.isPremium && !hasThemeAccess;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();

        if (isLocked) {
          // Show paywall for locked themes
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const PaywallScreen(
                featureToUnlock: FeatureIds.customThemes,
              ),
            ),
          );
          return;
        }

        ref.read(themeStateProvider.notifier).setThemeByKey(theme.key);
        UIHelpers.showSnackBar(
          context,
          'تم تغيير المظهر إلى ${theme.displayNameAr}',
          backgroundColor: themeColors.primary,
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          // Theme card with blur only for locked themes (no grayscale)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: ImageFiltered(
              imageFilter: isLocked
                  ? ui.ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0)
                  : ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: themeColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Theme icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      child: const Icon(
                        Icons.palette_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Theme name
                    Text(
                      theme.displayNameAr,
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Selected indicator text (Reserved space)
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isSelected ? 1.0 : 0.0,
                      child: Text(
                        'مُختار',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.premiumGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Subtle dark overlay for locked themes
          if (isLocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  color: Colors.black.withValues(alpha: 0.1),
                ),
              ),
            ),
          // External selection ring (gold glow)
          if (isSelected)
            Positioned(
              top: -4,
              bottom: -4,
              left: -4,
              right: -4,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg + 4),
                  border: Border.all(
                    color: AppColors.premiumGold,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.premiumGold.withValues(alpha: 0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          // Premium badge for locked themes
          if (isLocked)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.premiumGold, AppColors.premiumGoldDark],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.lock, size: 12, color: Colors.black87),
              ),
            ),
        ],
      ),
    );
  }

}
