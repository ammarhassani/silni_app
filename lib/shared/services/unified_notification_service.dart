import 'fcm_notification_service.dart';
import 'supabase_notification_service.dart';
import '../../core/services/app_logger_service.dart';

/// Unified notification service that manages both FCM push notifications
/// and local scheduled notifications
class UnifiedNotificationService {
  static final UnifiedNotificationService _instance =
      UnifiedNotificationService._internal();
  factory UnifiedNotificationService() => _instance;
  UnifiedNotificationService._internal();

  final FCMNotificationService _fcmService = FCMNotificationService();
  final SupabaseNotificationService _localService = SupabaseNotificationService();
  final AppLoggerService _logger = AppLoggerService();

  bool _isInitialized = false;

  /// Initialize both notification services
  Future<void> initialize() async {
    try {
      if (_isInitialized) {
        _logger.debug(
          'Unified notification service already initialized',
          category: LogCategory.service,
          tag: 'UnifiedNotifications',
        );
        return;
      }

      _logger.info(
        'Initializing unified notification service...',
        category: LogCategory.service,
        tag: 'UnifiedNotifications',
      );

      // Initialize local notifications service (for scheduled reminders)
      await _localService.initialize();
      _logger.info(
        'Local notification service initialized',
        category: LogCategory.service,
        tag: 'UnifiedNotifications',
      );

      // Initialize FCM service (for server-triggered push notifications)
      await _fcmService.initialize();
      _logger.info(
        'FCM notification service initialized',
        category: LogCategory.service,
        tag: 'UnifiedNotifications',
      );

      _isInitialized = true;

      _logger.info(
        'Unified notification service initialized successfully',
        category: LogCategory.service,
        tag: 'UnifiedNotifications',
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error initializing unified notification service',
        category: LogCategory.service,
        tag: 'UnifiedNotifications',
        stackTrace: stackTrace,
      );
      // Don't rethrow - allow app to continue even if notifications fail
      // User can still use app without notifications
    }
  }

  /// Handle login - register FCM token for user
  Future<void> onLogin() async {
    try {
      _logger.info(
        'Registering FCM token on login',
        category: LogCategory.service,
        tag: 'UnifiedNotifications',
      );

      await _fcmService.registerTokenForCurrentUser();

      _logger.info(
        'FCM token registered successfully',
        category: LogCategory.service,
        tag: 'UnifiedNotifications',
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error registering FCM token on login',
        category: LogCategory.service,
        tag: 'UnifiedNotifications',
        stackTrace: stackTrace,
      );
      // Don't rethrow - login should succeed even if token registration fails
    }
  }

  /// Handle logout - deactivate FCM token
  Future<void> onLogout() async {
    try {
      _logger.info(
        'Deactivating notifications on logout',
        category: LogCategory.service,
        tag: 'UnifiedNotifications',
      );

      await _fcmService.deactivateToken();

      _logger.info(
        'Notifications deactivated successfully',
        category: LogCategory.service,
        tag: 'UnifiedNotifications',
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error deactivating notifications on logout',
        category: LogCategory.service,
        tag: 'UnifiedNotifications',
        stackTrace: stackTrace,
      );
      // Don't rethrow - logout should succeed even if token deactivation fails
    }
  }

  /// Get FCM token
  String? get fcmToken => _fcmService.fcmToken;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get FCM service instance (for advanced usage)
  FCMNotificationService get fcmService => _fcmService;

  /// Get local notification service instance (for advanced usage)
  SupabaseNotificationService get localService => _localService;

  /// Dispose resources
  void dispose() {
    _fcmService.dispose();
  }
}
