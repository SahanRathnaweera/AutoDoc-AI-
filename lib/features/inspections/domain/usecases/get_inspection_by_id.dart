import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/inspections/domain/entities/inspection_entity.dart';
import 'package:autodoc_ai/features/inspections/domain/repositories/inspection_repository.dart';

class GetInspectionByIdParams extends Equatable {
  final String inspectionId;

  const GetInspectionByIdParams(this.inspectionId);

  @override
  List<Object?> get props => [inspectionId];
}

@lazySingleton
class GetInspectionById implements UseCase<InspectionEntity?, GetInspectionByIdParams> {
  final InspectionRepository _repository;

  GetInspectionById(this._repository);

  @override
  Future<Either<Failure, InspectionEntity?>> call(GetInspectionByIdParams params) {
    return _repository.getInspectionById(params.inspectionId);
  }
}
