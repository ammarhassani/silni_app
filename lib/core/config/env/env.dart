import 'package:envied/envied.dart';

part 'env.g.dart';

/// Base environment configuration
/// Controls which environment (staging/production) the app connects to
@Envied(path: '.env')
abstract class Env {
  /// App environment: 'staging' or 'production'
  /// Determines which Supabase instance to connect to
  @EnviedField(varName: 'APP_ENV', defaultValue: 'staging')
  static String appEnv = _Env.appEnv;

  /// Sentry environment: 'development', 'staging', or 'production'
  /// Used for error tracking categorization
  @EnviedField(varName: 'ENVIRONMENT', defaultValue: 'development')
  static String environment = _Env.environment;

  /// TestFlight build flag: 'true' or 'false'
  /// Enables remote error logging for TestFlight builds
  @EnviedField(varName: 'IS_TESTFLIGHT', defaultValue: 'false')
  static String isTestFlight = _Env.isTestFlight;
}
