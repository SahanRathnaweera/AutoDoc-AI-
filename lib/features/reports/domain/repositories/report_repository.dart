import 'package:dartz/dartz.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/reports/domain/entities/report_entity.dart';

abstract class ReportRepository {
  Future<Either<Failure, ReportEntity?>> getReportById(String reportId);
  Future<Either<Failure, ReportEntity?>> getReportByInspectionId(String inspectionId);
  Future<Either<Failure, String>> saveReport(ReportEntity report);
  Stream<ReportEntity?> streamReport(String reportId);
}
