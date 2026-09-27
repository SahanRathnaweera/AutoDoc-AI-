import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:autodoc_ai/features/inspections/domain/entities/inspection_entity.dart';

class InspectionModel extends InspectionEntity {
  const InspectionModel({
    required super.inspectionId,
    required super.vehicleId,
    required super.userId,
    super.inspectorId,
    required super.status,
    required super.inspectionDate,
    super.overallScore,
    super.damageScore,
    super.engineScore,
    super.createdAt,
    super.updatedAt,
  });

  factory InspectionModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return InspectionModel(
      inspectionId: id ?? map['inspectionId'] as String? ?? map['id'] as String? ?? '',
      vehicleId: map['vehicleId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      inspectorId: map['inspectorId'] as String?,
      status: map['status'] as String? ?? 'pending',
      inspectionDate: _parseDateTime(map['inspectionDate']) ?? DateTime.now(),
      overallScore: (map['overallScore'] as num?)?.toDouble(),
      damageScore: (map['damageScore'] as num?)?.toDouble(),
      engineScore: (map['engineScore'] as num?)?.toDouble(),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'inspectionId': inspectionId,
      'vehicleId': vehicleId,
      'userId': userId,
      if (inspectorId != null) 'inspectorId': inspectorId,
      'status': status,
      'inspectionDate': Timestamp.fromDate(inspectionDate),
      if (overallScore != null) 'overallScore': overallScore,
      if (damageScore != null) 'damageScore': damageScore,
      if (engineScore != null) 'engineScore': engineScore,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  InspectionModel copyWith({
    String? inspectionId,
    String? vehicleId,
    String? userId,
    String? inspectorId,
    String? status,
    DateTime? inspectionDate,
    double? overallScore,
    double? damageScore,
    double? engineScore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InspectionModel(
      inspectionId: inspectionId ?? this.inspectionId,
      vehicleId: vehicleId ?? this.vehicleId,
      userId: userId ?? this.userId,
      inspectorId: inspectorId ?? this.inspectorId,
      status: status ?? this.status,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      overallScore: overallScore ?? this.overallScore,
      damageScore: damageScore ?? this.damageScore,
      engineScore: engineScore ?? this.engineScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
