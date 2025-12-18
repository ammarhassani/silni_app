import 'package:envied/envied.dart';

part 'env_production.g.dart';

/// Production environment Supabase configuration
/// Used when APP_ENV=production
@Envied(path: '.env', obfuscate: true)
abstract class EnvProduction {
  /// Production Supabase project URL
  @EnviedField(varName: 'SUPABASE_PRODUCTION_URL')
  static String supabaseUrl = _EnvProduction.supabaseUrl;

  /// Production Supabase anonymous key (obfuscated in binary)
  @EnviedField(varName: 'SUPABASE_PRODUCTION_ANON_KEY', obfuscate: true)
  static String supabaseAnonKey = _EnvProduction.supabaseAnonKey;
}
