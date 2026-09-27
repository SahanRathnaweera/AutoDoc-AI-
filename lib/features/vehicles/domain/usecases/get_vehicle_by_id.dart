import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/vehicles/domain/entities/vehicle_entity.dart';
import 'package:autodoc_ai/features/vehicles/domain/repositories/vehicle_repository.dart';

class GetVehicleByIdParams extends Equatable {
  final String vehicleId;

  const GetVehicleByIdParams(this.vehicleId);

  @override
  List<Object?> get props => [vehicleId];
}

@lazySingleton
class GetVehicleById implements UseCase<VehicleEntity?, GetVehicleByIdParams> {
  final VehicleRepository _repository;

  GetVehicleById(this._repository);

  @override
  Future<Either<Failure, VehicleEntity?>> call(GetVehicleByIdParams params) {
    return _repository.getVehicleById(params.vehicleId);
  }
}
