import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/reports/domain/entities/report_entity.dart';
import 'package:autodoc_ai/features/reports/domain/repositories/report_repository.dart';

class GetReportByIdParams extends Equatable {
  final String reportId;

  const GetReportByIdParams(this.reportId);

  @override
  List<Object?> get props => [reportId];
}

@lazySingleton
class GetReportById implements UseCase<ReportEntity?, GetReportByIdParams> {
  final ReportRepository _repository;

  GetReportById(this._repository);

  @override
  Future<Either<Failure, ReportEntity?>> call(GetReportByIdParams params) {
    return _repository.getReportById(params.reportId);
  }
}
