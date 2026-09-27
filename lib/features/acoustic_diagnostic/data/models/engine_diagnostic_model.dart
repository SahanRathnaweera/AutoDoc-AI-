import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:autodoc_ai/features/acoustic_diagnostic/domain/entities/engine_diagnostic_entity.dart';

class EngineDiagnosticModel extends EngineDiagnosticEntity {
  const EngineDiagnosticModel({
    required super.diagnosticId,
    required super.inspectionId,
    required super.vehicleId,
    required super.audioStoragePath,
    required super.durationSeconds,
    required super.status,
    required super.anomalyDetected,
    super.anomalyType,
    required super.confidence,
    super.spectralFeatures,
    super.createdAt,
  });

  factory EngineDiagnosticModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return EngineDiagnosticModel(
      diagnosticId: id ?? map['diagnosticId'] as String? ?? map['id'] as String? ?? '',
      inspectionId: map['inspectionId'] as String? ?? '',
      vehicleId: map['vehicleId'] as String? ?? '',
      audioStoragePath: map['audioStoragePath'] as String? ?? '',
      durationSeconds: (map['durationSeconds'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'completed',
      anomalyDetected: map['anomalyDetected'] as bool? ?? false,
      anomalyType: map['anomalyType'] as String?,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      spectralFeatures: map['spectralFeatures'] != null
          ? Map<String, dynamic>.from(map['spectralFeatures'] as Map)
          : null,
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'diagnosticId': diagnosticId,
      'inspectionId': inspectionId,
      'vehicleId': vehicleId,
      'audioStoragePath': audioStoragePath,
      'durationSeconds': durationSeconds,
      'status': status,
      'anomalyDetected': anomalyDetected,
      if (anomalyType != null) 'anomalyType': anomalyType,
      'confidence': confidence,
      if (spectralFeatures != null) 'spectralFeatures': spectralFeatures,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  EngineDiagnosticModel copyWith({
    String? diagnosticId,
    String? inspectionId,
    String? vehicleId,
    String? audioStoragePath,
    double? durationSeconds,
    String? status,
    bool? anomalyDetected,
    String? anomalyType,
    double? confidence,
    Map<String, dynamic>? spectralFeatures,
    DateTime? createdAt,
  }) {
    return EngineDiagnosticModel(
      diagnosticId: diagnosticId ?? this.diagnosticId,
      inspectionId: inspectionId ?? this.inspectionId,
      vehicleId: vehicleId ?? this.vehicleId,
      audioStoragePath: audioStoragePath ?? this.audioStoragePath,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      status: status ?? this.status,
      anomalyDetected: anomalyDetected ?? this.anomalyDetected,
      anomalyType: anomalyType ?? this.anomalyType,
      confidence: confidence ?? this.confidence,
      spectralFeatures: spectralFeatures ?? this.spectralFeatures,
      createdAt: createdAt ?? this.createdAt,
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
