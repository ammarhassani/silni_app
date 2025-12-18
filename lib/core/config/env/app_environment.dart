import 'env.dart';
import 'env_staging.dart';
import 'env_production.dart';
import 'env_services.dart';
import 'env_firebase.dart';

/// Unified environment configuration accessor
///
/// Provides a single access point for all environment variables.
/// Automatically selects staging or production based on APP_ENV.
/// Supports dart-define overrides for CI/CD builds.
class AppEnvironment {
  AppEnvironment._();

  // ===========================================
  // ENVIRONMENT FLAGS
  // ===========================================

  /// Current environment name ('staging' or 'production')
  static String get currentEnvironment {
    // Check dart-define first (for CI/CD)
    const dartDefine = String.fromEnvironment('APP_ENV', defaultValue: '');
    if (dartDefine.isNotEmpty) return dartDefine;
    return Env.appEnv;
  }

  /// Sentry environment ('development', 'staging', or 'production')
  static String get sentryEnvironment {
    const dartDefine = String.fromEnvironment('ENVIRONMENT', defaultValue: '');
    if (dartDefine.isNotEmpty) return dartDefine;
    return Env.environment;
  }

  /// Whether this is a TestFlight build
  static bool get isTestFlight {
    const dartDefine = String.fromEnvironment('IS_TESTFLIGHT', defaultValue: '');
    if (dartDefine.isNotEmpty) return dartDefine.toLowerCase() == 'true';
    return Env.isTestFlight.toLowerCase() == 'true';
  }

  /// Whether running in production mode
  static bool get isProduction => currentEnvironment == 'production';

  /// Whether running in staging mode
  static bool get isStaging => currentEnvironment == 'staging';

  // ===========================================
  // SUPABASE CONFIGURATION
  // ===========================================

  /// Get Supabase URL for current environment
  static String get supabaseUrl {
    // Check dart-define first (for CI/CD)
    const dartDefine = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    if (dartDefine.isNotEmpty) return dartDefine;

    // Check environment-specific dart-define
    if (isProduction) {
      const prodDartDefine = String.fromEnvironment(
        'SUPABASE_PRODUCTION_URL',
        defaultValue: '',
      );
      if (prodDartDefine.isNotEmpty) return prodDartDefine;
    } else {
      const stagingDartDefine = String.fromEnvironment(
        'SUPABASE_STAGING_URL',
        defaultValue: '',
      );
      if (stagingDartDefine.isNotEmpty) return stagingDartDefine;
    }

    // Fall back to envied-generated config
    return isProduction ? EnvProduction.supabaseUrl : EnvStaging.supabaseUrl;
  }

  /// Get Supabase Anon Key for current environment
  static String get supabaseAnonKey {
    // Check dart-define first (for CI/CD)
    const dartDefine = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: '',
    );
    if (dartDefine.isNotEmpty) return dartDefine;

    // Check environment-specific dart-define
    if (isProduction) {
      const prodDartDefine = String.fromEnvironment(
        'SUPABASE_PRODUCTION_ANON_KEY',
        defaultValue: '',
      );
      if (prodDartDefine.isNotEmpty) return prodDartDefine;
    } else {
      const stagingDartDefine = String.fromEnvironment(
        'SUPABASE_STAGING_ANON_KEY',
        defaultValue: '',
      );
      if (stagingDartDefine.isNotEmpty) return stagingDartDefine;
    }

    // Fall back to envied-generated config
    return isProduction
        ? EnvProduction.supabaseAnonKey
        : EnvStaging.supabaseAnonKey;
  }

  // ===========================================
  // SERVICE CONFIGURATION
  // ===========================================

  /// Sentry DSN for error tracking
  static String get sentryDsn {
    const dartDefine = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
    if (dartDefine.isNotEmpty) return dartDefine;
    return EnvServices.sentryDsn;
  }

  /// Cloudinary cloud name
  static String get cloudinaryCloudName => EnvServices.cloudinaryCloudName;

  /// Cloudinary API key
  static String get cloudinaryApiKey => EnvServices.cloudinaryApiKey;

  /// Cloudinary API secret
  static String get cloudinaryApiSecret => EnvServices.cloudinaryApiSecret;

  /// Cloudinary upload preset
  static String get cloudinaryUploadPreset => EnvServices.cloudinaryUploadPreset;

  // ===========================================
  // FIREBASE WEB (LEGACY)
  // ===========================================

  /// Firebase Web API key
  static String get firebaseApiKey => EnvFirebase.apiKey;

  /// Firebase Auth domain
  static String get firebaseAuthDomain => EnvFirebase.authDomain;

  /// Firebase project ID
  static String get firebaseProjectId => EnvFirebase.projectId;

  /// Firebase storage bucket
  static String get firebaseStorageBucket => EnvFirebase.storageBucket;

  /// Firebase messaging sender ID
  static String get firebaseMessagingSenderId => EnvFirebase.messagingSenderId;

  /// Firebase app ID
  static String get firebaseAppId => EnvFirebase.appId;

  /// Firebase measurement ID
  static String get firebaseMeasurementId => EnvFirebase.measurementId;
}
