import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:autodoc_ai/features/damage_assessment/domain/entities/damage_result_entity.dart';

class DamageResultModel extends DamageResultEntity {
  const DamageResultModel({
    required super.damageId,
    required super.inspectionId,
    required super.vehicleId,
    required super.imageStoragePath,
    super.annotatedImagePath,
    required super.damageType,
    required super.severity,
    required super.confidence,
    required super.bodyLocation,
    super.estimatedRepairCost,
    super.createdAt,
  });

  factory DamageResultModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return DamageResultModel(
      damageId: id ?? map['damageId'] as String? ?? map['id'] as String? ?? '',
      inspectionId: map['inspectionId'] as String? ?? '',
      vehicleId: map['vehicleId'] as String? ?? '',
      imageStoragePath: map['imageStoragePath'] as String? ?? '',
      annotatedImagePath: map['annotatedImagePath'] as String?,
      damageType: map['damageType'] as String? ?? '',
      severity: map['severity'] as String? ?? 'minor',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      bodyLocation: map['bodyLocation'] as String? ?? '',
      estimatedRepairCost: (map['estimatedRepairCost'] as num?)?.toDouble(),
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'damageId': damageId,
      'inspectionId': inspectionId,
      'vehicleId': vehicleId,
      'imageStoragePath': imageStoragePath,
      if (annotatedImagePath != null) 'annotatedImagePath': annotatedImagePath,
      'damageType': damageType,
      'severity': severity,
      'confidence': confidence,
      'bodyLocation': bodyLocation,
      if (estimatedRepairCost != null) 'estimatedRepairCost': estimatedRepairCost,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  DamageResultModel copyWith({
    String? damageId,
    String? inspectionId,
    String? vehicleId,
    String? imageStoragePath,
    String? annotatedImagePath,
    String? damageType,
    String? severity,
    double? confidence,
    String? bodyLocation,
    double? estimatedRepairCost,
    DateTime? createdAt,
  }) {
    return DamageResultModel(
      damageId: damageId ?? this.damageId,
      inspectionId: inspectionId ?? this.inspectionId,
      vehicleId: vehicleId ?? this.vehicleId,
      imageStoragePath: imageStoragePath ?? this.imageStoragePath,
      annotatedImagePath: annotatedImagePath ?? this.annotatedImagePath,
      damageType: damageType ?? this.damageType,
      severity: severity ?? this.severity,
      confidence: confidence ?? this.confidence,
      bodyLocation: bodyLocation ?? this.bodyLocation,
      estimatedRepairCost: estimatedRepairCost ?? this.estimatedRepairCost,
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
