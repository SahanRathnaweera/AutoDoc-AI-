import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:autodoc_ai/features/reports/data/models/report_model.dart';
import 'package:autodoc_ai/features/reports/domain/entities/report_entity.dart';

void main() {
  final tTimestamp = Timestamp.fromDate(DateTime(2026, 9, 27, 12, 30, 0));
  final tDateTime = tTimestamp.toDate();

  final tReportModel = ReportModel(
    reportId: 'rep_01',
    inspectionId: 'insp_101',
    vehicleId: 'veh_01',
    userId: 'usr_01',
    pdfStoragePath: 'reports/insp_101/report.pdf',
    pdfDownloadUrl: 'https://storage.googleapis.com/report.pdf',
    verificationIdentifier: 'v-hash-1234',
    status: 'ready',
    generatedAt: tDateTime,
  );

  test('ReportModel should be a subclass of ReportEntity', () {
    expect(tReportModel, isA<ReportEntity>());
  });

  test('fromMap parses valid map with verificationIdentifier', () {
    final map = {
      'reportId': 'rep_01',
      'inspectionId': 'insp_101',
      'vehicleId': 'veh_01',
      'userId': 'usr_01',
      'pdfStoragePath': 'reports/insp_101/report.pdf',
      'pdfDownloadUrl': 'https://storage.googleapis.com/report.pdf',
      'verificationIdentifier': 'v-hash-1234',
      'status': 'ready',
      'generatedAt': tTimestamp,
    };

    final result = ReportModel.fromMap(map);

    expect(result.reportId, 'rep_01');
    expect(result.verificationIdentifier, 'v-hash-1234');
    expect(result.status, 'ready');
  });

  test('toMap produces serializable map with Timestamp', () {
    final map = tReportModel.toMap();

    expect(map['reportId'], 'rep_01');
    expect(map['verificationIdentifier'], 'v-hash-1234');
    expect(map['generatedAt'], isA<Timestamp>());
  });
}
