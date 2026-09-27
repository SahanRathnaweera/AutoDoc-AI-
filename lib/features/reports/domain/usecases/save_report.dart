import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/reports/domain/entities/report_entity.dart';
import 'package:autodoc_ai/features/reports/domain/repositories/report_repository.dart';

class SaveReportParams extends Equatable {
  final ReportEntity report;

  const SaveReportParams(this.report);

  @override
  List<Object?> get props => [report];
}

@lazySingleton
class SaveReport implements UseCase<String, SaveReportParams> {
  final ReportRepository _repository;

  SaveReport(this._repository);

  @override
  Future<Either<Failure, String>> call(SaveReportParams params) {
    return _repository.saveReport(params.report);
  }
}
