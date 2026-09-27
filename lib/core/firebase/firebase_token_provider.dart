import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/exceptions.dart';
import 'package:autodoc_ai/core/utils/app_logger.dart';

/// Provides valid Firebase ID tokens to HTTP clients communicating with the Python/FastAPI backend.
@lazySingleton
class FirebaseTokenProvider {
  final FirebaseAuth _firebaseAuth;

  FirebaseTokenProvider(this._firebaseAuth);

  /// Retrieves a valid Firebase ID token for the currently authenticated user.
  /// If [forceRefresh] is true, forces a token refresh from Firebase servers.
  /// Throws [AuthException] if no user is authenticated.
  Future<String> requireIdToken({bool forceRefresh = false}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      AppLogger.warning('Attempted to retrieve ID token without an authenticated user.');
      throw AuthException(
        'User is not authenticated. Please log in first.',
        code: 'unauthenticated',
      );
    }

    try {
      final token = await user.getIdToken(forceRefresh);
      if (token == null || token.isEmpty) {
        throw AuthException('Retrieved empty token from Firebase Auth.', code: 'empty-token');
      }
      return token;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Failed to obtain Firebase ID token: ${e.message}');
      throw AuthException(e.message ?? 'Failed to get ID token.', code: e.code);
    } catch (e) {
      throw AuthException('Unexpected error retrieving ID token: $e');
    }
  }

  /// Safe token retrieval returning null instead of throwing if unauthenticated.
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    try {
      return await user.getIdToken(forceRefresh);
    } catch (e) {
      AppLogger.warning('Error in optional getIdToken call: $e');
      return null;
    }
  }

  /// Builds the standard HTTP Authorization header containing the Bearer token.
  /// Example: `{'Authorization': 'Bearer eyJhbGciOiJSUzI1NiIs...'}`
  Future<Map<String, String>> getAuthorizationHeader({bool forceRefresh = false}) async {
    final token = await requireIdToken(forceRefresh: forceRefresh);
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }
}
