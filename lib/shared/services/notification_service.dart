import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

/// Service for handling Firebase Cloud Messaging notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  final StreamController<RemoteMessage> _messageStreamController =
      StreamController<RemoteMessage>.broadcast();

  Stream<RemoteMessage> get onMessageReceived => _messageStreamController.stream;

  /// Initialize notification service
  Future<void> initialize() async {
    try {
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

      // Listen to token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        if (kDebugMode) {
          print('🔔 [NOTIFICATIONS] FCM Token refreshed: $newToken');
        }
        // TODO: Save token to Firestore for this user
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

  /// Handle notification tap navigation
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;

    if (kDebugMode) {
      print('🔔 [NOTIFICATIONS] Handling notification tap with data: $data');
    }

    // Navigate based on notification type
    final type = data['type'];
    final relativeId = data['relativeId'];

    // TODO: Implement navigation based on type
    // Example: Navigator.pushNamed(context, '/relative/$relativeId');
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

      // Note: For actual scheduling, you would need flutter_local_notifications with timezone support
      // This is a simplified version
      if (kDebugMode) {
        print('🔔 [NOTIFICATIONS] Scheduled notification for $scheduledTime');
      }

      // TODO: Implement actual scheduling with timezone support
      // await _localNotifications.zonedSchedule(
      //   id,
      //   title,
      //   body,
      //   tz.TZDateTime.from(scheduledTime, tz.local),
      //   details,
      //   androidAllowWhileIdle: true,
      //   uiLocalNotificationDateInterpretation:
      //       UILocalNotificationDateInterpretation.absoluteTime,
      //   payload: payload,
      // );
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
