import 'package:dartz/dartz.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/vehicles/domain/entities/vehicle_entity.dart';

abstract class VehicleRepository {
  Future<Either<Failure, VehicleEntity?>> getVehicleById(String vehicleId);
  Future<Either<Failure, List<VehicleEntity>>> getVehiclesByOwner(String ownerId);
  Future<Either<Failure, String>> createVehicle(VehicleEntity vehicle);
  Future<Either<Failure, void>> updateVehicle(VehicleEntity vehicle);
  Future<Either<Failure, void>> deleteVehicle(String vehicleId);
  Stream<VehicleEntity?> streamVehicle(String vehicleId);
}
