import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/acoustic_diagnostic/domain/entities/engine_diagnostic_entity.dart';
import 'package:autodoc_ai/features/acoustic_diagnostic/domain/repositories/engine_diagnostic_repository.dart';

class GetDiagnosticsByInspectionParams extends Equatable {
  final String inspectionId;

  const GetDiagnosticsByInspectionParams(this.inspectionId);

  @override
  List<Object?> get props => [inspectionId];
}

@lazySingleton
class GetDiagnosticsByInspection implements UseCase<List<EngineDiagnosticEntity>, GetDiagnosticsByInspectionParams> {
  final EngineDiagnosticRepository _repository;

  GetDiagnosticsByInspection(this._repository);

  @override
  Future<Either<Failure, List<EngineDiagnosticEntity>>> call(GetDiagnosticsByInspectionParams params) {
    return _repository.getDiagnosticsByInspection(params.inspectionId);
  }
}
