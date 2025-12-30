import 'package:envied/envied.dart';

part 'env_services.g.dart';

/// Third-party service configuration
/// Sentry, Cloudinary, and other external services
@Envied(path: '.env', obfuscate: true)
abstract class EnvServices {
  /// Sentry DSN for error tracking (obfuscated)
  @EnviedField(varName: 'SENTRY_DSN', obfuscate: true)
  static String sentryDsn = _EnvServices.sentryDsn;

  /// Cloudinary cloud name
  @EnviedField(varName: 'CLOUDINARY_CLOUD_NAME', defaultValue: '')
  static String cloudinaryCloudName = _EnvServices.cloudinaryCloudName;

  /// Cloudinary API key
  @EnviedField(varName: 'CLOUDINARY_API_KEY', defaultValue: '')
  static String cloudinaryApiKey = _EnvServices.cloudinaryApiKey;

  /// Cloudinary API secret (obfuscated)
  @EnviedField(varName: 'CLOUDINARY_API_SECRET', obfuscate: true, defaultValue: '')
  static String cloudinaryApiSecret = _EnvServices.cloudinaryApiSecret;

  /// Cloudinary upload preset
  @EnviedField(varName: 'CLOUDINARY_UPLOAD_PRESET', defaultValue: '')
  static String cloudinaryUploadPreset = _EnvServices.cloudinaryUploadPreset;

  /// Google OAuth - iOS Client ID (for Google Sign-In)
  @EnviedField(varName: 'GOOGLE_IOS_CLIENT_ID', defaultValue: '')
  static String googleIosClientId = _EnvServices.googleIosClientId;

  /// Google OAuth - Web Client ID (for Supabase OAuth)
  @EnviedField(varName: 'GOOGLE_WEB_CLIENT_ID', defaultValue: '')
  static String googleWebClientId = _EnvServices.googleWebClientId;

  /// RevenueCat API Key for iOS (obfuscated)
  @EnviedField(varName: 'REVENUECAT_APPLE_API_KEY', obfuscate: true, defaultValue: '')
  static String revenueCatAppleApiKey = _EnvServices.revenueCatAppleApiKey;

  /// RevenueCat API Key for Android (obfuscated)
  @EnviedField(varName: 'REVENUECAT_GOOGLE_API_KEY', obfuscate: true, defaultValue: '')
  static String revenueCatGoogleApiKey = _EnvServices.revenueCatGoogleApiKey;
}
