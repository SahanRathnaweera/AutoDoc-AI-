import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/inspections/domain/entities/inspection_entity.dart';
import 'package:autodoc_ai/features/inspections/domain/repositories/inspection_repository.dart';

class CreateInspectionParams extends Equatable {
  final InspectionEntity inspection;

  const CreateInspectionParams(this.inspection);

  @override
  List<Object?> get props => [inspection];
}

@lazySingleton
class CreateInspection implements UseCase<String, CreateInspectionParams> {
  final InspectionRepository _repository;

  CreateInspection(this._repository);

  @override
  Future<Either<Failure, String>> call(CreateInspectionParams params) {
    return _repository.createInspection(params.inspection);
  }
}
