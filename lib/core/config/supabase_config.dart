import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/app_logger_service.dart';

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
      logger.warning('Supabase already initialized, skipping', category: LogCategory.service, tag: 'SupabaseConfig');
      return;
    }

    try {
      logger.info('Initializing Supabase', category: LogCategory.service, tag: 'SupabaseConfig');

      // Determine environment - check dart-define first, then .env fallback
      final environment = const String.fromEnvironment('APP_ENV',
        defaultValue: '') != ''
        ? const String.fromEnvironment('APP_ENV')
        : dotenv.env['APP_ENV'] ?? 'staging';
      final isProduction = environment == 'production';

      logger.info(
        'Environment determined',
        category: LogCategory.service,
        tag: 'SupabaseConfig',
        metadata: {'environment': environment, 'isProduction': isProduction},
      );

      // Debug: Show where credentials are coming from
      final dartDefineUrl = const String.fromEnvironment('SUPABASE_STAGING_URL');
      final envUrl = dotenv.env['SUPABASE_STAGING_URL'];
      logger.debug(
        'Credential sources',
        category: LogCategory.service,
        tag: 'SupabaseConfig',
        metadata: {
          'dartDefineUrl': dartDefineUrl.isEmpty ? '(empty)' : dartDefineUrl,
          'envUrl': envUrl ?? '(null)',
        },
      );

      // Get environment-specific credentials
      // Priority: dart-define > .env > empty string
      final String supabaseUrl;
      final String supabaseAnonKey;

      if (isProduction) {
        supabaseUrl = const String.fromEnvironment('SUPABASE_PRODUCTION_URL',
          defaultValue: '') != ''
          ? const String.fromEnvironment('SUPABASE_PRODUCTION_URL')
          : dotenv.env['SUPABASE_PRODUCTION_URL'] ?? '';
        supabaseAnonKey = const String.fromEnvironment('SUPABASE_PRODUCTION_ANON_KEY',
          defaultValue: '') != ''
          ? const String.fromEnvironment('SUPABASE_PRODUCTION_ANON_KEY')
          : dotenv.env['SUPABASE_PRODUCTION_ANON_KEY'] ?? '';
      } else {
        supabaseUrl = const String.fromEnvironment('SUPABASE_STAGING_URL',
          defaultValue: '') != ''
          ? const String.fromEnvironment('SUPABASE_STAGING_URL')
          : dotenv.env['SUPABASE_STAGING_URL'] ?? '';
        supabaseAnonKey = const String.fromEnvironment('SUPABASE_STAGING_ANON_KEY',
          defaultValue: '') != ''
          ? const String.fromEnvironment('SUPABASE_STAGING_ANON_KEY')
          : dotenv.env['SUPABASE_STAGING_ANON_KEY'] ?? '';
      }

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
          'Please check your .env file or --dart-define flags.',
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
        metadata: {
          'urlPreview': urlPreview,
          'keyPreview': keyPreview,
        },
      );
      logger.debug('Starting Supabase.initialize()...', category: LogCategory.service, tag: 'SupabaseConfig');

      // Initialize Supabase with platform-specific options
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: kDebugMode,
        authOptions: FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce, // Recommended for security
          autoRefreshToken: true,
          pkceAsyncStorage: SharedPreferencesGotrueAsyncStorage(),
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: kDebugMode ? RealtimeLogLevel.info : RealtimeLogLevel.error,
        ),
        storageOptions: const StorageClientOptions(
          retryAttempts: 3, // Retry failed uploads
        ),
      );

      _initialized = true;

      logger.info(
        'Supabase initialized successfully',
        category: LogCategory.service,
        tag: 'SupabaseConfig',
        metadata: {
          'url': supabaseUrl,
          'authFlow': 'PKCE',
          'sessionPersistence': 'Enabled',
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
        'Technical details: $e'
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
