import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseConfig {
  FirebaseConfig._();

  /// Initialize Firebase with platform-specific configuration
  static Future<void> initialize() async {
    try {
      // Platform-specific initialization
      if (kIsWeb) {
        // For web, use environment variables from .env file
        // The JS SDK in index.html is for compat mode, but we need to initialize
        // the Dart Firebase SDK separately
        await Firebase.initializeApp(
          options: webOptions,
        );
        if (kDebugMode) {
          print('✅ Firebase initialized for Web');
        }

        // Configure Firestore settings for web - MUST be done before any Firestore access
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: false,  // Explicitly disable persistence
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );

        if (kDebugMode) {
          print('✅ Firestore settings configured for web');
        }
      } else {
        // For Android and iOS, use google-services.json and GoogleService-Info.plist
        await Firebase.initializeApp();
        if (kDebugMode) {
          print('✅ Firebase initialized for Mobile');
        }

        // Enable Firestore persistence for Mobile
        _enableFirestoreMobile();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase initialization error: $e');
        print('⚠️ App will continue but Firebase features may not work');
      }
      // Don't rethrow - allow app to continue even if Firebase fails
    }
  }

  /// Enable Firestore offline persistence for Mobile platforms
  static void _enableFirestoreMobile() {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      if (kDebugMode) {
        print('✅ Firestore offline persistence enabled for Mobile');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not enable Firestore persistence: $e');
      }
    }
  }

  /// Firebase options for Web platform
  /// Note: Hardcoded credentials for web since .env doesn't work in web builds
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
