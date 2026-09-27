import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/inspections/domain/entities/inspection_entity.dart';
import 'package:autodoc_ai/features/inspections/domain/repositories/inspection_repository.dart';

class GetInspectionsByVehicleParams extends Equatable {
  final String vehicleId;

  const GetInspectionsByVehicleParams(this.vehicleId);

  @override
  List<Object?> get props => [vehicleId];
}

@lazySingleton
class GetInspectionsByVehicle implements UseCase<List<InspectionEntity>, GetInspectionsByVehicleParams> {
  final InspectionRepository _repository;

  GetInspectionsByVehicle(this._repository);

  @override
  Future<Either<Failure, List<InspectionEntity>>> call(GetInspectionsByVehicleParams params) {
    return _repository.getInspectionsByVehicle(params.vehicleId);
  }
}
