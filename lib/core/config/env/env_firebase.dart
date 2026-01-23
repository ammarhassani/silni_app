import 'package:envied/envied.dart';

part 'env_firebase.g.dart';

/// Firebase configuration with obfuscation for security
/// Keys are XOR-encoded to prevent easy extraction from compiled binary
@Envied(path: '.env', obfuscate: true)
abstract class EnvFirebase {
  // ============ iOS Configuration ============

  /// Firebase iOS API key
  @EnviedField(varName: 'FIREBASE_IOS_API_KEY', defaultValue: '')
  static String iosApiKey = _EnvFirebase.iosApiKey;

  /// Firebase iOS App ID
  @EnviedField(varName: 'FIREBASE_IOS_APP_ID', defaultValue: '')
  static String iosAppId = _EnvFirebase.iosAppId;

  // ============ Android Configuration ============

  /// Firebase Android API key
  @EnviedField(varName: 'FIREBASE_ANDROID_API_KEY', defaultValue: '')
  static String androidApiKey = _EnvFirebase.androidApiKey;

  /// Firebase Android App ID
  @EnviedField(varName: 'FIREBASE_ANDROID_APP_ID', defaultValue: '')
  static String androidAppId = _EnvFirebase.androidAppId;

  // ============ Web Configuration ============

  /// Firebase Web API key
  @EnviedField(varName: 'FIREBASE_WEB_API_KEY', defaultValue: '')
  static String webApiKey = _EnvFirebase.webApiKey;

  /// Firebase Web App ID
  @EnviedField(varName: 'FIREBASE_WEB_APP_ID', defaultValue: '')
  static String webAppId = _EnvFirebase.webAppId;

  /// Firebase Auth domain (web only)
  @EnviedField(varName: 'FIREBASE_AUTH_DOMAIN', defaultValue: '')
  static String authDomain = _EnvFirebase.authDomain;

  /// Firebase measurement ID (for analytics, web only)
  @EnviedField(varName: 'FIREBASE_MEASUREMENT_ID', defaultValue: '')
  static String measurementId = _EnvFirebase.measurementId;

  // ============ Common Configuration ============

  /// Firebase project ID
  @EnviedField(varName: 'FIREBASE_PROJECT_ID', defaultValue: '')
  static String projectId = _EnvFirebase.projectId;

  /// Firebase storage bucket
  @EnviedField(varName: 'FIREBASE_STORAGE_BUCKET', defaultValue: '')
  static String storageBucket = _EnvFirebase.storageBucket;

  /// Firebase messaging sender ID
  @EnviedField(varName: 'FIREBASE_MESSAGING_SENDER_ID', defaultValue: '')
  static String messagingSenderId = _EnvFirebase.messagingSenderId;
}
