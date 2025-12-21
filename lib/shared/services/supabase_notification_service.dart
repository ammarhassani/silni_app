import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../core/config/supabase_config.dart';
import '../../core/errors/app_errors.dart';
import '../../core/router/navigation_service.dart';
import '../../core/router/app_routes.dart';
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
      tz.setLocalLocation(
        tz.getLocation('Asia/Riyadh'),
      ); // Default to Saudi Arabia timezone

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get or generate device ID for this device
      _deviceId = await _getOrCreateDeviceId();

      // Subscribe to Supabase realtime notifications
      await _subscribeToNotifications();

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [NOTIFICATIONS] Error initializing: $e');
      }
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
  Future<String> _getOrCreateDeviceId() async {
    // For now, use a simple UUID. In a real app, you might want to
    // use device-specific identifiers or store in secure storage
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
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
      if (kDebugMode) {
        print('❌ [NOTIFICATIONS] Error subscribing: $e');
      }
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
      if (kDebugMode) {
        print('❌ [NOTIFICATIONS] Error showing notification: $e');
      }
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
      if (kDebugMode) {
        print('❌ [NOTIFICATIONS] Error handling tap: $e');
      }
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
      if (kDebugMode) {
        print('❌ [NOTIFICATIONS] Error scheduling: $e');
      }
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
      if (kDebugMode) {
        print('❌ [NOTIFICATIONS] Error showing immediate: $e');
      }
    }
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
