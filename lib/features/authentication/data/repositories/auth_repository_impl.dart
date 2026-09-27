import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/exceptions.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/utils/app_logger.dart';
import 'package:autodoc_ai/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:autodoc_ai/features/authentication/domain/entities/user_entity.dart';
import 'package:autodoc_ai/features/authentication/domain/repositories/auth_repository.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, UserEntity>> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
    String? phoneNumber,
    String role = 'client',
  }) async {
    try {
      final user = await _remoteDataSource.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
        phoneNumber: phoneNumber,
        role: role,
      );
      return Right(user);
    } on AuthException catch (e) {
      return Left(_mapAuthExceptionToFailure(e));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error in registerWithEmailAndPassword', e, stackTrace);
      return Left(ServerFailure('Failed to register user: $e'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remoteDataSource.loginWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Right(user);
    } on AuthException catch (e) {
      return Left(_mapAuthExceptionToFailure(e));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error in loginWithEmailAndPassword', e, stackTrace);
      return Left(ServerFailure('Failed to login: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remoteDataSource.logout();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(_mapAuthExceptionToFailure(e));
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error in logout', e, stackTrace);
      return Left(ServerFailure('Failed to logout: $e'));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = await _remoteDataSource.getCurrentUser();
      return Right(user);
    } on AuthException catch (e) {
      return Left(_mapAuthExceptionToFailure(e));
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error in getCurrentUser', e, stackTrace);
      return Left(ServerFailure('Failed to get current user: $e'));
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
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error in sendPasswordResetEmail', e, stackTrace);
      return Left(ServerFailure('Failed to send password reset: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> sendEmailVerification() async {
    try {
      await _remoteDataSource.sendEmailVerification();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(_mapAuthExceptionToFailure(e));
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error in sendEmailVerification', e, stackTrace);
      return Left(ServerFailure('Failed to send verification email: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> getIdToken({bool forceRefresh = false}) async {
    try {
      final token = await _remoteDataSource.getIdToken(forceRefresh: forceRefresh);
      return Right(token);
    } on AuthException catch (e) {
      return Left(_mapAuthExceptionToFailure(e));
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error in getIdToken', e, stackTrace);
      return Left(ServerFailure('Failed to get ID token: $e'));
    }
  }

  Failure _mapAuthExceptionToFailure(AuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
        return InvalidCredentialsFailure(e.message, e.code);
      case 'user-not-found':
        return UserNotFoundFailure(e.message, e.code);
      case 'email-already-in-use':
        return EmailAlreadyInUseFailure(e.message, e.code);
      case 'weak-password':
        return WeakPasswordFailure(e.message, e.code);
      case 'user-disabled':
        return UserDisabledFailure(e.message, e.code);
      case 'too-many-requests':
        return TooManyRequestsFailure(e.message, e.code);
      case 'network-request-failed':
        return NetworkFailure(e.message);
      default:
        return AuthFailure(e.message, e.code);
    }
  }
}
