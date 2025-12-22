import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/router/navigation_service.dart';
import '../../core/router/app_routes.dart';
import '../../core/services/app_logger_service.dart';

/// Top-level background message handler for FCM
/// Must be a top-level function for Firebase to call it
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in background isolate
  await Firebase.initializeApp();

  // Show notification when app is in background
  final notification = message.notification;
  if (notification != null) {
    final localNotifications = FlutterLocalNotificationsPlugin();

    // Initialize with minimal settings for background
    await localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    const androidDetails = AndroidNotificationDetails(
      'silni_channel',
      'Silni Notifications',
      channelDescription: 'Notifications for Silni app',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('silni_default'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'silni_default.wav',
    );

    // Use unique ID combining timestamp and random to prevent notification collisions
    final uniqueId = DateTime.now().millisecondsSinceEpoch % 100000 + Random().nextInt(1000);

    // Encode data payload for navigation when notification is tapped
    final payload = message.data.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    await localNotifications.show(
      uniqueId,
      notification.title ?? 'تذكير',
      notification.body ?? 'لديك إشعار جديد',
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload, // Enable navigation on tap
    );
  }
}

/// Service for handling Firebase Cloud Messaging push notifications
class FCMNotificationService {
  static final FCMNotificationService _instance = FCMNotificationService._internal();
  factory FCMNotificationService() => _instance;
  FCMNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final SupabaseClient _supabase = SupabaseConfig.client;
  final AppLoggerService _logger = AppLoggerService();

  bool _isInitialized = false;
  String? _fcmToken;

  // Stream subscriptions for cleanup
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _backgroundTapSubscription;

  final StreamController<RemoteMessage> _messageStreamController =
      StreamController<RemoteMessage>.broadcast();

  Stream<RemoteMessage> get onMessageReceived => _messageStreamController.stream;

  /// Initialize FCM notification service
  Future<void> initialize() async {
    try {
      if (_isInitialized) {
        _logger.debug(
          'FCM service already initialized',
          category: LogCategory.service,
          tag: 'FCM',
        );
        return;
      }

      _logger.info(
        'Starting FCM notification service...',
        category: LogCategory.service,
        tag: 'FCM',
      );

      // Initialize local notifications for foreground display
      await _initializeLocalNotifications();

      // Request notification permissions
      await _requestPermissions();

      // Get and store FCM token
      await _initializeFCMToken();

      // Set up message handlers
      _setupMessageHandlers();

      _isInitialized = true;

      _logger.info(
        'FCM notification service initialized successfully',
        category: LogCategory.service,
        tag: 'FCM',
        metadata: {'fcmToken': _fcmToken},
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error initializing FCM service',
        category: LogCategory.service,
        tag: 'FCM',
        stackTrace: stackTrace,
      );
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
        _logger.debug(
          'Local notification tapped',
          category: LogCategory.service,
          tag: 'FCM',
          metadata: {'payload': response.payload},
        );
        _handleNotificationTap(response.payload);
      },
    );

    // Create Android notification channel with custom sound
    const androidChannel = AndroidNotificationChannel(
      'silni_channel',
      'Silni Notifications',
      description: 'Notifications for Silni app',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('silni_default'),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _logger.debug(
      'Local notifications initialized',
      category: LogCategory.service,
      tag: 'FCM',
    );
  }

