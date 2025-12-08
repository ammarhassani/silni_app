import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../core/config/supabase_config.dart';
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
  final StreamController<Map<String, dynamic>> _messageStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onMessageReceived =>
      _messageStreamController.stream;

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      if (kDebugMode) {
        print(
          '🔔 [SUPABASE_NOTIFICATIONS] Starting Supabase notification service...',
        );
      }

      // Initialize timezone data
      tz.initializeTimeZones();
      tz.setLocalLocation(
        tz.getLocation('Asia/Riyadh'),
      ); // Default to Saudi Arabia timezone

      if (kDebugMode) {
        print(
          '🔔 [SUPABASE_NOTIFICATIONS] Timezone initialized: ${tz.local.name}',
        );
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get or generate device ID for this device
      _deviceId = await _getOrCreateDeviceId();

      if (kDebugMode) {
        print('🔔 [SUPABASE_NOTIFICATIONS] Device ID: $_deviceId');
      }

      // Subscribe to Supabase realtime notifications
      await _subscribeToNotifications();

      _isInitialized = true;

      if (kDebugMode) {
        print(
          '✅ [SUPABASE_NOTIFICATIONS] Notification service initialized successfully',
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ [SUPABASE_NOTIFICATIONS] Error initializing: $e');
        print('❌ [SUPABASE_NOTIFICATIONS] Stack trace: $stackTrace');
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
        if (kDebugMode) {
          print(
            '🔔 [SUPABASE_NOTIFICATIONS] Local notification tapped: ${response.payload}',
          );
        }
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
        throw Exception('Device ID not available');
      }

      // Subscribe to notifications for this device
      _supabase
          .channel('notifications:device_id=eq.$_deviceId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            callback: (payload) async {
              final notification = payload.newRecord;
              if (kDebugMode) {
                print(
                  '🔔 [SUPABASE_NOTIFICATIONS] Received notification: $notification',
                );
              }

              _messageStreamController.add(notification);
              await _showLocalNotification(notification);
            },
          )
          .subscribe();

      if (kDebugMode) {
        print(
          '🔔 [SUPABASE_NOTIFICATIONS] Subscribed to realtime notifications',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ [SUPABASE_NOTIFICATIONS] Error subscribing to notifications: $e',
        );
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
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
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

      if (kDebugMode) {
        print('✅ [SUPABASE_NOTIFICATIONS] Local notification shown');
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ [SUPABASE_NOTIFICATIONS] Error showing local notification: $e',
        );
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

      if (kDebugMode) {
        print(
          '🔔 [SUPABASE_NOTIFICATIONS] Handling notification tap with data: $data',
        );
      }

      // Navigate based on notification type
      final type = data['type'];
      final relativeId = data['relativeId'];

      // Delay navigation slightly to ensure app is fully loaded
      Future.delayed(const Duration(milliseconds: 500), () {
        switch (type) {
          case 'reminder':
            // Navigate to relative detail if relativeId is provided
            if (relativeId != null && relativeId.isNotEmpty) {
              NavigationService.navigateTo(
                '${AppRoutes.relativeDetail}/$relativeId',
              );
            } else {
              // Otherwise navigate to reminders screen
              NavigationService.navigateTo(AppRoutes.reminders);
            }
            break;

          case 'relative':
            // Navigate to relative detail
            if (relativeId != null && relativeId.isNotEmpty) {
              NavigationService.navigateTo(
                '${AppRoutes.relativeDetail}/$relativeId',
              );
            }
            break;

          case 'achievement':
            // Navigate to profile/achievements
            NavigationService.navigateTo(AppRoutes.profile);
            break;

          case 'streak':
            // Navigate to statistics screen
            NavigationService.navigateTo(AppRoutes.statistics);
            break;

          default:
            // Navigate to home by default
            NavigationService.navigateTo(AppRoutes.home);
        }

        if (kDebugMode) {
          print(
            '✅ [SUPABASE_NOTIFICATIONS] Navigated to appropriate screen for type: $type',
          );
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SUPABASE_NOTIFICATIONS] Error handling notification tap: $e');
      }
      // Fallback to home screen
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
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Convert DateTime to TZDateTime with local timezone
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      if (kDebugMode) {
        print(
          '🔔 [SUPABASE_NOTIFICATIONS] Scheduling notification for $tzScheduledTime (${tz.local.name})',
        );
      }

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

      if (kDebugMode) {
        print(
          '✅ [SUPABASE_NOTIFICATIONS] Notification scheduled successfully for $tzScheduledTime',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SUPABASE_NOTIFICATIONS] Error scheduling notification: $e');
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
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
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

      if (kDebugMode) {
        print('✅ [SUPABASE_NOTIFICATIONS] Immediate notification shown');
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ [SUPABASE_NOTIFICATIONS] Error showing immediate notification: $e',
        );
      }
    }
  }

  /// Get device ID (for Supabase subscription)
  String? get deviceId => _deviceId;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  void dispose() {
    _messageStreamController.close();
  }
}
