import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/exceptions.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/vehicles/data/datasources/vehicle_remote_data_source.dart';
import 'package:autodoc_ai/features/vehicles/data/models/vehicle_model.dart';
import 'package:autodoc_ai/features/vehicles/domain/entities/vehicle_entity.dart';
import 'package:autodoc_ai/features/vehicles/domain/repositories/vehicle_repository.dart';

@LazySingleton(as: VehicleRepository)
class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleRemoteDataSource _remoteDataSource;

  VehicleRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, VehicleEntity?>> getVehicleById(String vehicleId) async {
    try {
      final vehicle = await _remoteDataSource.getVehicleById(vehicleId);
      return Right(vehicle);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(e.message, e.code));
    } catch (e) {
      return Left(FirestoreFailure('Failed to fetch vehicle: $e'));
    }
  }

  @override
  Future<Either<Failure, List<VehicleEntity>>> getVehiclesByOwner(String ownerId) async {
    try {
      final vehicles = await _remoteDataSource.getVehiclesByOwner(ownerId);
      return Right(vehicles);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(e.message, e.code));
    } catch (e) {
      return Left(FirestoreFailure('Failed to fetch vehicles for owner: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> createVehicle(VehicleEntity vehicle) async {
    try {
      final model = _toModel(vehicle);
      final id = await _remoteDataSource.createVehicle(model);
      return Right(id);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(e.message, e.code));
    } catch (e) {
      return Left(FirestoreFailure('Failed to create vehicle: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateVehicle(VehicleEntity vehicle) async {
    try {
      final model = _toModel(vehicle);
      await _remoteDataSource.updateVehicle(model);
      return const Right(null);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(e.message, e.code));
    } catch (e) {
      return Left(FirestoreFailure('Failed to update vehicle: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteVehicle(String vehicleId) async {
    try {
      await _remoteDataSource.deleteVehicle(vehicleId);
      return const Right(null);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(e.message, e.code));
    } catch (e) {
      return Left(FirestoreFailure('Failed to delete vehicle: $e'));
    }
  }

  @override
  Stream<VehicleEntity?> streamVehicle(String vehicleId) {
    return _remoteDataSource.streamVehicle(vehicleId);
  }

  VehicleModel _toModel(VehicleEntity entity) {
    if (entity is VehicleModel) return entity;
    return VehicleModel(
      vehicleId: entity.vehicleId,
      ownerId: entity.ownerId,
      registrationNumber: entity.registrationNumber,
      chassisNumber: entity.chassisNumber,
      engineNumber: entity.engineNumber,
      make: entity.make,
      model: entity.model,
      year: entity.year,
      odometer: entity.odometer,
      fuelType: entity.fuelType,
      transmission: entity.transmission,
      documentUrls: entity.documentUrls,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
