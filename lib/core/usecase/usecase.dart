import 'package:dartz/dartz.dart';
import 'package:autodoc_ai/core/error/failures.dart';

abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

abstract class StreamUseCase<T, Params> {
  Stream<T> call(Params params);
}

class NoParams {
  const NoParams();
}
