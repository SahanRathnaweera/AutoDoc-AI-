import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/vehicles/domain/entities/vehicle_entity.dart';
import 'package:autodoc_ai/features/vehicles/domain/repositories/vehicle_repository.dart';

class GetVehiclesByOwnerParams extends Equatable {
  final String ownerId;

  const GetVehiclesByOwnerParams(this.ownerId);

  @override
  List<Object?> get props => [ownerId];
}

@lazySingleton
class GetVehiclesByOwner implements UseCase<List<VehicleEntity>, GetVehiclesByOwnerParams> {
  final VehicleRepository _repository;

  GetVehiclesByOwner(this._repository);

  @override
  Future<Either<Failure, List<VehicleEntity>>> call(GetVehiclesByOwnerParams params) {
    return _repository.getVehiclesByOwner(params.ownerId);
  }
}
