import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseConfig {
  FirebaseConfig._();

  /// Initialize Firebase with platform-specific configuration
  static Future<void> initialize() async {
    try {
      // Platform-specific initialization
      if (kIsWeb) {
        // Get Firebase configuration from environment (with fallbacks)
        final apiKey = dotenv.env['FIREBASE_API_KEY'] ?? '';
        final authDomain = dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '';
        final projectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
        final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
        final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
        final appId = dotenv.env['FIREBASE_APP_ID'] ?? '';
        final measurementId = dotenv.env['FIREBASE_MEASUREMENT_ID'];

        // Only initialize if we have the required config
        if (apiKey.isNotEmpty && projectId.isNotEmpty && appId.isNotEmpty) {
          // Web configuration from environment
          await Firebase.initializeApp(
            options: FirebaseOptions(
              apiKey: apiKey,
              authDomain: authDomain,
              projectId: projectId,
              storageBucket: storageBucket,
              messagingSenderId: messagingSenderId,
              appId: appId,
              measurementId: measurementId,
            ),
          );
          if (kDebugMode) {
            print('✅ Firebase initialized for Web (from .env)');
          }
        } else {
          // Try to initialize with default configuration (from web/index.html)
          await Firebase.initializeApp();
          if (kDebugMode) {
            print('✅ Firebase initialized for Web (from default config)');
          }
        }
      } else {
        // For Android and iOS, use google-services.json and GoogleService-Info.plist
        await Firebase.initializeApp();
        if (kDebugMode) {
          print('✅ Firebase initialized for Mobile');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase initialization error: $e');
        print('⚠️ App will continue but Firebase features may not work');
      }
      // Don't rethrow - allow app to continue even if Firebase fails
    }
  }

  /// Firebase options for Web platform
  static FirebaseOptions get webOptions => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
        authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '',
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
        appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
        measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'],
      );
}
