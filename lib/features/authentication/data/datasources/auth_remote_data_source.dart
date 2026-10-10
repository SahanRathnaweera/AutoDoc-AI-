import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/exceptions.dart';
import 'package:autodoc_ai/core/firebase/firestore_collections.dart';
import 'package:autodoc_ai/core/utils/app_logger.dart';
import 'package:autodoc_ai/features/authentication/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
    String? phoneNumber,
    String role = 'client',
  });

  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<UserModel?> getCurrentUser();

  Stream<UserModel?> observeAuthState();

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> sendEmailVerification();

  Future<String> getIdToken({bool forceRefresh = false});

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(AuthException exception) onVerificationFailed,
    void Function(fb_auth.PhoneAuthCredential credential)? onVerificationCompleted,
    void Function(String verificationId)? onCodeAutoRetrievalTimeout,
    int? forceResendingToken,
    Duration timeout = const Duration(seconds: 60),
  });

  Future<UserModel> signInWithOtp({
    required String verificationId,
    required String smsCode,
    String? displayName,
    String role = 'client',
  });
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final fb_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl(this._firebaseAuth, this._firestore);

  @override
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
    String? phoneNumber,
    String role = 'client',
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw AuthException('Registration failed: user is null', code: 'null-user');
      }

      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
      }

      final now = DateTime.now();
      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? email.trim(),
        displayName: displayName ?? user.displayName,
        phoneNumber: phoneNumber ?? user.phoneNumber,
        photoUrl: user.photoURL,
        isEmailVerified: user.emailVerified,
        role: role,
        createdAt: now,
        updatedAt: now,
      );

      try {
        await _firestore
            .collection(FirestoreCollections.users)
            .doc(user.uid)
            .set(userModel.toMap(), SetOptions(merge: true));
      } catch (e) {
        AppLogger.warning('Failed to persist user profile in Firestore: $e');
      }

      return userModel;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Unexpected error during registration: $e');
    }
  }

  @override
  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw AuthException('Login failed: user is null', code: 'null-user');
      }

      return await _getUserModelWithFirestoreData(user);
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Unexpected error during login: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthException('Failed to logout: $e');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;
      return await _getUserModelWithFirestoreData(user);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to get current user: $e');
    }
  }

  @override
  Stream<UserModel?> observeAuthState() {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return await _getUserModelWithFirestoreData(user);
    });
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthException('Failed to send password reset email: $e');
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('No authenticated user to verify', code: 'no-current-user');
      }
      await user.sendEmailVerification();
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to send email verification: $e');
    }
  }

  @override
  Future<String> getIdToken({bool forceRefresh = false}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('No authenticated user available to obtain ID token', code: 'unauthenticated');
      }
      final token = await user.getIdToken(forceRefresh);
      if (token == null) {
        throw AuthException('Received empty ID token from Firebase Auth', code: 'empty-token');
      }
      return token;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to retrieve Firebase ID token: $e');
    }
  }

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(AuthException exception) onVerificationFailed,
    void Function(fb_auth.PhoneAuthCredential credential)? onVerificationCompleted,
    void Function(String verificationId)? onCodeAutoRetrievalTimeout,
    int? forceResendingToken,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber.trim(),
        timeout: timeout,
        forceResendingToken: forceResendingToken,
        verificationCompleted: (credential) {
          if (onVerificationCompleted != null) {
            onVerificationCompleted(credential);
          }
        },
        verificationFailed: (e) {
          onVerificationFailed(_handleFirebaseAuthException(e));
        },
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout: (verificationId) {
          if (onCodeAutoRetrievalTimeout != null) {
            onCodeAutoRetrievalTimeout(verificationId);
          }
        },
      );
    } on fb_auth.FirebaseAuthException catch (e) {
      onVerificationFailed(_handleFirebaseAuthException(e));
    } catch (e) {
      onVerificationFailed(AuthException('Unexpected phone verification error: $e'));
    }
  }

  @override
  Future<UserModel> signInWithOtp({
    required String verificationId,
    required String smsCode,
    String? displayName,
    String role = 'client',
  }) async {
    try {
      final credential = fb_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw AuthException('Phone authentication failed: user is null', code: 'null-user');
      }

      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
      }

      final doc = await _firestore.collection(FirestoreCollections.users).doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, uid: user.uid);
      }

      final now = DateTime.now();
      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: displayName ?? user.displayName,
        phoneNumber: user.phoneNumber,
        photoUrl: user.photoURL,
        isEmailVerified: true,
        role: role,
        createdAt: now,
        updatedAt: now,
      );

      try {
        await _firestore
            .collection(FirestoreCollections.users)
            .doc(user.uid)
            .set(userModel.toMap(), SetOptions(merge: true));
      } catch (e) {
        AppLogger.warning('Failed to persist phone user profile in Firestore: $e');
      }

      return userModel;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to sign in with OTP: $e');
    }
  }

  Future<UserModel> _getUserModelWithFirestoreData(fb_auth.User user) async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, uid: user.uid);
      }
    } catch (e) {
      AppLogger.warning('Could not fetch user profile from Firestore, using auth token info: $e');
    }
    return UserModel.fromFirebaseUser(user);
  }

  AuthException _handleFirebaseAuthException(fb_auth.FirebaseAuthException e) {
    AppLogger.error('FirebaseAuthException [${e.code}]: ${e.message}');
    switch (e.code) {
      case 'invalid-verification-code':
        return AuthException('The SMS verification code entered is invalid.', code: e.code);
      case 'session-expired':
        return AuthException('The SMS verification session has expired. Please request a new code.', code: e.code);
      case 'quota-exceeded':
        return AuthException('SMS verification quota exceeded. Please try again later.', code: e.code);
      case 'invalid-phone-number':
        return AuthException('The phone number entered is invalid.', code: e.code);
      case 'user-not-found':
        return AuthException('No user account found with this email.', code: e.code);
      case 'wrong-password':
        return AuthException('Incorrect password. Please try again.', code: e.code);
      case 'invalid-credential':
        return AuthException('Invalid login credentials.', code: e.code);
      case 'email-already-in-use':
        return AuthException('An account already exists for this email.', code: e.code);
      case 'invalid-email':
        return AuthException('The email address entered is invalid.', code: e.code);
      case 'weak-password':
        return AuthException('The password provided is too weak.', code: e.code);
      case 'user-disabled':
        return AuthException('This account has been disabled. Please contact support.', code: e.code);
      case 'too-many-requests':
        return AuthException('Too many attempts. Please wait a few moments and try again.', code: e.code);
      case 'network-request-failed':
        return AuthException('Network connection failed. Please check your internet.', code: e.code);
      default:
        return AuthException(e.message ?? 'An authentication error occurred.', code: e.code);
    }
  }
}
