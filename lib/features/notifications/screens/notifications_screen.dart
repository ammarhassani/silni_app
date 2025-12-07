import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_themes.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/services/notification_service.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  bool _remindersEnabled = true;
  bool _dailyRemindersEnabled = true;
  bool _weeklyRemindersEnabled = true;
  bool _birthdayRemindersEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);

    return GradientBackground(
      animated: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    // Notification Preferences
                    Text(
                      '🔔 تفضيلات الإشعارات',
                      style: AppTypography.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    _buildSwitchTile(
                      title: 'تفعيل الإشعارات',
                      subtitle: 'تلقي إشعارات عامة من التطبيق',
                      value: _remindersEnabled,
                      onChanged: (value) {
                        HapticFeedback.selectionClick();
                        setState(() => _remindersEnabled = value);
                      },
                      themeColors: themeColors,
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    _buildSwitchTile(
                      title: 'تذكيرات يومية',
                      subtitle: 'تذكير يومي للتواصل مع الأقارب',
                      value: _dailyRemindersEnabled,
                      onChanged: (value) {
                        HapticFeedback.selectionClick();
                        setState(() => _dailyRemindersEnabled = value);
                      },
                      themeColors: themeColors,
                      enabled: _remindersEnabled,
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    _buildSwitchTile(
                      title: 'تذكيرات أسبوعية',
                      subtitle: 'تذكير أسبوعي بالأقارب الذين يحتاجون تواصل',
                      value: _weeklyRemindersEnabled,
                      onChanged: (value) {
                        HapticFeedback.selectionClick();
                        setState(() => _weeklyRemindersEnabled = value);
                      },
                      themeColors: themeColors,
                      enabled: _remindersEnabled,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Sound & Vibration
                    Text(
                      '🔊 الصوت والاهتزاز',
                      style: AppTypography.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    _buildSwitchTile(
                      title: 'الصوت',
                      subtitle: 'تشغيل صوت عند وصول إشعار',
                      value: _soundEnabled,
                      onChanged: (value) {
                        HapticFeedback.selectionClick();
                        setState(() => _soundEnabled = value);
                      },
                      themeColors: themeColors,
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    _buildSwitchTile(
                      title: 'الاهتزاز',
                      subtitle: 'اهتزاز الجهاز عند وصول إشعار',
                      value: _vibrationEnabled,
                      onChanged: (value) {
                        HapticFeedback.selectionClick();
                        setState(() => _vibrationEnabled = value);
                      },
                      themeColors: themeColors,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Device Info
                    Text(
                      '📱 معلومات الجهاز',
                      style: AppTypography.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: themeColors.accent,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'معرّف الإشعارات',
                                style: AppTypography.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _notificationService.fcmToken != null
                                ? 'تم الحصول على المعرّف'
                                : 'لم يتم الحصول على المعرّف',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Test Notification Button
                    GlassCard(
                      child: ListTile(
                        leading: Icon(
                          Icons.send_rounded,
                          color: themeColors.accent,
                        ),
                        title: Text(
                          'إرسال إشعار تجريبي',
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          'اختبر الإشعارات على جهازك',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white.withOpacity(0.5),
                          size: 20,
                        ),
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _sendTestNotification();
                        },
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إعدادات الإشعارات',
                  style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تخصيص التذكيرات والإشعارات',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeColors themeColors,
    bool enabled = true,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: enabled
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: enabled
                        ? Colors.white.withOpacity(0.7)
                        : Colors.white.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: themeColors.primary,
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.1, end: 0);
  }

  void _sendTestNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إرسال إشعار تجريبي! 🔔'),
        backgroundColor: AppColors.islamicGreenPrimary,
      ),
    );

    // TODO: Actually send a test local notification
    // _notificationService.scheduleReminderNotification(
    //   id: DateTime.now().millisecondsSinceEpoch,
    //   title: 'إشعار تجريبي',
    //   body: 'هذا إشعار تجريبي من تطبيق صلني',
    //   scheduledTime: DateTime.now().add(const Duration(seconds: 5)),
    // );
  }
}
