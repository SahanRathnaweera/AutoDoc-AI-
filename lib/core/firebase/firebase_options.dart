import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
        return macos;
      case TargetPlatform.windows:
        return windows;
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

  static String _env(String key) {
    if (dotenv.isInitialized && dotenv.env[key] != null && dotenv.env[key]!.isNotEmpty) {
      return dotenv.env[key]!;
    }
    return String.fromEnvironment(key, defaultValue: '');
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: _env('FIREBASE_WEB_API_KEY'),
    appId: _env('FIREBASE_WEB_APP_ID'),
    messagingSenderId: _env('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: _env('FIREBASE_PROJECT_ID'),
    authDomain: _env('FIREBASE_AUTH_DOMAIN'),
    storageBucket: _env('FIREBASE_STORAGE_BUCKET'),
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: _env('FIREBASE_ANDROID_API_KEY'),
    appId: _env('FIREBASE_ANDROID_APP_ID'),
    messagingSenderId: _env('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: _env('FIREBASE_PROJECT_ID'),
    storageBucket: _env('FIREBASE_STORAGE_BUCKET'),
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: _env('FIREBASE_IOS_API_KEY'),
    appId: _env('FIREBASE_IOS_APP_ID'),
    messagingSenderId: _env('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: _env('FIREBASE_PROJECT_ID'),
    storageBucket: _env('FIREBASE_STORAGE_BUCKET'),
    iosBundleId: _env('FIREBASE_IOS_BUNDLE_ID'),
  );

  static FirebaseOptions get macos => FirebaseOptions(
    apiKey: _env('FIREBASE_IOS_API_KEY'),
    appId: _env('FIREBASE_IOS_APP_ID'),
    messagingSenderId: _env('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: _env('FIREBASE_PROJECT_ID'),
    storageBucket: _env('FIREBASE_STORAGE_BUCKET'),
    iosBundleId: _env('FIREBASE_IOS_BUNDLE_ID'),
  );

  static FirebaseOptions get windows => FirebaseOptions(
    apiKey: _env('FIREBASE_WEB_API_KEY'),
    appId: _env('FIREBASE_WINDOWS_APP_ID'),
    messagingSenderId: _env('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: _env('FIREBASE_PROJECT_ID'),
    authDomain: _env('FIREBASE_AUTH_DOMAIN'),
    storageBucket: _env('FIREBASE_STORAGE_BUCKET'),
  );
}