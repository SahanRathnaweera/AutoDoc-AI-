import 'package:equatable/equatable.dart';

class DamageResultEntity extends Equatable {
  final String damageId;
  final String inspectionId;
  final String vehicleId;
  final String imageStoragePath;
  final String? annotatedImagePath;
  final String damageType;
  final String severity;
  final double confidence;
  final String bodyLocation;
  final double? estimatedRepairCost;
  final DateTime? createdAt;

  const DamageResultEntity({
    required this.damageId,
    required this.inspectionId,
    required this.vehicleId,
    required this.imageStoragePath,
    this.annotatedImagePath,
    required this.damageType,
    required this.severity,
    required this.confidence,
    required this.bodyLocation,
    this.estimatedRepairCost,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        damageId,
        inspectionId,
        vehicleId,
        imageStoragePath,
        annotatedImagePath,
        damageType,
        severity,
        confidence,
        bodyLocation,
        estimatedRepairCost,
        createdAt,
      ];
}
