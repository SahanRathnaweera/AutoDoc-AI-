import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/vehicles/domain/entities/vehicle_entity.dart';
import 'package:autodoc_ai/features/vehicles/domain/repositories/vehicle_repository.dart';

class UpdateVehicleParams extends Equatable {
  final VehicleEntity vehicle;

  const UpdateVehicleParams(this.vehicle);

  @override
  List<Object?> get props => [vehicle];
}

@lazySingleton
class UpdateVehicle implements UseCase<void, UpdateVehicleParams> {
  final VehicleRepository _repository;

  UpdateVehicle(this._repository);

  @override
  Future<Either<Failure, void>> call(UpdateVehicleParams params) {
    return _repository.updateVehicle(params.vehicle);
  }
}
