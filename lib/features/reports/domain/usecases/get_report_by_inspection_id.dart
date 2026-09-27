import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/reports/domain/entities/report_entity.dart';
import 'package:autodoc_ai/features/reports/domain/repositories/report_repository.dart';

class GetReportByInspectionIdParams extends Equatable {
  final String inspectionId;

  const GetReportByInspectionIdParams(this.inspectionId);

  @override
  List<Object?> get props => [inspectionId];
}

@lazySingleton
class GetReportByInspectionId implements UseCase<ReportEntity?, GetReportByInspectionIdParams> {
  final ReportRepository _repository;

  GetReportByInspectionId(this._repository);

  @override
  Future<Either<Failure, ReportEntity?>> call(GetReportByInspectionIdParams params) {
    return _repository.getReportByInspectionId(params.inspectionId);
  }
}
