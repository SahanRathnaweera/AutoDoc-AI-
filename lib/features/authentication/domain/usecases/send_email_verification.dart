import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/authentication/domain/repositories/auth_repository.dart';

@lazySingleton
class SendEmailVerification implements UseCase<void, NoParams> {
  final AuthRepository repository;

  SendEmailVerification(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.sendEmailVerification();
  }
}
