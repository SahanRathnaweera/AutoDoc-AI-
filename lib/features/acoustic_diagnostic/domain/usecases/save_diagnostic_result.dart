import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/acoustic_diagnostic/domain/entities/engine_diagnostic_entity.dart';
import 'package:autodoc_ai/features/acoustic_diagnostic/domain/repositories/engine_diagnostic_repository.dart';

class SaveDiagnosticResultParams extends Equatable {
  final EngineDiagnosticEntity diagnostic;

  const SaveDiagnosticResultParams(this.diagnostic);

  @override
  List<Object?> get props => [diagnostic];
}

@lazySingleton
class SaveDiagnosticResult implements UseCase<String, SaveDiagnosticResultParams> {
  final EngineDiagnosticRepository _repository;

  SaveDiagnosticResult(this._repository);

  @override
  Future<Either<Failure, String>> call(SaveDiagnosticResultParams params) {
    return _repository.saveDiagnosticResult(params.diagnostic);
  }
}
