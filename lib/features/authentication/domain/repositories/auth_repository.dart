import 'package:dartz/dartz.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/authentication/domain/entities/user_entity.dart';

/// Contract for Authentication repository in the Domain layer.
abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
    String? phoneNumber,
    String role = 'client',
  });

  Future<Either<Failure, UserEntity>> loginWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, UserEntity?>> getCurrentUser();

  Stream<UserEntity?> observeAuthState();

  Future<Either<Failure, void>> sendPasswordResetEmail({required String email});

  Future<Either<Failure, void>> sendEmailVerification();

  Future<Either<Failure, String>> getIdToken({bool forceRefresh = false});
}
