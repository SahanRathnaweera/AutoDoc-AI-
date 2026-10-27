import 'package:dartz/dartz.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/damage_assessment/domain/entities/damage_result_entity.dart';

abstract class DamageRepository {
  Future<Either<Failure, List<DamageResultEntity>>> getDamageResultsByInspection(String inspectionId);
  Future<Either<Failure, String>> saveDamageResult(DamageResultEntity damageResult);
  Stream<List<DamageResultEntity>> streamDamageResults(String inspectionId);
}
