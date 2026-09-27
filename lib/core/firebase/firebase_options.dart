// File generated as template for AutoDoc AI Firebase integration.
// Run `flutterfire configure` to generate production credentials.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// When connecting to your production Firebase project, run:
/// ```bash
/// flutterfire configure
/// ```
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSy-PLACEHOLDER-WEB-API-KEY',
    appId: '1:1234567890:web:abcdef123456',
    messagingSenderId: '1234567890',
    projectId: 'autodoc-ai',
    authDomain: 'autodoc-ai.firebaseapp.com',
    storageBucket: 'autodoc-ai.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSy-PLACEHOLDER-ANDROID-API-KEY',
    appId: '1:1234567890:android:abcdef123456',
    messagingSenderId: '1234567890',
    projectId: 'autodoc-ai',
    storageBucket: 'autodoc-ai.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSy-PLACEHOLDER-IOS-API-KEY',
    appId: '1:1234567890:ios:abcdef123456',
    messagingSenderId: '1234567890',
    projectId: 'autodoc-ai',
    storageBucket: 'autodoc-ai.appspot.com',
    iosBundleId: 'com.example.autodocAi',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSy-PLACEHOLDER-MACOS-API-KEY',
    appId: '1:1234567890:ios:abcdef123456',
    messagingSenderId: '1234567890',
    projectId: 'autodoc-ai',
    storageBucket: 'autodoc-ai.appspot.com',
    iosBundleId: 'com.example.autodocAi',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSy-PLACEHOLDER-WINDOWS-API-KEY',
    appId: '1:1234567890:web:abcdef123456',
    messagingSenderId: '1234567890',
    projectId: 'autodoc-ai',
    authDomain: 'autodoc-ai.firebaseapp.com',
    storageBucket: 'autodoc-ai.appspot.com',
  );
}
