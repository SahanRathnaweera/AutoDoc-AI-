import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/exceptions.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/damage_assessment/data/datasources/damage_remote_data_source.dart';
import 'package:autodoc_ai/features/damage_assessment/data/models/damage_result_model.dart';
import 'package:autodoc_ai/features/damage_assessment/domain/entities/damage_result_entity.dart';
import 'package:autodoc_ai/features/damage_assessment/domain/repositories/damage_repository.dart';

@LazySingleton(as: DamageRepository)
class DamageRepositoryImpl implements DamageRepository {
  final DamageRemoteDataSource _remoteDataSource;

  DamageRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<DamageResultEntity>>> getDamageResultsByInspection(String inspectionId) async {
    try {
      final results = await _remoteDataSource.getDamageResultsByInspection(inspectionId);
      return Right(results);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(e.message, e.code));
    } catch (e) {
      return Left(FirestoreFailure('Failed to fetch damage results: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> saveDamageResult(DamageResultEntity damageResult) async {
    try {
      final model = _toModel(damageResult);
      final id = await _remoteDataSource.saveDamageResult(model);
      return Right(id);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(e.message, e.code));
    } catch (e) {
      return Left(FirestoreFailure('Failed to save damage result: $e'));
    }
  }

  @override
  Stream<List<DamageResultEntity>> streamDamageResults(String inspectionId) {
    return _remoteDataSource.streamDamageResults(inspectionId);
  }

  DamageResultModel _toModel(DamageResultEntity entity) {
    if (entity is DamageResultModel) return entity;
    return DamageResultModel(
      damageId: entity.damageId,
      inspectionId: entity.inspectionId,
      vehicleId: entity.vehicleId,
      imageStoragePath: entity.imageStoragePath,
      annotatedImagePath: entity.annotatedImagePath,
      damageType: entity.damageType,
      severity: entity.severity,
      confidence: entity.confidence,
      bodyLocation: entity.bodyLocation,
      estimatedRepairCost: entity.estimatedRepairCost,
      createdAt: entity.createdAt,
    );
  }
}
