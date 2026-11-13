import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:autodoc_ai/core/utils/app_logger.dart';

import '../../firebase_options.dart';

class FirebaseInitializer {
  FirebaseInitializer._();

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  // Shared in-flight initialization so concurrent callers don't race.
  static Future<bool>? _pending;

  /// Initializes Firebase with platform-appropriate options.
  /// Safe to call multiple times, even concurrently.
  static Future<bool> initialize({FirebaseOptions? options}) {
    if (_isInitialized || Firebase.apps.isNotEmpty) {
      _isInitialized = true;
      return Future.value(true);
    }
    return _pending ??= _doInitialize(options).whenComplete(() {
      _pending = null;
    });
  }

  static Future<bool> _doInitialize(FirebaseOptions? options) async {
    try {
      final effectiveOptions = options ?? _resolveDefaultOptions();
      if (effectiveOptions != null && _hasClientConfiguration(effectiveOptions)) {
        await Firebase.initializeApp(options: effectiveOptions);
      } else if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS)) {
        await Firebase.initializeApp();
      } else {
        throw StateError('Firebase client configuration is missing for this platform.');
      }
      _isInitialized = true;
      AppLogger.info('Firebase initialized successfully.');
      return true;
    } on FirebaseException catch (e, stackTrace) {
      // Native side (google-services plugin) may have created [DEFAULT] already.
      if (e.code == 'duplicate-app') {
        _isInitialized = true;
        AppLogger.info('Firebase [DEFAULT] app already existed; reusing it.');
        return true;
      }
      return _handleFailure(e, stackTrace);
    } catch (e, stackTrace) {
      return _handleFailure(e, stackTrace);
    }
  }

  static bool _handleFailure(Object e, StackTrace stackTrace) {
    _isInitialized = false;
    AppLogger.warning(
      'Firebase initialization skipped or failed: $e. '
      'If running locally, configure Firebase via flutterfire configure or supply google-services.json.',
    );
    if (kDebugMode) {
      AppLogger.error('Firebase initialization error details', e, stackTrace);
    }
    return false;
  }

  static bool _hasClientConfiguration(FirebaseOptions options) =>
      options.apiKey.isNotEmpty &&
      !options.apiKey.startsWith('your-') &&
      options.appId.isNotEmpty &&
      !options.appId.startsWith('your-') &&
      options.messagingSenderId.isNotEmpty &&
      options.projectId.isNotEmpty;

  static FirebaseOptions? _resolveDefaultOptions() {
    try {
      return DefaultFirebaseOptions.currentPlatform;
    } catch (_) {
      return null;
    }
  }
}