import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_themes.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/services/supabase_notification_service.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../shared/widgets/message_widget.dart';

/// SharedPreferences keys for notification settings persistence
class _NotificationPrefsKeys {
  static const String remindersEnabled = 'notifications_reminders_enabled';
  static const String dailyRemindersEnabled = 'notifications_daily_enabled';
  static const String weeklyRemindersEnabled = 'notifications_weekly_enabled';
  static const String soundEnabled = 'notifications_sound_enabled';
  static const String vibrationEnabled = 'notifications_vibration_enabled';
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final SupabaseNotificationService _notificationService =
      SupabaseNotificationService();

  bool _remindersEnabled = true;
  bool _dailyRemindersEnabled = true;
  bool _weeklyRemindersEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeNotificationService();
    _loadSavedPreferences();
  }

  /// Load saved notification preferences from SharedPreferences
  Future<void> _loadSavedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _remindersEnabled = prefs.getBool(_NotificationPrefsKeys.remindersEnabled) ?? true;
          _dailyRemindersEnabled = prefs.getBool(_NotificationPrefsKeys.dailyRemindersEnabled) ?? true;
          _weeklyRemindersEnabled = prefs.getBool(_NotificationPrefsKeys.weeklyRemindersEnabled) ?? true;
          _soundEnabled = prefs.getBool(_NotificationPrefsKeys.soundEnabled) ?? true;
          _vibrationEnabled = prefs.getBool(_NotificationPrefsKeys.vibrationEnabled) ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      // If loading fails, use defaults and mark as loaded
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Save a notification preference to SharedPreferences
  Future<void> _savePreference(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      // Silently fail - the setting is still applied in memory for this session
    }
  }

  Future<void> _initializeNotificationService() async {
    try {
      await _notificationService.initialize();
    } catch (e) {
      // Show error to user if mounted
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          'فشل تهيئة خدمة الإشعارات',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                _buildHeader(themeColors),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    // In-App Messages
                    const MessageWidget(screenPath: '/notifications'),
                    const SizedBox(height: AppSpacing.md),

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
                        _savePreference(_NotificationPrefsKeys.remindersEnabled, value);
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
                        _savePreference(_NotificationPrefsKeys.dailyRemindersEnabled, value);
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
                        _savePreference(_NotificationPrefsKeys.weeklyRemindersEnabled, value);
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
                        _savePreference(_NotificationPrefsKeys.soundEnabled, value);
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
                        _savePreference(_NotificationPrefsKeys.vibrationEnabled, value);
                      },
                      themeColors: themeColors,
                    ),

                    const SizedBox(height: AppSpacing.xl),
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

  Widget _buildHeader(dynamic themeColors) {
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
              icon: Icon(Icons.arrow_forward_rounded, color: themeColors.textOnGradient),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إعدادات الإشعارات',
                  style: AppTypography.headlineMedium.copyWith(
                    color: themeColors.textOnGradient,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تخصيص التذكيرات والإشعارات',
                  style: AppTypography.bodySmall.copyWith(
                    color: themeColors.textOnGradient.withValues(alpha: 0.8),
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
                        : Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: enabled
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeTrackColor: themeColors.primary,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.1, end: 0);
  }
}
