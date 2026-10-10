import 'package:dartz/dartz.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/authentication/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> loginWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
    String? phoneNumber,
    String role = 'client',
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, UserEntity?>> getCurrentUser();

  Stream<UserEntity?> observeAuthState();

  Future<Either<Failure, void>> sendPasswordResetEmail({required String email});

  Future<Either<Failure, void>> sendEmailVerification();

  Future<Either<Failure, String>> getIdToken({bool forceRefresh = false});

  Future<Either<Failure, void>> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(AuthFailure failure) onVerificationFailed,
    void Function(UserEntity user)? onVerificationCompleted,
    void Function(String verificationId)? onCodeAutoRetrievalTimeout,
    int? forceResendingToken,
    Duration timeout = const Duration(seconds: 60),
  });

  Future<Either<Failure, UserEntity>> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
    String? displayName,
    String role = 'client',
  });
}
