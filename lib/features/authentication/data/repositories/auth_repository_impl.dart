import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/exceptions.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:autodoc_ai/features/authentication/domain/entities/user_entity.dart';
import 'package:autodoc_ai/features/authentication/domain/repositories/auth_repository.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, UserEntity>> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await _remoteDataSource.loginWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Right(userModel);
    } on AuthException catch (e) {
      return Left(_mapAuthExceptionToFailure(e));
    } catch (e) {
      return Left(AuthFailure('Unexpected login failure: $e'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
    String? phoneNumber,
    String role = 'client',
  }) async {
    try {
      final userModel = await _remoteDataSource.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
        phoneNumber: phoneNumber,
        role: role,
      );
      return Right(userModel);
    } on AuthException catch (e) {
      return Left(_mapAuthExceptionToFailure(e));
    } catch (e) {
      return Left(AuthFailure('Unexpected registration failure: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remoteDataSource.logout();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(_mapAuthExceptionToFailure(e));
    } catch (e) {
      return Left(AuthFailure('Unexpected logout failure: $e'));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = await _remoteDataSource.getCurrentUser();
      return Right(user);
    } on AuthException catch (e) {
      return Left(_mapAuthExceptionToFailure(e));
    } catch (e) {
      return Left(AuthFailure('Unexpected failure retrieving user: $e'));
    }
  }

  @override
  Stream<UserEntity?> observeAuthState() {
    return _remoteDataSource.observeAuthState();
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail({required String email}) async {
    try {
      await _remoteDataSource.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(_mapAuthExceptionToFailure(e));
    } catch (e) {
      return Left(AuthFailure('Unexpected password reset failure: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> sendEmailVerification() async {
    try {
      await _remoteDataSource.sendEmailVerification();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(_mapAuthExceptionToFailure(e));
    } catch (e) {
      return Left(AuthFailure('Unexpected verification email failure: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> getIdToken({bool forceRefresh = false}) async {
    try {
      final token = await _remoteDataSource.getIdToken(forceRefresh: forceRefresh);
      return Right(token);
    } on AuthException catch (e) {
      return Left(_mapAuthExceptionToFailure(e));
    } catch (e) {
      return Left(AuthFailure('Unexpected ID token retrieval failure: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(AuthFailure failure) onVerificationFailed,
    void Function(UserEntity user)? onVerificationCompleted,
    void Function(String verificationId)? onCodeAutoRetrievalTimeout,
    int? forceResendingToken,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      await _remoteDataSource.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        onCodeSent: onCodeSent,
        onVerificationFailed: (exception) {
          onVerificationFailed(_mapAuthExceptionToFailure(exception));
        },
        onVerificationCompleted: onVerificationCompleted != null
            ? (credential) async {
                final user = await _remoteDataSource.getCurrentUser();
                if (user != null) onVerificationCompleted(user);
              }
            : null,
        onCodeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
        forceResendingToken: forceResendingToken,
        timeout: timeout,
      );
      return const Right(null);
    } on AuthException catch (e) {
      return Left(_mapAuthExceptionToFailure(e));
    } catch (e) {
      return Left(AuthFailure('Unexpected phone verification failure: $e'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
    String? displayName,
    String role = 'client',
  }) async {
    try {
      final userModel = await _remoteDataSource.signInWithOtp(
        verificationId: verificationId,
        smsCode: smsCode,
        displayName: displayName,
        role: role,
      );
      return Right(userModel);
    } on AuthException catch (e) {
      return Left(_mapAuthExceptionToFailure(e));
    } catch (e) {
      return Left(AuthFailure('Unexpected OTP verification failure: $e'));
    }
  }

  AuthFailure _mapAuthExceptionToFailure(AuthException exception) {
    switch (exception.code) {
      case 'invalid-verification-code':
        return InvalidOtpFailure(exception.message, exception.code);
      case 'session-expired':
        return OtpTimeoutFailure(exception.message, exception.code);
      case 'quota-exceeded':
        return PhoneAuthQuotaExceededFailure(exception.message, exception.code);
      case 'invalid-credential':
        return InvalidCredentialsFailure(exception.message, exception.code);
      case 'user-not-found':
        return UserNotFoundFailure(exception.message, exception.code);
      case 'email-already-in-use':
        return EmailAlreadyInUseFailure(exception.message, exception.code);
      case 'weak-password':
        return WeakPasswordFailure(exception.message, exception.code);
      default:
        return AuthFailure(exception.message, exception.code);
    }
  }
}
