import 'package:equatable/equatable.dart';

class ReportEntity extends Equatable {
  final String reportId;
  final String inspectionId;
  final String vehicleId;
  final String userId;
  final String pdfStoragePath;
  final String? pdfDownloadUrl;
  final String verificationIdentifier;
  final String status;
  final DateTime? generatedAt;

  const ReportEntity({
    required this.reportId,
    required this.inspectionId,
    required this.vehicleId,
    required this.userId,
    required this.pdfStoragePath,
    this.pdfDownloadUrl,
    required this.verificationIdentifier,
    required this.status,
    this.generatedAt,
  });

  @override
  List<Object?> get props => [
        reportId,
        inspectionId,
        vehicleId,
        userId,
        pdfStoragePath,
        pdfDownloadUrl,
        verificationIdentifier,
        status,
        generatedAt,
      ];
}
