import 'package:dartz/dartz.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/inspections/domain/entities/inspection_entity.dart';

abstract class InspectionRepository {
  Future<Either<Failure, InspectionEntity?>> getInspectionById(String inspectionId);
  Future<Either<Failure, List<InspectionEntity>>> getInspectionsByVehicle(String vehicleId);
  Future<Either<Failure, List<InspectionEntity>>> getInspectionsByUser(String userId);
  Future<Either<Failure, String>> createInspection(InspectionEntity inspection);
  Future<Either<Failure, void>> updateInspectionStatus(String inspectionId, String status);
  Stream<InspectionEntity?> streamInspection(String inspectionId);
}
