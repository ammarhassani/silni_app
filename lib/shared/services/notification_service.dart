import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../core/config/supabase_config.dart';
import '../../core/router/navigation_service.dart';
import '../../core/router/app_routes.dart';
import 'dart:async';

/// Service for handling Firebase Cloud Messaging notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = SupabaseConfig.client;

  String? _fcmToken;
  final StreamController<RemoteMessage> _messageStreamController =
      StreamController<RemoteMessage>.broadcast();

  Stream<RemoteMessage> get onMessageReceived => _messageStreamController.stream;

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      // Initialize timezone data
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Riyadh')); // Default to Saudi Arabia timezone

      if (kDebugMode) {
        print('🔔 [NOTIFICATIONS] Timezone initialized: ${tz.local.name}');
      }

      // Request notification permissions
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('🔔 [NOTIFICATIONS] Permission status: ${settings.authorizationStatus}');
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        print('🔔 [NOTIFICATIONS] FCM Token: $_fcmToken');
      }

      // Save FCM token to Firestore
      if (_fcmToken != null) {
        await _saveFcmToken(_fcmToken!);
      }

      // Listen to token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        if (kDebugMode) {
          print('🔔 [NOTIFICATIONS] FCM Token refreshed: $newToken');
        }
        // Save refreshed token to Firestore
        await _saveFcmToken(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('🔔 [NOTIFICATIONS] Received foreground message: ${message.notification?.title}');
        }
        _messageStreamController.add(message);
        _showLocalNotification(message);
      });

      // Handle notification opened app
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('🔔 [NOTIFICATIONS] App opened from notification: ${message.notification?.title}');
        }
        _handleNotificationTap(message);
      });

      // Check if app was opened from a notification
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) {
          print('🔔 [NOTIFICATIONS] App launched from notification: ${initialMessage.notification?.title}');
        }
        _handleNotificationTap(initialMessage);
      }

      if (kDebugMode) {
        print('✅ [NOTIFICATIONS] Notification service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [NOTIFICATIONS] Error initializing: $e');
      }
      rethrow;
    }
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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
          print('🔔 [NOTIFICATIONS] Local notification tapped: ${response.payload}');
        }
        // Handle notification tap
      },
    );
  }

  /// Show local notification when app is in foreground
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

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
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  /// Save FCM token to Supabase
  Future<void> _saveFcmToken(String token) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Upsert FCM token to Supabase (insert or update)
      await _supabase.from('fcm_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'platform': kIsWeb ? 'web' : 'mobile',
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('🔔 [NOTIFICATIONS] FCM token saved to Supabase');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [NOTIFICATIONS] Error saving FCM token: $e');
      }
    }
  }

  /// Handle notification tap navigation
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;

    if (kDebugMode) {
      print('🔔 [NOTIFICATIONS] Handling notification tap with data: $data');
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
        print('✅ [NOTIFICATIONS] Navigated to appropriate screen for type: $type');
      }
    });
  }

  /// Get FCM token
  String? get fcmToken => _fcmToken;

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('🔔 [NOTIFICATIONS] Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [NOTIFICATIONS] Error subscribing to topic: $e');
      }
      rethrow;
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('🔔 [NOTIFICATIONS] Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [NOTIFICATIONS] Error unsubscribing from topic: $e');
      }
      rethrow;
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
        print('🔔 [NOTIFICATIONS] Scheduling notification for $tzScheduledTime (${tz.local.name})');
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
        print('✅ [NOTIFICATIONS] Notification scheduled successfully for $tzScheduledTime');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [NOTIFICATIONS] Error scheduling notification: $e');
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

  /// Dispose resources
  void dispose() {
    _messageStreamController.close();
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('🔔 [NOTIFICATIONS] Background message: ${message.notification?.title}');
  }
  // Handle background message
}
