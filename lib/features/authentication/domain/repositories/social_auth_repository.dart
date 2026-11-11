import 'package:dartz/dartz.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/authentication/domain/entities/social_provider.dart';
import 'package:autodoc_ai/features/authentication/domain/entities/user_entity.dart';

/// Sign in or sign up with Google, Yahoo or Microsoft.
abstract class SocialAuthRepository {
  Future<Either<Failure, UserEntity>> signIn(SocialProvider provider);
}