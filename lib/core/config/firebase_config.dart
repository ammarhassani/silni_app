import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseConfig {
  FirebaseConfig._();

  /// Initialize Firebase with platform-specific configuration
  static Future<void> initialize() async {
    // Load environment variables
    await dotenv.load(fileName: '.env');

    // Get Firebase configuration from environment
    final apiKey = dotenv.env['FIREBASE_API_KEY']!;
    final authDomain = dotenv.env['FIREBASE_AUTH_DOMAIN']!;
    final projectId = dotenv.env['FIREBASE_PROJECT_ID']!;
    final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET']!;
    final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!;
    final appId = dotenv.env['FIREBASE_APP_ID']!;
    final measurementId = dotenv.env['FIREBASE_MEASUREMENT_ID'];

    // Platform-specific initialization
    if (kIsWeb) {
      // Web configuration
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
        print('✅ Firebase initialized for Web');
      }
    } else {
      // For Android and iOS, use google-services.json and GoogleService-Info.plist
      // You'll need to download these files from Firebase Console
      await Firebase.initializeApp();
      if (kDebugMode) {
        print('✅ Firebase initialized for Mobile');
      }
    }
  }

  /// Firebase options for Web platform
  static FirebaseOptions get webOptions => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY']!,
        authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN']!,
        projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
        appId: dotenv.env['FIREBASE_APP_ID']!,
        measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'],
      );
}
