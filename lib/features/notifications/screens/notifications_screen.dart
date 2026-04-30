// NOTIFICATION TOGGLES CUT FROM V1 (2026-04-26).
// Previous toggles wrote to SharedPreferences but never gated FCM or local
// notifications. v1 relies on OS-level notification controls.
// v1.1 plan: ship FCM topic-subscription infrastructure (server-side topic
// publish + client-side subscribe/unsubscribe + offline reconciliation),
// then re-enable per-category toggles backed by topic membership.
// SharedPreferences keys preserved so v1.1 can read prior user intent.

import 'dart:io' show Platform;
import '../../../shared/widgets/directional_icon.dart';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/message_widget.dart';

/// SharedPreferences keys preserved verbatim for v1.1 readback.
///
/// The previous in-screen toggles wrote to these keys but never gated
/// FCM or local notifications. v1.1 (topic-subscription infra) will read
/// any prior values to seed initial topic membership before re-exposing
/// per-category controls. The keys are unused in v1 — that's intentional.
// ignore_for_file: unused_field, unused_element
class _NotificationPrefsKeys {
  static const String remindersEnabled = 'notifications_reminders_enabled';
  static const String dailyRemindersEnabled = 'notifications_daily_enabled';
  static const String weeklyRemindersEnabled = 'notifications_weekly_enabled';
  static const String soundEnabled = 'notifications_sound_enabled';
  static const String vibrationEnabled = 'notifications_vibration_enabled';
}

/// v1 notifications screen — explainer + OS-settings launcher.
///
/// All control of notification delivery happens at the OS level. Tapping
/// the button below opens iOS Settings → Silni → Notifications directly;
/// on Android the user is shown the path to navigate manually (a native
/// intent for `APP_NOTIFICATION_SETTINGS` would require an extra package).
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = ref.watch(themeColorsProvider);

    return GradientBackground(
      animated: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: Semantics(
          label: 'إعدادات الإشعارات',
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, themeColors),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.xxl,
                    ),
                    children: [
                      const MessageWidget(screenPath: '/notifications'),
                      const SizedBox(height: AppSpacing.md),
                      GlassCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Icon(
                              Icons.notifications_active_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'إدارة إشعارات صِلْني من إعدادات النظام',
                              style: AppTypography.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'لتشغيل أو إيقاف التذكيرات والإشعارات، '
                              'افتح إعدادات الإشعارات الخاصة بصِلْني '
                              'من خلال إعدادات النظام.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            GradientButton(
                              text: 'افتح إعدادات النظام',
                              icon: Icons.open_in_new_rounded,
                              onPressed: () =>
                                  _openSystemNotificationSettings(context),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Open the OS notification settings for Silni.
  ///
  /// iOS: `app-settings:` URL scheme jumps straight to the app's
  /// notification page. Confirmed by Apple as the supported deep-link
  /// since iOS 8 — same scheme used by `permission_handler` etc.
  ///
  /// Android: `url_launcher` can't open the
  /// `android.settings.APP_NOTIFICATION_SETTINGS` intent without a native
  /// helper, so we surface the manual path via a snackbar. v1.1 with
  /// `app_settings` or `permission_handler` will improve this.
  Future<void> _openSystemNotificationSettings(BuildContext context) async {
    if (Platform.isIOS) {
      final uri = Uri.parse('app-settings:');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
      if (context.mounted) {
        UIHelpers.showSnackBar(
          context,
          'تعذّر فتح الإعدادات. افتح إعدادات الجهاز > صِلْني > الإشعارات.',
          isError: true,
        );
      }
      return;
    }

    if (context.mounted) {
      UIHelpers.showSnackBar(
        context,
        'افتح إعدادات الجهاز > التطبيقات > صِلْني > الإشعارات.',
      );
    }
  }

  Widget _buildHeader(BuildContext context, dynamic themeColors) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Semantics(
            label: 'رجوع',
            button: true,
            child: IconButton(
              onPressed: () => context.pop(),
              icon: DirectionalIcon(Icons.arrow_forward_rounded,
                  color: themeColors.textOnGradient),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'إعدادات الإشعارات',
              style: AppTypography.headlineMedium.copyWith(
                color: themeColors.textOnGradient,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }
}
