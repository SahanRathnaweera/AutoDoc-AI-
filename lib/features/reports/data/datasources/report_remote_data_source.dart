import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/firebase/firestore_collections.dart';
import 'package:autodoc_ai/core/firebase/firestore_service.dart';
import 'package:autodoc_ai/features/reports/data/models/report_model.dart';

abstract class ReportRemoteDataSource {
  Future<ReportModel?> getReportById(String reportId);
  Future<ReportModel?> getReportByInspectionId(String inspectionId);
  Future<String> saveReport(ReportModel report);
  Stream<ReportModel?> streamReport(String reportId);
}

@LazySingleton(as: ReportRemoteDataSource)
class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final FirestoreService _firestoreService;

  ReportRemoteDataSourceImpl(this._firestoreService);

  @override
  Future<ReportModel?> getReportById(String reportId) async {
    final data = await _firestoreService.getDocument(
      collectionPath: FirestoreCollections.reports,
      documentId: reportId,
    );
    if (data == null) return null;
    return ReportModel.fromMap(data, id: reportId);
  }

  @override
  Future<ReportModel?> getReportByInspectionId(String inspectionId) async {
    final docs = await _firestoreService.queryDocuments(
      collectionPath: FirestoreCollections.reports,
      queryBuilder: (query) => query.where('inspectionId', isEqualTo: inspectionId).limit(1),
    );
    if (docs.isEmpty) return null;
    return ReportModel.fromMap(docs.first, id: docs.first['id'] as String?);
  }

  @override
  Future<String> saveReport(ReportModel report) async {
    return _firestoreService.createDocument(
      collectionPath: FirestoreCollections.reports,
      documentId: report.reportId.isNotEmpty ? report.reportId : null,
      data: report.toMap(),
    );
  }

  @override
  Stream<ReportModel?> streamReport(String reportId) {
    return _firestoreService
        .streamDocument(
          collectionPath: FirestoreCollections.reports,
          documentId: reportId,
        )
        .map((data) => data == null ? null : ReportModel.fromMap(data, id: reportId));
  }
}
