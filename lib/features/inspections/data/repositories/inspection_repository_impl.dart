import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/exceptions.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/inspections/data/datasources/inspection_remote_data_source.dart';
import 'package:autodoc_ai/features/inspections/data/models/inspection_model.dart';
import 'package:autodoc_ai/features/inspections/domain/entities/inspection_entity.dart';
import 'package:autodoc_ai/features/inspections/domain/repositories/inspection_repository.dart';

@LazySingleton(as: InspectionRepository)
class InspectionRepositoryImpl implements InspectionRepository {
  final InspectionRemoteDataSource _remoteDataSource;

  InspectionRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, InspectionEntity?>> getInspectionById(String inspectionId) async {
    try {
      final inspection = await _remoteDataSource.getInspectionById(inspectionId);
      return Right(inspection);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(e.message, e.code));
    } catch (e) {
      return Left(FirestoreFailure('Failed to fetch inspection: $e'));
    }
  }

  @override
  Future<Either<Failure, List<InspectionEntity>>> getInspectionsByVehicle(String vehicleId) async {
    try {
      final inspections = await _remoteDataSource.getInspectionsByVehicle(vehicleId);
      return Right(inspections);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(e.message, e.code));
    } catch (e) {
      return Left(FirestoreFailure('Failed to fetch vehicle inspections: $e'));
    }
  }

  @override
  Future<Either<Failure, List<InspectionEntity>>> getInspectionsByUser(String userId) async {
    try {
      final inspections = await _remoteDataSource.getInspectionsByUser(userId);
      return Right(inspections);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(e.message, e.code));
    } catch (e) {
      return Left(FirestoreFailure('Failed to fetch user inspections: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> createInspection(InspectionEntity inspection) async {
    try {
      final model = _toModel(inspection);
      final id = await _remoteDataSource.createInspection(model);
      return Right(id);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(e.message, e.code));
    } catch (e) {
      return Left(FirestoreFailure('Failed to create inspection: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateInspectionStatus(String inspectionId, String status) async {
    try {
      await _remoteDataSource.updateInspectionStatus(inspectionId, status);
      return const Right(null);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(e.message, e.code));
    } catch (e) {
      return Left(FirestoreFailure('Failed to update inspection status: $e'));
    }
  }

  @override
  Stream<InspectionEntity?> streamInspection(String inspectionId) {
    return _remoteDataSource.streamInspection(inspectionId);
  }

  InspectionModel _toModel(InspectionEntity entity) {
    if (entity is InspectionModel) return entity;
    return InspectionModel(
      inspectionId: entity.inspectionId,
      vehicleId: entity.vehicleId,
      userId: entity.userId,
      inspectorId: entity.inspectorId,
      status: entity.status,
      inspectionDate: entity.inspectionDate,
      overallScore: entity.overallScore,
      damageScore: entity.damageScore,
      engineScore: entity.engineScore,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
