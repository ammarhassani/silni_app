import 'package:flutter/foundation.dart';
import 'app_environment.dart';
import '../../services/app_logger_service.dart';

/// Validates required environment variables at app startup
///
/// Ensures all critical configuration is present before the app
/// attempts to connect to external services.
class EnvValidator {
  static final _logger = AppLoggerService();

  /// Validates all required environment variables are present
  ///
  /// Returns true if all required variables are configured.
  /// Throws [EnvironmentValidationException] if validation fails
  /// and [throwOnError] is true (default).
  ///
  /// In debug mode, validation is more lenient to allow development
  /// without full configuration.
  static bool validate({bool throwOnError = true}) {
    final errors = <String>[];

    // Check Supabase configuration (required)
    if (AppEnvironment.supabaseUrl.isEmpty) {
      errors.add('SUPABASE_URL is not configured');
    }
    if (AppEnvironment.supabaseAnonKey.isEmpty) {
      errors.add('SUPABASE_ANON_KEY is not configured');
    }

    // Check Sentry (optional in debug mode)
    if (AppEnvironment.sentryDsn.isEmpty && !kDebugMode) {
      errors.add('SENTRY_DSN is not configured (required for release builds)');
    }

    // Log validation results
    if (errors.isEmpty) {
      _logger.info(
        'Environment validation passed',
        category: LogCategory.lifecycle,
        tag: 'EnvValidator',
        metadata: {
          'environment': AppEnvironment.currentEnvironment,
          'isProduction': AppEnvironment.isProduction,
          'isTestFlight': AppEnvironment.isTestFlight,
        },
      );
      return true;
    }

    // Log errors
    _logger.error(
      'Environment validation FAILED',
      category: LogCategory.lifecycle,
      tag: 'EnvValidator',
      metadata: {
        'errors': errors,
        'errorCount': errors.length,
      },
    );

    if (throwOnError) {
      throw EnvironmentValidationException(errors);
    }

    return false;
  }

  /// Logs current configuration (without sensitive values)
  ///
  /// Useful for debugging and verifying the correct environment
  /// is being used.
  static void logConfiguration() {
    _logger.info(
      'Environment Configuration',
      category: LogCategory.lifecycle,
      tag: 'EnvValidator',
      metadata: {
        'appEnv': AppEnvironment.currentEnvironment,
        'sentryEnv': AppEnvironment.sentryEnvironment,
        'isProduction': AppEnvironment.isProduction,
        'isTestFlight': AppEnvironment.isTestFlight,
        'supabaseUrlConfigured': AppEnvironment.supabaseUrl.isNotEmpty,
        'supabaseKeyConfigured': AppEnvironment.supabaseAnonKey.isNotEmpty,
        'sentryConfigured': AppEnvironment.sentryDsn.isNotEmpty,
        'supabaseUrlPreview': _maskUrl(AppEnvironment.supabaseUrl),
      },
    );
  }

  /// Masks a URL for safe logging (shows only domain hint)
  static String _maskUrl(String url) {
    if (url.isEmpty) return '(empty)';
    if (url.length < 20) return '***';
    // Show first 15 chars and last 10 to identify the project
    return '${url.substring(0, 15)}...${url.substring(url.length - 10)}';
  }
}

/// Exception thrown when environment validation fails
class EnvironmentValidationException implements Exception {
  final List<String> errors;

  EnvironmentValidationException(this.errors);

  @override
  String toString() {
    return '''
EnvironmentValidationException: Missing required configuration

${errors.map((e) => '  - $e').join('\n')}

To fix this issue:
1. Ensure your .env file exists and contains all required variables
2. Run: flutter pub run build_runner build --delete-conflicting-outputs
3. If using CI/CD, ensure --dart-define flags are passed correctly

See docs/SECRETS_MANAGEMENT.md for detailed setup instructions.
''';
  }
}
