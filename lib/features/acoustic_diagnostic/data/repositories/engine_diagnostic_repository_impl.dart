import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/exceptions.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/acoustic_diagnostic/data/datasources/engine_diagnostic_remote_data_source.dart';
import 'package:autodoc_ai/features/acoustic_diagnostic/data/models/engine_diagnostic_model.dart';
import 'package:autodoc_ai/features/acoustic_diagnostic/domain/entities/engine_diagnostic_entity.dart';
import 'package:autodoc_ai/features/acoustic_diagnostic/domain/repositories/engine_diagnostic_repository.dart';

@LazySingleton(as: EngineDiagnosticRepository)
class EngineDiagnosticRepositoryImpl implements EngineDiagnosticRepository {
  final EngineDiagnosticRemoteDataSource _remoteDataSource;

  EngineDiagnosticRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<EngineDiagnosticEntity>>> getDiagnosticsByInspection(String inspectionId) async {
    try {
      final results = await _remoteDataSource.getDiagnosticsByInspection(inspectionId);
      return Right(results);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(e.message, e.code));
    } catch (e) {
      return Left(FirestoreFailure('Failed to fetch engine diagnostics: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> saveDiagnosticResult(EngineDiagnosticEntity diagnostic) async {
    try {
      final model = _toModel(diagnostic);
      final id = await _remoteDataSource.saveDiagnosticResult(model);
      return Right(id);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(e.message, e.code));
    } catch (e) {
      return Left(FirestoreFailure('Failed to save engine diagnostic: $e'));
    }
  }

  @override
  Stream<List<EngineDiagnosticEntity>> streamDiagnostics(String inspectionId) {
    return _remoteDataSource.streamDiagnostics(inspectionId);
  }

  EngineDiagnosticModel _toModel(EngineDiagnosticEntity entity) {
    if (entity is EngineDiagnosticModel) return entity;
    return EngineDiagnosticModel(
      diagnosticId: entity.diagnosticId,
      inspectionId: entity.inspectionId,
      vehicleId: entity.vehicleId,
      audioStoragePath: entity.audioStoragePath,
      durationSeconds: entity.durationSeconds,
      status: entity.status,
      anomalyDetected: entity.anomalyDetected,
      anomalyType: entity.anomalyType,
      confidence: entity.confidence,
      spectralFeatures: entity.spectralFeatures,
      createdAt: entity.createdAt,
    );
  }
}
