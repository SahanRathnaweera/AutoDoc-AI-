import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/vehicles/domain/entities/vehicle_entity.dart';
import 'package:autodoc_ai/features/vehicles/domain/repositories/vehicle_repository.dart';

class CreateVehicleParams extends Equatable {
  final VehicleEntity vehicle;

  const CreateVehicleParams(this.vehicle);

  @override
  List<Object?> get props => [vehicle];
}

@lazySingleton
class CreateVehicle implements UseCase<String, CreateVehicleParams> {
  final VehicleRepository _repository;

  CreateVehicle(this._repository);

  @override
  Future<Either<Failure, String>> call(CreateVehicleParams params) {
    return _repository.createVehicle(params.vehicle);
  }
}
