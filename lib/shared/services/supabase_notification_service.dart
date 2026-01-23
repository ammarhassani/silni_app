import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';
import '../../core/config/supabase_config.dart';
import '../../core/errors/app_errors.dart';
import '../../core/router/navigation_service.dart';
import '../../core/router/app_routes.dart';
import '../../core/services/notification_config_service.dart';
import 'dart:async';

/// Service for handling notifications using Supabase Realtime instead of Firebase
class SupabaseNotificationService {
  static final SupabaseNotificationService _instance =
      SupabaseNotificationService._internal();
  factory SupabaseNotificationService() => _instance;
  SupabaseNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = SupabaseConfig.client;

  String? _deviceId;
  bool _isInitialized = false;
  RealtimeChannel? _notificationsChannel;
  final StreamController<Map<String, dynamic>> _messageStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onMessageReceived =>
      _messageStreamController.stream;

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      // Initialize timezone data
      tz.initializeTimeZones();

      // Try to detect device timezone, fallback to UTC
      try {
        // Detect timezone based on device's UTC offset
        final offset = DateTime.now().timeZoneOffset;
        final String tzName;

        // Map common offsets to timezone IDs
        if (offset.inHours == 3) {
          tzName = 'Asia/Riyadh'; // UTC+3 (Saudi Arabia, etc.)
        } else if (offset.inHours == 4) {
          tzName = 'Asia/Dubai'; // UTC+4 (UAE, etc.)
        } else if (offset.inHours == 2) {
          tzName = 'Africa/Cairo'; // UTC+2 (Egypt, etc.)
        } else if (offset.inHours == 0) {
          tzName = 'UTC';
        } else if (offset.inHours == -5) {
          tzName = 'America/New_York'; // UTC-5 (EST)
        } else if (offset.inHours == -8) {
          tzName = 'America/Los_Angeles'; // UTC-8 (PST)
        } else {
          // Default to UTC for unknown timezones
          tzName = 'UTC';
        }

        tz.setLocalLocation(tz.getLocation(tzName));
      } catch (_) {
        // If timezone detection fails, use UTC as safe fallback
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get or generate device ID for this device
      _deviceId = await _getOrCreateDeviceId();

      // Subscribe to Supabase realtime notifications
      await _subscribeToNotifications();

      _isInitialized = true;
    } catch (e) {
      rethrow;
    }
  }

  /// Initialize local notifications for display
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );
  }

  /// Get or create a unique device ID
  /// Uses secure storage to persist the device ID across app restarts
  Future<String> _getOrCreateDeviceId() async {
    try {
      const storage = FlutterSecureStorage();
      const deviceIdKey = 'device_unique_id';

      // Try to get existing device ID from secure storage
      String? existingDeviceId = await storage.read(key: deviceIdKey);

      if (existingDeviceId != null && existingDeviceId.isNotEmpty) {
        return existingDeviceId;
      }

      // Generate a new UUID and store it
      final newDeviceId = 'device_${const Uuid().v4()}';
      await storage.write(key: deviceIdKey, value: newDeviceId);

      return newDeviceId;
    } catch (e) {
      // Fallback to in-memory UUID if secure storage fails
      // This allows notifications to still function even if storage access fails
      return 'device_${const Uuid().v4()}';
    }
  }

  /// Subscribe to Supabase realtime notifications
  Future<void> _subscribeToNotifications() async {
    try {
      if (_deviceId == null) {
        throw const ConfigurationError(
          message: 'Device ID not available',
          arabicMessage: 'معرف الجهاز غير متوفر',
          component: 'NotificationService',
        );
      }

      // Subscribe to notifications for this device
      _notificationsChannel = _supabase
          .channel('notifications:device_id=eq.$_deviceId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            callback: (payload) async {
              final notification = payload.newRecord;
              _messageStreamController.add(notification);
              await _showLocalNotification(notification);
            },
          );
      _notificationsChannel!.subscribe();
    } catch (e) {
      rethrow;
    }
  }

  /// Show local notification when app is in foreground
  Future<void> _showLocalNotification(Map<String, dynamic> notification) async {
    try {
      final title = notification['title']?.toString() ?? 'تذكير';
      final body = notification['body']?.toString() ?? 'لديك تذكير جديد';

      const androidDetails = AndroidNotificationDetails(
        'silni_channel',
        'Silni Notifications',
        channelDescription: 'Notifications for Silni app',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        sound: RawResourceAndroidNotificationSound('silni_default'),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'silni_default.wav',
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        notification.hashCode,
        title,
        body,
        details,
        payload: notification.toString(),
      );
    } catch (e) {
      // Silently fail - notification display is not critical
    }
  }

  /// Handle notification tap navigation
  void _handleNotificationTap(String? payload) {
    if (payload == null) return;

    try {
      final data = Map<String, dynamic>.from(
        // Parse the payload string back to a map
        payload
            .split(',')
            .map((e) => e.split(':'))
            .where((e) => e.length == 2)
            .fold(
              {},
              (map, e) => {
                ...map,
                e[0].trim(): e[1].trim().replaceAll(RegExp(r'[{}"]'), ''),
              },
            ),
      );

      // Navigate based on notification type
      final type = data['type'];
      final relativeId = data['relativeId'];

      // Delay navigation slightly to ensure app is fully loaded
      Future.delayed(const Duration(milliseconds: 500), () {
        switch (type) {
          case 'reminder':
            if (relativeId != null && relativeId.isNotEmpty) {
              NavigationService.navigateTo(
                '${AppRoutes.relativeDetail}/$relativeId',
              );
            } else {
              NavigationService.navigateTo(AppRoutes.reminders);
            }
            break;

          case 'relative':
            if (relativeId != null && relativeId.isNotEmpty) {
              NavigationService.navigateTo(
                '${AppRoutes.relativeDetail}/$relativeId',
              );
            }
            break;

          case 'achievement':
            NavigationService.navigateTo(AppRoutes.profile);
            break;

          case 'streak':
            NavigationService.navigateTo(AppRoutes.statistics);
            break;

          default:
            NavigationService.navigateTo(AppRoutes.home);
        }
      });
    } catch (e) {
      NavigationService.navigateTo(AppRoutes.home);
    }
  }

  /// Schedule reminder notification (local notification)
  Future<void> scheduleReminderNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'reminders_channel',
        'Reminders',
        channelDescription: 'Reminders to contact relatives',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound('silni_default'),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'silni_default.wav',
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Convert DateTime to TZDateTime with local timezone
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      // Schedule the notification with timezone support
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel scheduled notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Show immediate notification (for testing without scheduling)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'silni_channel',
        'Silni Notifications',
        channelDescription: 'Notifications for Silni app',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        sound: RawResourceAndroidNotificationSound('silni_default'),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'silni_default.wav',
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().hashCode,
        title,
        body,
        details,
        payload: 'immediate_notification',
      );
    } catch (e) {
      // Silently fail - notification display is not critical
    }
  }

  /// Show notification using admin-configured template
  /// This uses the NotificationConfigService to get dynamic templates.
  ///
  /// Example usage:
  /// ```dart
  /// await showTemplatedNotification(
  ///   templateKey: 'reminder_due',
  ///   variables: {'relative_name': 'أحمد'},
  /// );
  /// ```
  Future<void> showTemplatedNotification({
    required String templateKey,
    Map<String, String> variables = const {},
    String? payload,
  }) async {
    try {
      // Get notification content from template
      final content = NotificationConfigService.instance.buildNotification(
        templateKey,
        variables,
      );

      if (content == null) {
        // Template not found - use fallback
        await showImmediateNotification(
          title: 'تنبيه',
          body: 'لديك إشعار جديد',
        );
        return;
      }

      // Determine notification details based on priority
      final androidDetails = AndroidNotificationDetails(
        'silni_channel',
        'Silni Notifications',
        channelDescription: 'Notifications for Silni app',
        importance: content.priority == 'high' ? Importance.high : Importance.defaultImportance,
        priority: content.priority == 'high' ? Priority.high : Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        sound: content.sound == 'celebration'
            ? const RawResourceAndroidNotificationSound('silni_celebration')
            : const RawResourceAndroidNotificationSound('silni_default'),
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: content.sound == 'celebration' ? 'silni_celebration.wav' : 'silni_default.wav',
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().hashCode,
        content.title,
        content.body,
        details,
        payload: payload ?? 'template:$templateKey',
      );
    } catch (e) {
      // Silently fail - notification display is not critical
    }
  }

  /// Schedule a reminder notification using admin-configured template
  Future<void> scheduleTemplatedReminder({
    required int id,
    required String templateKey,
    required DateTime scheduledTime,
    Map<String, String> variables = const {},
    String? payload,
  }) async {
    // Get notification content from template
    final content = NotificationConfigService.instance.buildNotification(
      templateKey,
      variables,
    );

    final title = content?.title ?? 'تذكير';
    final body = content?.body ?? 'لديك تذكير';

    await scheduleReminderNotification(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      payload: payload,
    );
  }

  /// Get device ID (for Supabase subscription)
  String? get deviceId => _deviceId;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  void dispose() {
    if (_notificationsChannel != null) {
      _supabase.removeChannel(_notificationsChannel!);
    }
    _messageStreamController.close();
  }
}
