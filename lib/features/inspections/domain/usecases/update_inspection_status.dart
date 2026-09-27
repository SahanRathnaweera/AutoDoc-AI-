import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/inspections/domain/repositories/inspection_repository.dart';

class UpdateInspectionStatusParams extends Equatable {
  final String inspectionId;
  final String status;

  const UpdateInspectionStatusParams({
    required this.inspectionId,
    required this.status,
  });

  @override
  List<Object?> get props => [inspectionId, status];
}

@lazySingleton
class UpdateInspectionStatus implements UseCase<void, UpdateInspectionStatusParams> {
  final InspectionRepository _repository;

  UpdateInspectionStatus(this._repository);

  @override
  Future<Either<Failure, void>> call(UpdateInspectionStatusParams params) {
    return _repository.updateInspectionStatus(params.inspectionId, params.status);
  }
}
