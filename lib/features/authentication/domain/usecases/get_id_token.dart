import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/authentication/domain/repositories/auth_repository.dart';

class GetIdTokenParams extends Equatable {
  final bool forceRefresh;

  const GetIdTokenParams({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

@lazySingleton
class GetIdToken implements UseCase<String, GetIdTokenParams> {
  final AuthRepository repository;

  GetIdToken(this.repository);

  @override
  Future<Either<Failure, String>> call(GetIdTokenParams params) {
    return repository.getIdToken(forceRefresh: params.forceRefresh);
  }
}
