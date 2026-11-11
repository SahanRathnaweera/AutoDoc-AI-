import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/firebase/firestore_collections.dart';
import 'package:autodoc_ai/core/utils/app_logger.dart';
import 'package:autodoc_ai/features/authentication/data/models/user_model.dart';
import 'package:autodoc_ai/features/authentication/domain/entities/social_provider.dart';
import 'package:autodoc_ai/features/authentication/domain/entities/user_entity.dart';
import 'package:autodoc_ai/features/authentication/domain/repositories/social_auth_repository.dart';

@LazySingleton(as: SocialAuthRepository)
class SocialAuthRepositoryImpl implements SocialAuthRepository {
  final fb_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  SocialAuthRepositoryImpl(this._firebaseAuth, this._firestore);

  fb_auth.AuthProvider _providerFor(SocialProvider provider) {
    switch (provider) {
      case SocialProvider.google:
        return fb_auth.GoogleAuthProvider();
      case SocialProvider.yahoo:
        return fb_auth.OAuthProvider('yahoo.com');
      case SocialProvider.microsoft:
        return fb_auth.OAuthProvider('microsoft.com');
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signIn(SocialProvider provider) async {
    try {
      final authProvider = _providerFor(provider);
      final credential = kIsWeb
          ? await _firebaseAuth.signInWithPopup(authProvider)
          : await _firebaseAuth.signInWithProvider(authProvider);

      final user = credential.user;
      if (user == null) {
        return Left(AuthFailure('Sign-in failed. Please try again.'));
      }

      // Existing account: load its saved profile.
      try {
        final doc = await _firestore
            .collection(FirestoreCollections.users)
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          return Right(UserModel.fromMap(doc.data()!, uid: user.uid));
        }
      } catch (e) {
        AppLogger.warning('Could not read user profile: $e');
      }

      // New account: save a profile in Firestore.
      final now = DateTime.now();
      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        phoneNumber: user.phoneNumber,
        photoUrl: user.photoURL,
        isEmailVerified: user.emailVerified,
        role: 'client',
        createdAt: now,
        updatedAt: now,
      );

      try {
        await _firestore
            .collection(FirestoreCollections.users)
            .doc(user.uid)
            .set(userModel.toMap(), SetOptions(merge: true));
      } catch (e) {
        AppLogger.warning('Failed to save social user profile: $e');
      }

      return Right(userModel);
    } on fb_auth.FirebaseAuthException catch (e) {
      AppLogger.error('Social sign-in [${e.code}]: ${e.message}');
      return Left(AuthFailure(_messageFor(e), e.code));
    } catch (e) {
      return Left(AuthFailure('Unexpected sign-in failure: $e'));
    }
  }

  String _messageFor(fb_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'web-context-canceled':
      case 'canceled':
        return 'Sign-in was cancelled.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled yet.';
      case 'network-request-failed':
        return 'Network connection failed. Please check your internet.';
      default:
        return e.message ?? 'Sign-in failed. Please try again.';
    }
  }
}