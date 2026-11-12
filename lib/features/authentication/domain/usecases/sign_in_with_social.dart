import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/authentication/domain/entities/social_provider.dart';
import 'package:autodoc_ai/features/authentication/domain/entities/user_entity.dart';
import 'package:autodoc_ai/features/authentication/domain/repositories/social_auth_repository.dart';

class SocialSignInParams extends Equatable {
  final SocialProvider provider;

  const SocialSignInParams(this.provider);

  @override
  List<Object?> get props => [provider];
}

@lazySingleton
class SignInWithSocial implements UseCase<UserEntity, SocialSignInParams> {
  final SocialAuthRepository repository;

  SignInWithSocial(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SocialSignInParams params) {
    return repository.signIn(params.provider);
  }
}