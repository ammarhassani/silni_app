import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/router/app_router.dart' as router;
import '../../../shared/services/auth_service.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/session_cleanup_service.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../shared/widgets/message_widget.dart';
import '../../../shared/widgets/glass_pill_title.dart';
import '../../../shared/widgets/persistent_bottom_nav.dart';
import '../../../core/config/env/env.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../profile/widgets/profile_dialogs.dart';
import '../widgets/subscription_card.dart';
import '../widgets/theme_carousel.dart';

/// Admin email for showing environment badge
const _adminEmail = 'azahrani337@gmail.com';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Semantics(
        label: 'شاشة الإعدادات',
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Settings list
              ListView(
                padding: EdgeInsets.only(
                  top: 56,
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: PersistentBottomNav.totalHeight + AppSpacing.md,
                ),
                children: [
                  // In-App Messages
                  const MessageWidget(screenPath: '/settings'),
                  const SizedBox(height: AppSpacing.md),

                  // ── الحساب (Account) ────────────────────────────
                  _buildSectionHeader('الحساب', themeColors),
                  _buildSettingsTile(
                    icon: Icons.person,
                    title: 'الملف الشخصي',
                    themeColors: themeColors,
                    onTap: () => context.push(AppRoutes.profile),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSettingsTile(
                    icon: Icons.lock_outline,
                    title: 'تغيير كلمة المرور',
                    themeColors: themeColors,
                    onTap: () => _showChangePasswordDialog(context, ref),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSettingsTile(
                    icon: Icons.logout,
                    title: 'تسجيل الخروج',
                    themeColors: themeColors,
                    showChevron: false,
                    onTap: () async {
                      final userId =
                          Supabase.instance.client.auth.currentUser?.id;
                      final authService = ref.read(authServiceProvider);
                      await authService.signOut();
                      clearUserSessionFromWidget(
                        ref,
                        previousUserId: userId,
                      );
                      if (context.mounted) {
                        context.go(AppRoutes.login);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Phase 9.X.D.B Track B6 — re-run setup wizard. De-emphasized
                  // escape hatch for power users / support cases. Confirms
                  // before clearing setupComplete and pushing the wizard.
                  _buildSettingsTile(
                    icon: Icons.replay_rounded,
                    title: 'إعادة الإعداد',
                    themeColors: themeColors,
                    onTap: () => _confirmRerunSetup(context, ref),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Mirror of the delete-account entry on Profile. The
                  // dialog itself (showDeleteAccountDialog) handles the
                  // 2-step warning + typed-confirm + password re-auth.
                  _buildSettingsTile(
                    icon: Icons.delete_forever_rounded,
                    title: 'حذف الحساب',
                    themeColors: themeColors,
                    iconColor: themeColors.statusError,
                    titleColor: themeColors.statusError,
                    showChevron: false,
                    onTap: () => showDeleteAccountDialog(
                      context: context,
                      ref: ref,
                      themeColors: themeColors,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── التطبيق (App) ───────────────────────────────
                  _buildSectionHeader('التطبيق', themeColors),
                  const ThemePickerButton(),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSettingsTile(
                    icon: Icons.notifications,
                    title: 'الإشعارات',
                    themeColors: themeColors,
                    onTap: () => context.push(AppRoutes.notifications),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Builder(
                    builder: (ctx) => _buildSettingsTile(
                      icon: Icons.person_add_alt_1_rounded,
                      title: 'دعوة صديق',
                      trailingIcon: Icons.share_rounded,
                      themeColors: themeColors,
                      onTap: () {
                        final box = ctx.findRenderObject() as RenderBox;
                        final origin =
                            box.localToGlobal(Offset.zero) & box.size;
                        Share.share(
                          'حمّل تطبيق صِلْني وصِل رحمك 🌳\n\n'
                          'iOS: https://apps.apple.com/app/id6738029498\n'
                          'Android: https://play.google.com/store/apps/details?id=com.silni.app',
                          sharePositionOrigin: origin,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSettingsTile(
                    icon: Icons.star_rate_rounded,
                    title: 'قيّم التطبيق',
                    themeColors: themeColors,
                    onTap: () async {
                      final inAppReview = InAppReview.instance;
                      if (await inAppReview.isAvailable()) {
                        await inAppReview.requestReview();
                      } else {
                        await inAppReview.openStoreListing(
                          appStoreId: '6738029498',
                        );
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── الاشتراك (Subscription) ─────────────────────
                  _buildSectionHeader('الاشتراك', themeColors),
                  Consumer(
                    builder: (context, ref, _) {
                      final isMax = ref.watch(isMaxProvider);
                      return SubscriptionCard(compact: isMax);
                    },
                  ),

                  // Environment badge for admin user
                  _buildAdminEnvBadge(ref, themeColors),
                ],
              ),
              // Floating header pill
              const Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.md,
                child: GlassPillTitle(text: 'الإعدادات'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a section header label for the three grouped settings sections.
  Widget _buildSectionHeader(String title, dynamic themeColors) {
    return Padding(
      padding: const EdgeInsets.only(
        right: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        title,
        style: AppTypography.labelLarge.copyWith(
          color: themeColors.textOnGradient.withValues(alpha: 0.55),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Build a consistent settings tile. Reduces the previous row duplication.
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required dynamic themeColors,
    required VoidCallback onTap,
    IconData trailingIcon = Icons.arrow_forward_ios_rounded,
    bool showChevron = true,
    Color? iconColor,
    Color? titleColor,
  }) {
    return GlassCard(
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? themeColors.textOnGradient),
        title: Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            color: titleColor ?? themeColors.textOnGradient,
          ),
        ),
        trailing: showChevron
            ? Icon(
                trailingIcon,
                color: themeColors.textOnGradient.withValues(alpha: 0.5),
                size: 20,
              )
            : null,
        onTap: onTap,
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

          return AlertDialog(
            backgroundColor: themeColors.background1.withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            titlePadding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            contentPadding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            actionsPadding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  color: themeColors.primary,
                  size: 32,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'تغيير كلمة المرور',
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
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
                  style: TextStyle(color: themeColors.primary),
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

  /// Phase 9.X.D.B Track B6 — confirm + re-run the onboarding wizard.
  ///
  /// Clears the local setupComplete cache + SharedPreferences mirror, sets
  /// `users.onboarding_metadata->>'setupComplete'` to false on prod, then
  /// navigates to /onboarding-wizard. The wizard's finish callback writes
  /// setupComplete=true again on completion.
  Future<void> _confirmRerunSetup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إعادة الإعداد'),
        content: const Text(
          'سيتم إعادة عرض دليل الإعداد. أي إعدادات حالية تبقى كما هي؛ هذا فقط يعيد عرض الخطوات. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('إعادة البدء'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    try {
      // Clear server-side flag
      final row = await SupabaseConfig.client
          .from('users')
          .select('onboarding_metadata')
          .eq('id', user.id)
          .maybeSingle();
      final meta =
          (row?['onboarding_metadata'] as Map<String, dynamic>?) ?? const {};
      final next = Map<String, dynamic>.from(meta)..['setupComplete'] = false;
      await SupabaseConfig.client
          .from('users')
          .update({'onboarding_metadata': next})
          .eq('id', user.id);

      // Mirror locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('setup_complete', false);
      router.setCachedSetupComplete(false);
    } catch (_) {
      // Even on partial failure, push the wizard — user expressed intent.
    }
    if (context.mounted) context.go(AppRoutes.onboardingWizard);
  }
}
