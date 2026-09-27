import 'package:equatable/equatable.dart';

class InspectionEntity extends Equatable {
  final String inspectionId;
  final String vehicleId;
  final String userId;
  final String? inspectorId;
  final String status;
  final DateTime inspectionDate;
  final double? overallScore;
  final double? damageScore;
  final double? engineScore;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const InspectionEntity({
    required this.inspectionId,
    required this.vehicleId,
    required this.userId,
    this.inspectorId,
    required this.status,
    required this.inspectionDate,
    this.overallScore,
    this.damageScore,
    this.engineScore,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        inspectionId,
        vehicleId,
        userId,
        inspectorId,
        status,
        inspectionDate,
        overallScore,
        damageScore,
        engineScore,
        createdAt,
        updatedAt,
      ];
}
