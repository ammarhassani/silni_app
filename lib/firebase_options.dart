// Firebase configuration for Silni app
// Generated for project: silni-31811
// Platforms: Android, iOS, Web
// Keys are now loaded from environment variables with obfuscation

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'core/config/env/env_firebase.dart';

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: EnvFirebase.webApiKey,
    appId: EnvFirebase.webAppId,
    messagingSenderId: EnvFirebase.messagingSenderId,
    projectId: EnvFirebase.projectId,
    authDomain: EnvFirebase.authDomain,
    storageBucket: EnvFirebase.storageBucket,
    measurementId: EnvFirebase.measurementId,
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: EnvFirebase.androidApiKey,
    appId: EnvFirebase.androidAppId,
    messagingSenderId: EnvFirebase.messagingSenderId,
    projectId: EnvFirebase.projectId,
    storageBucket: EnvFirebase.storageBucket,
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: EnvFirebase.iosApiKey,
    appId: EnvFirebase.iosAppId,
    messagingSenderId: EnvFirebase.messagingSenderId,
    projectId: EnvFirebase.projectId,
    storageBucket: EnvFirebase.storageBucket,
    iosBundleId: 'com.silni.app',
  );
}
