import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/app_logger_service.dart';
import 'env/app_environment.dart';

/// Supabase configuration and initialization for Silni app
///
/// Supports both staging and production environments
/// Handles web and mobile platforms with appropriate settings
class SupabaseConfig {
  SupabaseConfig._();

  static bool _initialized = false;

  /// Initialize Supabase with environment-specific configuration
  ///
  /// Reads APP_ENV from .env to determine which credentials to use:
  /// - 'staging' → Uses SUPABASE_STAGING_* credentials
  /// - 'production' → Uses SUPABASE_PRODUCTION_* credentials
  ///
  /// For web: Configures for optimal web performance
  /// For mobile: Enables offline persistence and local storage
  static Future<void> initialize() async {
    final logger = AppLoggerService();

    if (_initialized) {
      logger.warning(
        'Supabase already initialized, skipping',
        category: LogCategory.service,
        tag: 'SupabaseConfig',
      );
      return;
    }

    try {
      logger.info(
        'Initializing Supabase',
        category: LogCategory.service,
        tag: 'SupabaseConfig',
      );

      // Get environment from AppEnvironment (handles dart-define priority)
      final environment = AppEnvironment.currentEnvironment;
      final isProduction = AppEnvironment.isProduction;

      logger.info(
        'Environment determined',
        category: LogCategory.service,
        tag: 'SupabaseConfig',
        metadata: {'environment': environment, 'isProduction': isProduction},
      );

      // Get credentials from AppEnvironment (type-safe, compile-time)
      final supabaseUrl = AppEnvironment.supabaseUrl;
      final supabaseAnonKey = AppEnvironment.supabaseAnonKey;

      // Validate credentials
      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        logger.error(
          'Credential validation failed',
          category: LogCategory.service,
          tag: 'SupabaseConfig',
          metadata: {
            'urlEmpty': supabaseUrl.isEmpty,
            'keyEmpty': supabaseAnonKey.isEmpty,
            'environment': environment,
          },
        );
        throw Exception(
          'Missing Supabase credentials for environment: $environment. '
          'Run: flutter pub run build_runner build --delete-conflicting-outputs',
        );
      }

      // Show partial URL for debugging without exposing full endpoint
      final urlPreview = supabaseUrl.length > 20
          ? '${supabaseUrl.substring(0, 10)}...${supabaseUrl.substring(supabaseUrl.length - 10)}'
          : supabaseUrl;
      final keyPreview = supabaseAnonKey.length > 20
          ? '${supabaseAnonKey.substring(0, 10)}...${supabaseAnonKey.substring(supabaseAnonKey.length - 10)}'
          : '(hidden)';

      logger.info(
        'Credentials validated',
        category: LogCategory.service,
        tag: 'SupabaseConfig',
        metadata: {'urlPreview': urlPreview, 'keyPreview': keyPreview},
      );
      logger.debug(
        'Starting Supabase.initialize()...',
        category: LogCategory.service,
        tag: 'SupabaseConfig',
      );

      // Initialize Supabase with platform-specific options
      // NOTE: Using AuthFlowType.implicit for email/password auth
      // PKCE is designed for OAuth redirect flows and can cause session issues on iOS
      logger.debug(
        'Configuring Supabase auth options...',
        category: LogCategory.service,
        tag: 'SupabaseConfig',
        metadata: {
          'isWeb': kIsWeb,
          'authFlowType': kIsWeb ? 'pkce' : 'implicit',
          'platform': kIsWeb ? 'web' : Platform.operatingSystem,
        },
      );

      final authOptions = FlutterAuthClientOptions(
        authFlowType: kIsWeb
            ? AuthFlowType.pkce
            : AuthFlowType.implicit, // Use PKCE for web, implicit for mobile
        autoRefreshToken: true,
        // NOTE: Removed pkceAsyncStorage - not needed for implicit flow
      );

      logger.debug(
        'Final auth options configured',
        category: LogCategory.service,
        tag: 'SupabaseConfig',
        metadata: {
          'authFlowType': authOptions.authFlowType.toString(),
          'autoRefreshToken': authOptions.autoRefreshToken,
        },
      );

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: kDebugMode,
        authOptions: authOptions,
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: kDebugMode ? RealtimeLogLevel.info : RealtimeLogLevel.error,
        ),
        storageOptions: const StorageClientOptions(
          retryAttempts: 3, // Retry failed uploads
        ),
      );

      // Verify storage is working on iOS (session persistence)
      if (!kIsWeb && Platform.isIOS) {
        try {
          logger.debug(
            'Verifying iOS storage...',
            category: LogCategory.service,
            tag: 'SupabaseConfig',
          );

          final prefs = await SharedPreferences.getInstance();
          final testKey =
              '_supabase_storage_test_${DateTime.now().millisecondsSinceEpoch}';
          await prefs.setString(testKey, 'test_value');
          final retrieved = prefs.getString(testKey);
          await prefs.remove(testKey);

          logger.info(
            'iOS storage verification',
            category: LogCategory.service,
            tag: 'SupabaseConfig',
            metadata: {
              'storage_write': true,
              'storage_read': retrieved == 'test_value',
              'storage_delete': true,
            },
          );

          if (retrieved != 'test_value') {
            throw Exception(
              'iOS storage verification failed - could not read back test value',
            );
          }

          logger.info(
            'iOS storage verified successfully',
            category: LogCategory.service,
            tag: 'SupabaseConfig',
          );
        } catch (e, stackTrace) {
          logger.error(
            'Storage verification failed',
            category: LogCategory.service,
            tag: 'SupabaseConfig',
            metadata: {'error': e.toString()},
            stackTrace: stackTrace,
          );

          // Send to Sentry for remote debugging
          await Sentry.captureException(
            e,
            stackTrace: stackTrace,
            hint: Hint.withMap({
              'context': 'ios_storage_verification',
              'platform': kIsWeb ? 'web' : Platform.operatingSystem,
              'os_version': kIsWeb ? 'web' : Platform.operatingSystemVersion,
            }),
          );

          // Don't throw - allow app to continue but log the issue
          logger.warning(
            'Continuing despite storage verification failure',
            category: LogCategory.service,
            tag: 'SupabaseConfig',
          );
        }
      }

      _initialized = true;

      logger.info(
        'Supabase initialized successfully',
        category: LogCategory.service,
        tag: 'SupabaseConfig',
        metadata: {
          'url': supabaseUrl,
          'authFlow': kIsWeb ? 'PKCE' : 'implicit',
          'sessionPersistence': kIsWeb ? 'Web Storage' : 'Enabled',
        },
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to initialize Supabase',
        category: LogCategory.service,
        tag: 'SupabaseConfig',
        metadata: {'error': e.toString()},
        stackTrace: stackTrace,
      );

      // Re-throw with user-friendly message
      // This prevents the app from continuing with an uninitialized Supabase instance
      throw Exception(
        'فشل الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.\n\n'
        'Failed to connect to server. Please check your internet connection and try again.\n\n'
        'Technical details: $e',
      );
    }
  }

  /// Get the Supabase client instance
  ///
  /// Throws an exception if Supabase is not initialized
  static SupabaseClient get client {
    if (!_initialized) {
      throw Exception(
        'Supabase not initialized. Call SupabaseConfig.initialize() first.',
      );
    }
    return Supabase.instance.client;
  }

  /// Convenience getter for checking initialization status
  static bool get isInitialized => _initialized;

  /// Get current user (if authenticated)
  static User? get currentUser => client.auth.currentUser;

  /// Get current user ID (if authenticated)
  static String? get currentUserId => currentUser?.id;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Get auth state stream for listening to authentication changes
  static Stream<AuthState> get authStateStream => client.auth.onAuthStateChange;
}
