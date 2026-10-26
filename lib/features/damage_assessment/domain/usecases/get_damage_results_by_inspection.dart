import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/damage_assessment/domain/entities/damage_result_entity.dart';
import 'package:autodoc_ai/features/damage_assessment/domain/repositories/damage_repository.dart';

class GetDamageResultsByInspectionParams extends Equatable {
  final String inspectionId;

  const GetDamageResultsByInspectionParams(this.inspectionId);

  @override
  List<Object?> get props => [inspectionId];
}

@lazySingleton
class GetDamageResultsByInspection implements UseCase<List<DamageResultEntity>, GetDamageResultsByInspectionParams> {
  final DamageRepository _repository;

  GetDamageResultsByInspection(this._repository);

  @override
  Future<Either<Failure, List<DamageResultEntity>>> call(GetDamageResultsByInspectionParams params) {
    return _repository.getDamageResultsByInspection(params.inspectionId);
  }
}
