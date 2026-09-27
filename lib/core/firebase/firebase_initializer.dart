import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:autodoc_ai/core/utils/app_logger.dart';
import 'firebase_options.dart';

class FirebaseInitializer {
  FirebaseInitializer._();

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  /// Initializes Firebase with platform-appropriate options.
  /// If Firebase is already initialized, returns safely.
  /// If initialization fails (e.g. during local tests without credentials),
  /// logs a warning with AppLogger without crashing the app.
  static Future<bool> initialize({FirebaseOptions? options}) async {
    if (_isInitialized || Firebase.apps.isNotEmpty) {
      _isInitialized = true;
      AppLogger.info('Firebase already initialized: ${Firebase.apps.map((a) => a.name).join(', ')}');
      return true;
    }

    try {
      final effectiveOptions = options ?? _resolveDefaultOptions();
      if (effectiveOptions != null) {
        await Firebase.initializeApp(options: effectiveOptions);
      } else {
        await Firebase.initializeApp();
      }
      _isInitialized = true;
      AppLogger.info('Firebase initialized successfully.');
      return true;
    } catch (e, stackTrace) {
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
  }

  static FirebaseOptions? _resolveDefaultOptions() {
    try {
      return DefaultFirebaseOptions.currentPlatform;
    } catch (_) {
      return null;
    }
  }
}
