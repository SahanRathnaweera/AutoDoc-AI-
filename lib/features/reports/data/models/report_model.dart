import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:autodoc_ai/features/reports/domain/entities/report_entity.dart';

class ReportModel extends ReportEntity {
  const ReportModel({
    required super.reportId,
    required super.inspectionId,
    required super.vehicleId,
    required super.userId,
    required super.pdfStoragePath,
    super.pdfDownloadUrl,
    required super.verificationIdentifier,
    required super.status,
    super.generatedAt,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return ReportModel(
      reportId: id ?? map['reportId'] as String? ?? map['id'] as String? ?? '',
      inspectionId: map['inspectionId'] as String? ?? '',
      vehicleId: map['vehicleId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      pdfStoragePath: map['pdfStoragePath'] as String? ?? '',
      pdfDownloadUrl: map['pdfDownloadUrl'] as String?,
      verificationIdentifier: map['verificationIdentifier'] as String? ?? '',
      status: map['status'] as String? ?? 'ready',
      generatedAt: _parseDateTime(map['generatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'inspectionId': inspectionId,
      'vehicleId': vehicleId,
      'userId': userId,
      'pdfStoragePath': pdfStoragePath,
      if (pdfDownloadUrl != null) 'pdfDownloadUrl': pdfDownloadUrl,
      'verificationIdentifier': verificationIdentifier,
      'status': status,
      if (generatedAt != null) 'generatedAt': Timestamp.fromDate(generatedAt!),
    };
  }

  ReportModel copyWith({
    String? reportId,
    String? inspectionId,
    String? vehicleId,
    String? userId,
    String? pdfStoragePath,
    String? pdfDownloadUrl,
    String? verificationIdentifier,
    String? status,
    DateTime? generatedAt,
  }) {
    return ReportModel(
      reportId: reportId ?? this.reportId,
      inspectionId: inspectionId ?? this.inspectionId,
      vehicleId: vehicleId ?? this.vehicleId,
      userId: userId ?? this.userId,
      pdfStoragePath: pdfStoragePath ?? this.pdfStoragePath,
      pdfDownloadUrl: pdfDownloadUrl ?? this.pdfDownloadUrl,
      verificationIdentifier: verificationIdentifier ?? this.verificationIdentifier,
      status: status ?? this.status,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value);
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }
}
