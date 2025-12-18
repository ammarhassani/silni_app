import 'package:envied/envied.dart';

part 'env_firebase.g.dart';

/// Firebase Web configuration (legacy - for potential future web support)
/// These are public API keys - not obfuscated as they're designed to be public
@Envied(path: '.env')
abstract class EnvFirebase {
  /// Firebase Web API key
  @EnviedField(varName: 'FIREBASE_API_KEY', defaultValue: '')
  static String apiKey = _EnvFirebase.apiKey;

  /// Firebase Auth domain
  @EnviedField(varName: 'FIREBASE_AUTH_DOMAIN', defaultValue: '')
  static String authDomain = _EnvFirebase.authDomain;

  /// Firebase project ID
  @EnviedField(varName: 'FIREBASE_PROJECT_ID', defaultValue: '')
  static String projectId = _EnvFirebase.projectId;

  /// Firebase storage bucket
  @EnviedField(varName: 'FIREBASE_STORAGE_BUCKET', defaultValue: '')
  static String storageBucket = _EnvFirebase.storageBucket;

  /// Firebase messaging sender ID
  @EnviedField(varName: 'FIREBASE_MESSAGING_SENDER_ID', defaultValue: '')
  static String messagingSenderId = _EnvFirebase.messagingSenderId;

  /// Firebase app ID
  @EnviedField(varName: 'FIREBASE_APP_ID', defaultValue: '')
  static String appId = _EnvFirebase.appId;

  /// Firebase measurement ID (for analytics)
  @EnviedField(varName: 'FIREBASE_MEASUREMENT_ID', defaultValue: '')
  static String measurementId = _EnvFirebase.measurementId;
}
