import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/exceptions.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/reports/data/datasources/report_remote_data_source.dart';
import 'package:autodoc_ai/features/reports/data/models/report_model.dart';
import 'package:autodoc_ai/features/reports/domain/entities/report_entity.dart';
import 'package:autodoc_ai/features/reports/domain/repositories/report_repository.dart';

@LazySingleton(as: ReportRepository)
class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource _remoteDataSource;

  ReportRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, ReportEntity?>> getReportById(String reportId) async {
    try {
      final report = await _remoteDataSource.getReportById(reportId);
      return Right(report);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(e.message, e.code));
    } catch (e) {
      return Left(FirestoreFailure('Failed to fetch report: $e'));
    }
  }

  @override
  Future<Either<Failure, ReportEntity?>> getReportByInspectionId(String inspectionId) async {
    try {
      final report = await _remoteDataSource.getReportByInspectionId(inspectionId);
      return Right(report);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(e.message, e.code));
    } catch (e) {
      return Left(FirestoreFailure('Failed to fetch report by inspection: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> saveReport(ReportEntity report) async {
    try {
      final model = _toModel(report);
      final id = await _remoteDataSource.saveReport(model);
      return Right(id);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(e.message, e.code));
    } catch (e) {
      return Left(FirestoreFailure('Failed to save report: $e'));
    }
  }

  @override
  Stream<ReportEntity?> streamReport(String reportId) {
    return _remoteDataSource.streamReport(reportId);
  }

  ReportModel _toModel(ReportEntity entity) {
    if (entity is ReportModel) return entity;
    return ReportModel(
      reportId: entity.reportId,
      inspectionId: entity.inspectionId,
      vehicleId: entity.vehicleId,
      userId: entity.userId,
      pdfStoragePath: entity.pdfStoragePath,
      pdfDownloadUrl: entity.pdfDownloadUrl,
      verificationIdentifier: entity.verificationIdentifier,
      status: entity.status,
      generatedAt: entity.generatedAt,
    );
  }
}
