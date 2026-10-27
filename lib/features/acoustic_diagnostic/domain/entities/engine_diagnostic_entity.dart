import 'package:equatable/equatable.dart';

class EngineDiagnosticEntity extends Equatable {
  final String diagnosticId;
  final String inspectionId;
  final String vehicleId;
  final String audioStoragePath;
  final double durationSeconds;
  final String status;
  final bool anomalyDetected;
  final String? anomalyType;
  final double confidence;
  final Map<String, dynamic>? spectralFeatures;
  final DateTime? createdAt;

  const EngineDiagnosticEntity({
    required this.diagnosticId,
    required this.inspectionId,
    required this.vehicleId,
    required this.audioStoragePath,
    required this.durationSeconds,
    required this.status,
    required this.anomalyDetected,
    this.anomalyType,
    required this.confidence,
    this.spectralFeatures,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        diagnosticId,
        inspectionId,
        vehicleId,
        audioStoragePath,
        durationSeconds,
        status,
        anomalyDetected,
        anomalyType,
        confidence,
        spectralFeatures,
        createdAt,
      ];
}
