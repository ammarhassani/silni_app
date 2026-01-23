import 'package:envied/envied.dart';

part 'env_firebase.g.dart';

/// Firebase configuration with obfuscation for security
/// Keys are XOR-encoded to prevent easy extraction from compiled binary
@Envied(path: '.env', obfuscate: true)
abstract class EnvFirebase {
  // ============ iOS Configuration ============

  /// Firebase iOS API key
  @EnviedField(varName: 'FIREBASE_IOS_API_KEY', obfuscate: true)
  static String iosApiKey = _EnvFirebase.iosApiKey;

  /// Firebase iOS App ID
  @EnviedField(varName: 'FIREBASE_IOS_APP_ID', obfuscate: true)
  static String iosAppId = _EnvFirebase.iosAppId;

  // ============ Android Configuration ============

  /// Firebase Android API key
  @EnviedField(varName: 'FIREBASE_ANDROID_API_KEY', obfuscate: true)
  static String androidApiKey = _EnvFirebase.androidApiKey;

  /// Firebase Android App ID
  @EnviedField(varName: 'FIREBASE_ANDROID_APP_ID', obfuscate: true)
  static String androidAppId = _EnvFirebase.androidAppId;

  // ============ Web Configuration ============

  /// Firebase Web API key
  @EnviedField(varName: 'FIREBASE_WEB_API_KEY', obfuscate: true)
  static String webApiKey = _EnvFirebase.webApiKey;

  /// Firebase Web App ID
  @EnviedField(varName: 'FIREBASE_WEB_APP_ID', obfuscate: true)
  static String webAppId = _EnvFirebase.webAppId;

  /// Firebase Auth domain (web only)
  @EnviedField(varName: 'FIREBASE_AUTH_DOMAIN', obfuscate: true)
  static String authDomain = _EnvFirebase.authDomain;

  /// Firebase measurement ID (for analytics, web only)
  @EnviedField(varName: 'FIREBASE_MEASUREMENT_ID', obfuscate: true)
  static String measurementId = _EnvFirebase.measurementId;

  // ============ Common Configuration ============

  /// Firebase project ID
  @EnviedField(varName: 'FIREBASE_PROJECT_ID', obfuscate: true)
  static String projectId = _EnvFirebase.projectId;

  /// Firebase storage bucket
  @EnviedField(varName: 'FIREBASE_STORAGE_BUCKET', obfuscate: true)
  static String storageBucket = _EnvFirebase.storageBucket;

  /// Firebase messaging sender ID
  @EnviedField(varName: 'FIREBASE_MESSAGING_SENDER_ID', obfuscate: true)
  static String messagingSenderId = _EnvFirebase.messagingSenderId;
}
