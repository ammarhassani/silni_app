import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    if (_initialized) {
      if (kDebugMode) {
        print('⚠️ [SupabaseConfig] Already initialized, skipping...');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('🚀 [SupabaseConfig] Initializing Supabase...');
      }

      // Determine environment - check dart-define first, then .env fallback
      final environment = const String.fromEnvironment('APP_ENV',
        defaultValue: '') != ''
        ? const String.fromEnvironment('APP_ENV')
        : dotenv.env['APP_ENV'] ?? 'staging';
      final isProduction = environment == 'production';

      if (kDebugMode) {
        print('🌍 [SupabaseConfig] Environment: $environment');
      }

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
        throw Exception(
          'Missing Supabase credentials for environment: $environment. '
          'Please check your .env file.',
        );
      }

      // Initialize Supabase with platform-specific options
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: kDebugMode,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce, // Recommended for security
          autoRefreshToken: true,
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: kDebugMode ? RealtimeLogLevel.info : RealtimeLogLevel.error,
        ),
        storageOptions: const StorageClientOptions(
          retryAttempts: 3, // Retry failed uploads
        ),
      );

      _initialized = true;

      if (kDebugMode) {
        print('✅ [SupabaseConfig] Supabase initialized successfully');
        print('🔗 [SupabaseConfig] URL: $supabaseUrl');
        print('🔒 [SupabaseConfig] Auth Flow: PKCE');
        print('💾 [SupabaseConfig] Session Persistence: Enabled');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ [SupabaseConfig] Failed to initialize Supabase');
        print('Error: $e');
        print('Stack trace: $stackTrace');
      }

      // Don't throw - allow app to start but log the error
      // Services will fail gracefully if Supabase is not initialized
      if (kDebugMode) {
        print('⚠️ [SupabaseConfig] App will continue but Supabase features will not work');
      }
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
