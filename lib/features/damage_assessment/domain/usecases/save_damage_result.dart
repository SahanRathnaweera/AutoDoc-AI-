import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/damage_assessment/domain/entities/damage_result_entity.dart';
import 'package:autodoc_ai/features/damage_assessment/domain/repositories/damage_repository.dart';

class SaveDamageResultParams extends Equatable {
  final DamageResultEntity damageResult;

  const SaveDamageResultParams(this.damageResult);

  @override
  List<Object?> get props => [damageResult];
}

@lazySingleton
class SaveDamageResult implements UseCase<String, SaveDamageResultParams> {
  final DamageRepository _repository;

  SaveDamageResult(this._repository);

  @override
  Future<Either<Failure, String>> call(SaveDamageResultParams params) {
    return _repository.saveDamageResult(params.damageResult);
  }
}
