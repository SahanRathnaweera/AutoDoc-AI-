import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/inspections/domain/entities/inspection_entity.dart';
import 'package:autodoc_ai/features/inspections/domain/repositories/inspection_repository.dart';

class GetInspectionsByUserParams extends Equatable {
  final String userId;

  const GetInspectionsByUserParams(this.userId);

  @override
  List<Object?> get props => [userId];
}

@lazySingleton
class GetInspectionsByUser implements UseCase<List<InspectionEntity>, GetInspectionsByUserParams> {
  final InspectionRepository _repository;

  GetInspectionsByUser(this._repository);

  @override
  Future<Either<Failure, List<InspectionEntity>>> call(GetInspectionsByUserParams params) {
    return _repository.getInspectionsByUser(params.userId);
  }
}
