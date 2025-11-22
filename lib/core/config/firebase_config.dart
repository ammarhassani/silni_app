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
        // For web, use the hardcoded Firebase configuration
        // The JS SDK in index.html is for compat mode, but we need to initialize
        // the Dart Firebase SDK separately
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "AIzaSyBuS1snryQ_DWxhcEUtj0Lu_HDrdIvASDY",
            authDomain: "silni-31811.firebaseapp.com",
            projectId: "silni-31811",
            storageBucket: "silni-31811.firebasestorage.app",
            messagingSenderId: "1049917341546",
            appId: "1:1049917341546:web:baa2792c28877379412f13",
            measurementId: "G-1MR4GW3PR4",
          ),
        );
        if (kDebugMode) {
          print('✅ Firebase initialized for Web');
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
