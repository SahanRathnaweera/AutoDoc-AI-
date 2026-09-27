import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/vehicles/domain/repositories/vehicle_repository.dart';

class DeleteVehicleParams extends Equatable {
  final String vehicleId;

  const DeleteVehicleParams(this.vehicleId);

  @override
  List<Object?> get props => [vehicleId];
}

@lazySingleton
class DeleteVehicle implements UseCase<void, DeleteVehicleParams> {
  final VehicleRepository _repository;

  DeleteVehicle(this._repository);

  @override
  Future<Either<Failure, void>> call(DeleteVehicleParams params) {
    return _repository.deleteVehicle(params.vehicleId);
  }
}
