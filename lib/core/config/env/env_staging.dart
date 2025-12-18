import 'package:envied/envied.dart';

part 'env_staging.g.dart';

/// Staging environment Supabase configuration
/// Used when APP_ENV=staging
@Envied(path: '.env', obfuscate: true)
abstract class EnvStaging {
  /// Staging Supabase project URL
  @EnviedField(varName: 'SUPABASE_STAGING_URL')
  static String supabaseUrl = _EnvStaging.supabaseUrl;

  /// Staging Supabase anonymous key (obfuscated in binary)
  @EnviedField(varName: 'SUPABASE_STAGING_ANON_KEY', obfuscate: true)
  static String supabaseAnonKey = _EnvStaging.supabaseAnonKey;
}