  /// Request notification permissions from user
  Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    _logger.info(
      'Notification permissions requested',
      category: LogCategory.service,
      tag: 'FCM',
      metadata: {'status': settings.authorizationStatus.toString()},
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      _logger.warning(
        'User denied notification permissions',
        category: LogCategory.service,
        tag: 'FCM',
      );
    }
  }

  /// Initialize and store FCM token
  Future<void> _initializeFCMToken() async {
    try {
      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();

      if (_fcmToken != null) {
        _logger.info(
          'FCM token obtained',
          category: LogCategory.service,
          tag: 'FCM',
          metadata: {'token': '${_fcmToken!.substring(0, 20)}...'},
        );

        // Store token in Supabase
        await _storeFCMToken(_fcmToken!);

        // Listen for token refresh
        _tokenRefreshSubscription = _firebaseMessaging.onTokenRefresh.listen((newToken) async {
          _logger.info(
            'FCM token refreshed',
            category: LogCategory.service,
            tag: 'FCM',
          );
          _fcmToken = newToken;
          await _storeFCMToken(newToken);
        });
      } else {
        _logger.warning(
          'Failed to obtain FCM token',
          category: LogCategory.service,
          tag: 'FCM',
        );
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Error initializing FCM token',
        category: LogCategory.service,
        tag: 'FCM',
        stackTrace: stackTrace,
      );
    }
  }

  /// Store FCM token in Supabase
  Future<void> _storeFCMToken(String token) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _logger.warning(
          'Cannot store FCM token - no authenticated user',
          category: LogCategory.service,
          tag: 'FCM',
        );
        return;
      }

      // Determine platform
      final platform = defaultTargetPlatform.toString().contains('android')
          ? 'android'
          : defaultTargetPlatform.toString().contains('iOS')
              ? 'ios'
              : 'web';

      // Upsert token in Supabase
      await _supabase.from('notification_tokens').upsert({
        'user_id': userId,
        'fcm_token': token,
        'platform': platform,
        'device_info': {
          'platform': platform,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'fcm_token');

      _logger.info(
        'FCM token stored in Supabase',
        category: LogCategory.database,
        tag: 'FCM',
        metadata: {'userId': userId, 'platform': platform},
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error storing FCM token in Supabase',
        category: LogCategory.database,
        tag: 'FCM',
        stackTrace: stackTrace,
      );
    }
  }

  /// Set up FCM message handlers for different app states
  void _setupMessageHandlers() {
    // Handle foreground messages
    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.info(
        'Foreground FCM message received',
        category: LogCategory.service,
        tag: 'FCM',
        metadata: {
          'title': message.notification?.title,
          'body': message.notification?.body,
          'data': message.data,
        },
      );

      _messageStreamController.add(message);

      // Show local notification when app is in foreground
      _showForegroundNotification(message);
    });

    // Handle notification tap when app is in background
    _backgroundTapSubscription = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logger.info(
        'Background notification tapped',
        category: LogCategory.service,
        tag: 'FCM',
        metadata: {
          'title': message.notification?.title,
          'data': message.data,
        },
      );

      _handleFCMNotificationTap(message);
    });

    // Handle notification tap when app was terminated
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _logger.info(
          'Terminated app opened via notification',
          category: LogCategory.service,
          tag: 'FCM',
          metadata: {
            'title': message.notification?.title,
            'data': message.data,
          },
        );

        _handleFCMNotificationTap(message);
      }
    });
  }

  /// Show notification when app is in foreground
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

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
        notification.title ?? 'تذكير',
        notification.body ?? 'لديك إشعار جديد',
        details,
        payload: _encodePayload(message.data),
      );

      _logger.debug(
        'Foreground notification shown',
        category: LogCategory.service,
        tag: 'FCM',
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error showing foreground notification',
        category: LogCategory.service,
        tag: 'FCM',
        stackTrace: stackTrace,
      );
    }
  }

  /// Handle FCM notification tap navigation
  void _handleFCMNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type']?.toString();
    final relativeId = data['relative_id']?.toString();

    _logger.debug(
      'Handling FCM notification tap',
      category: LogCategory.navigation,
      tag: 'FCM',
      metadata: {'type': type, 'relativeId': relativeId},
    );

    // First navigate to home to establish base, then push the target screen
    // This ensures back button works properly
    switch (type) {
      case 'reminder':
        // Navigate to reminders due screen with relative IDs
        final relativeIds = data['relative_ids']?.toString();
        if (relativeIds != null && relativeIds.isNotEmpty) {
          NavigationService.navigateTo(AppRoutes.home);
          Future.delayed(const Duration(milliseconds: 100), () {
            NavigationService.pushTo('${AppRoutes.remindersDue}?ids=$relativeIds');
          });
        } else if (relativeId != null) {
          NavigationService.navigateTo(AppRoutes.home);
          Future.delayed(const Duration(milliseconds: 100), () {
            NavigationService.pushTo('${AppRoutes.remindersDue}?ids=$relativeId');
          });
        } else {
          NavigationService.navigateTo(AppRoutes.home);
          Future.delayed(const Duration(milliseconds: 100), () {
            NavigationService.pushTo(AppRoutes.remindersDue);
          });
        }
        break;

      case 'streak':
        NavigationService.navigateTo(AppRoutes.home);
        Future.delayed(const Duration(milliseconds: 100), () {
          NavigationService.pushTo(AppRoutes.statistics);
        });
        break;

      case 'achievement':
        NavigationService.navigateTo(AppRoutes.home);
        Future.delayed(const Duration(milliseconds: 100), () {
          NavigationService.pushTo(AppRoutes.profile);
        });
        break;

      case 'announcement':
        NavigationService.navigateTo(AppRoutes.home);
        break;

      default:
        _logger.warning(
          'Unknown notification type',
          category: LogCategory.navigation,
          tag: 'FCM',
          metadata: {'type': type},
        );
        NavigationService.navigateTo(AppRoutes.home);
    }
  }

  /// Handle local notification tap (from payload string)
  void _handleNotificationTap(String? payload) {
    if (payload == null) return;

    try {
      final data = _decodePayload(payload);
      final type = data['type']?.toString();
      final relativeId = data['relative_id']?.toString();

      _logger.debug(
        'Handling local notification tap',
        category: LogCategory.navigation,
        tag: 'FCM',
        metadata: {'type': type, 'relativeId': relativeId},
      );

      // First navigate to home to establish base, then push the target screen
      switch (type) {
        case 'reminder':
          // Navigate to reminders due screen with relative IDs
          final relativeIds = data['relative_ids']?.toString();
          if (relativeIds != null && relativeIds.isNotEmpty) {
            NavigationService.navigateTo(AppRoutes.home);
            Future.delayed(const Duration(milliseconds: 100), () {
              NavigationService.pushTo('${AppRoutes.remindersDue}?ids=$relativeIds');
            });
          } else if (relativeId != null) {
            NavigationService.navigateTo(AppRoutes.home);
            Future.delayed(const Duration(milliseconds: 100), () {
              NavigationService.pushTo('${AppRoutes.remindersDue}?ids=$relativeId');
            });
          } else {
            NavigationService.navigateTo(AppRoutes.home);
            Future.delayed(const Duration(milliseconds: 100), () {
              NavigationService.pushTo(AppRoutes.remindersDue);
            });
          }
          break;

        case 'streak':
          NavigationService.navigateTo(AppRoutes.home);
          Future.delayed(const Duration(milliseconds: 100), () {
            NavigationService.pushTo(AppRoutes.statistics);
          });
          break;

        case 'achievement':
          NavigationService.navigateTo(AppRoutes.home);
          Future.delayed(const Duration(milliseconds: 100), () {
            NavigationService.pushTo(AppRoutes.profile);
          });
          break;

        case 'announcement':
          NavigationService.navigateTo(AppRoutes.home);
          break;

        default:
          NavigationService.navigateTo(AppRoutes.home);
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Error handling notification tap',
        category: LogCategory.navigation,
        tag: 'FCM',
        stackTrace: stackTrace,
      );
    }
  }

  /// Encode notification data to string payload
  String _encodePayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  /// Decode payload string to map
  Map<String, dynamic> _decodePayload(String payload) {
    final pairs = payload.split('&');
    final map = <String, dynamic>{};

    for (final pair in pairs) {
      final parts = pair.split('=');
      if (parts.length == 2) {
        map[parts[0]] = parts[1];
      }
    }

    return map;
  }

  /// Re-register FCM token after login
  /// Call this after successful authentication to ensure token is stored
  Future<void> registerTokenForCurrentUser() async {
    try {
      if (_fcmToken == null) {
        _logger.warning(
          'No FCM token available to register',
          category: LogCategory.service,
          tag: 'FCM',
        );
        // Try to get a new token
        _fcmToken = await _firebaseMessaging.getToken();
      }

      if (_fcmToken != null) {
        await _storeFCMToken(_fcmToken!);
        _logger.info(
          'FCM token registered for current user',
          category: LogCategory.service,
          tag: 'FCM',
        );
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Error registering FCM token for current user',
        category: LogCategory.service,
        tag: 'FCM',
        stackTrace: stackTrace,
      );
    }
  }

  /// Deactivate FCM token on logout
  Future<void> deactivateToken() async {
    try {
      if (_fcmToken == null) {
        _logger.debug(
          'No FCM token to deactivate',
          category: LogCategory.service,
          tag: 'FCM',
        );
        return;
      }

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _logger.warning(
          'Cannot deactivate FCM token - no authenticated user',
          category: LogCategory.service,
          tag: 'FCM',
        );
        return;
      }

      // Mark token as inactive in Supabase
      await _supabase
          .from('notification_tokens')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('fcm_token', _fcmToken!)
          .eq('user_id', userId);

      _logger.info(
        'FCM token deactivated',
        category: LogCategory.service,
        tag: 'FCM',
        metadata: {'userId': userId},
      );

      // Delete FCM token from device
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;

      _logger.debug(
        'FCM token deleted from device',
        category: LogCategory.service,
        tag: 'FCM',
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error deactivating FCM token',
        category: LogCategory.service,
        tag: 'FCM',
        stackTrace: stackTrace,
      );
    }
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _foregroundMessageSubscription?.cancel();
    _backgroundTapSubscription?.cancel();
    _messageStreamController.close();
  }
}
