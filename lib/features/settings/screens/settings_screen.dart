import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/router/app_router.dart' as router;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/directional_icon.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/session_cleanup_service.dart';
import '../../../shared/widgets/message_widget.dart';
import '../../../shared/widgets/glass_pill_title.dart';
import '../../../shared/widgets/persistent_bottom_nav.dart';
import '../../../core/config/env/env.dart';
import '../../../core/providers/subscription_provider.dart';
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

                  // ── الاشتراك (Subscription) — promoted to top ──
                  _buildSectionHeader('الاشتراك', themeColors),
                  Consumer(
                    builder: (context, ref, _) {
                      final isMax = ref.watch(isMaxProvider);
                      return SubscriptionCard(compact: isMax);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── المظهر (Theme) — promoted to top ──
                  _buildSectionHeader('المظهر', themeColors),
                  const ThemePickerButton(),
                  const SizedBox(height: AppSpacing.lg),

                  // ── الحساب (Account) ────────────────────────────
                  _buildSectionHeader('الحساب', themeColors),
                  _buildIdentityTile(
                    ref: ref,
                    themeColors: themeColors,
                    onTap: () => context.push(AppRoutes.profile),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── التطبيق (App) ───────────────────────────────
                  _buildSectionHeader('التطبيق', themeColors),
                  _buildPremiumTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'الإشعارات',
                    subtitle: 'إدارة التذكيرات والتنبيهات',
                    leading: _LeadingStyle.bell,
                    accentColor: themeColors.levelMax,
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        themeColors.levelMax.withValues(alpha: 0.22),
                        AppColors.premiumGoldDark.withValues(alpha: 0.2),
                        themeColors.primary.withValues(alpha: 0.18),
                      ],
                    ),
                    themeColors: themeColors,
                    onTap: () => context.push(AppRoutes.notifications),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Phase 9.X.D.B Track B6 — re-run setup wizard. De-emphasized
                  // escape hatch for power users / support cases. Confirms
                  // before clearing setupComplete and pushing the wizard.
                  _buildPremiumTile(
                    icon: Icons.restart_alt_rounded,
                    title: 'إعادة الإعداد',
                    subtitle: 'أعد عرض دليل البداية',
                    leading: _LeadingStyle.ring,
                    accentColor: themeColors.secondary,
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        themeColors.secondary.withValues(alpha: 0.25),
                        themeColors.primary.withValues(alpha: 0.22),
                        themeColors.accent.withValues(alpha: 0.1),
                      ],
                    ),
                    themeColors: themeColors,
                    onTap: () => _confirmRerunSetup(context, ref),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Builder(
                    builder: (ctx) => _buildPremiumTile(
                      icon: Icons.person_add_alt_1_rounded,
                      title: 'دعوة صديق',
                      subtitle: 'صِلْ رحمك بمشاركة التطبيق',
                      accentColor: AppColors.calmBlue,
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          AppColors.calmBlue.withValues(alpha: 0.28),
                          themeColors.primary.withValues(alpha: 0.32),
                          AppColors.premiumGold.withValues(alpha: 0.08),
                        ],
                      ),
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
                  _buildPremiumTile(
                    icon: Icons.star_rate_rounded,
                    title: 'قيّم التطبيق',
                    subtitle: 'ساعدنا بنجمة في المتجر',
                    accentColor: AppColors.premiumGold,
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        AppColors.premiumGold.withValues(alpha: 0.22),
                        AppColors.premiumGoldDark.withValues(alpha: 0.28),
                        themeColors.primary.withValues(alpha: 0.18),
                      ],
                    ),
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
                  const SizedBox(height: AppSpacing.sm),
                  _buildPremiumTile(
                    icon: Icons.logout_rounded,
                    title: 'تسجيل الخروج',
                    subtitle: 'إنهاء جلستك على هذا الجهاز',
                    leading: _LeadingStyle.circle,
                    accentColor:
                        themeColors.textOnGradient.withValues(alpha: 0.55),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        themeColors.textOnGradient.withValues(alpha: 0.08),
                        themeColors.textOnGradient.withValues(alpha: 0.03),
                      ],
                    ),
                    themeColors: themeColors,
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

  /// Build a rich, distinctive action card. Multi-stop gradient + decorative
  /// orbs + accent-colored leading shape + title/subtitle + arrow chip. The
  /// leading-shape vocabulary (circle / square / ring / bell) keeps a column
  /// of these tiles reading as varied rather than templated.
  Widget _buildPremiumTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required Color accentColor,
    required dynamic themeColors,
    required VoidCallback onTap,
    _LeadingStyle leading = _LeadingStyle.circle,
  }) {
    return Semantics(
      label: '$title - $subtitle',
      button: true,
      child: GlassCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        gradient: gradient,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Stack(
            children: [
              // Radial glow (top-right)
              Positioned(
                top: -28,
                right: -28,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.32),
                        accentColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Orb (bottom-left)
              Positioned(
                left: -16,
                bottom: -20,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.14),
                  ),
                ),
              ),
              // Small accent orb (mid-right)
              Positioned(
                right: 40,
                top: 8,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.18),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    _buildLeading(
                      leading,
                      icon,
                      accentColor,
                      themeColors,
                      size: 48,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: AppTypography.titleMedium.copyWith(
                              color: themeColors.textOnGradient,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: AppTypography.bodySmall.copyWith(
                              color: themeColors.textOnGradient
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                      child: DirectionalIcon(
                        Icons.arrow_back_ios_rounded,
                        color: themeColors.textOnGradient
                            .withValues(alpha: 0.85),
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Identity tile — Profile entry. Avatar gradient circle showing user's
  /// first initial, name + email subtitle, theme primary tint background.
  Widget _buildIdentityTile({
    required WidgetRef ref,
    required dynamic themeColors,
    required VoidCallback onTap,
  }) {
    final user = ref.watch(currentUserProvider);
    final email = user?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '؟';
    final displayName = (user?.userMetadata?['full_name'] as String?)?.trim();
    final subtitle = (displayName != null && displayName.isNotEmpty)
        ? email
        : 'الملف الشخصي';
    final title = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : 'الملف الشخصي';

    return Semantics(
      label: 'الملف الشخصي - $email',
      button: true,
      child: GlassCard(
        onTap: onTap,
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            themeColors.primary.withValues(alpha: 0.18),
            themeColors.primaryDark.withValues(alpha: 0.12),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    themeColors.primary,
                    themeColors.primaryDark,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeColors.primary.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: AppTypography.titleLarge.copyWith(
                    color: themeColors.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: themeColors.textOnGradient,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: themeColors.textOnGradient
                            .withValues(alpha: 0.65),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            DirectionalIcon(
              Icons.arrow_forward_ios_rounded,
              color: themeColors.textOnGradient.withValues(alpha: 0.55),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// Render the leading shape vocabulary. Each style is intentionally
  /// distinct (circle / squircle / open ring / bell-with-dot) so a column
  /// of these tiles reads as a varied list rather than a uniform template.
  Widget _buildLeading(
    _LeadingStyle style,
    IconData icon,
    Color accent,
    dynamic themeColors, {
    double size = 44,
  }) {
    final iconSize = size * 0.5;
    final radius = size * 0.27;
    final dotSize = size * 0.23;
    switch (style) {
      case _LeadingStyle.circle:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.22),
            border: Border.all(
              color: accent.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Icon(icon, color: accent, size: iconSize),
        );
      case _LeadingStyle.square:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: accent.withValues(alpha: 0.22),
            border: Border.all(
              color: accent.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Icon(icon, color: accent, size: iconSize),
        );
      case _LeadingStyle.ring:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.all(color: accent, width: 2.5),
          ),
          child: Icon(icon, color: accent, size: iconSize),
        );
      case _LeadingStyle.bell:
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.22),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, color: accent, size: iconSize),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeColors.statusError,
                    border: Border.all(
                      color: themeColors.textOnGradient.withValues(alpha: 0.85),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
    }
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

/// Leading-shape vocabulary for [_buildDistinctTile]. Each style produces a
/// visually distinct icon container so a column of mixed tiles reads as
/// hand-crafted rather than a uniform template.
enum _LeadingStyle { circle, square, ring, bell }

