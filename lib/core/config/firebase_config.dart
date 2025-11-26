import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Firebase configuration for FCM (Firebase Cloud Messaging) only
/// All data storage has been migrated to Supabase
class FirebaseConfig {
  FirebaseConfig._();

  /// Initialize Firebase (only for FCM notifications)
  static Future<void> initialize() async {
    try {
      if (kIsWeb) {
        // For web, use environment variables from .env file
        await Firebase.initializeApp(
          options: webOptions,
        );
        if (kDebugMode) {
          print('✅ [Firebase] Firebase initialized for Web (FCM only)');
        }
      } else {
        // For Android and iOS, use google-services.json and GoogleService-Info.plist
        await Firebase.initializeApp();
        if (kDebugMode) {
          print('✅ [Firebase] Firebase initialized for Mobile (FCM only)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Firebase] Firebase initialization error: $e');
        print('⚠️ [Firebase] App will continue but FCM features may not work');
      }
      // Don't rethrow - allow app to continue even if Firebase fails
    }
  }

  /// Firebase options for Web platform
  static FirebaseOptions get webOptions => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY'] ?? 'AIzaSyBuS1snryQ_DWxhcEUtj0Lu_HDrdIvASDY',
        authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? 'silni-31811.firebaseapp.com',
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? 'silni-31811',
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'silni-31811.firebasestorage.app',
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '104991741546',
        appId: dotenv.env['FIREBASE_APP_ID'] ?? '1:104991741546:web:baa2792c28877379412f13',
        measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? 'G-JMW4oM9PXM',
      );
}
