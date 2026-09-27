import 'package:equatable/equatable.dart';

class VehicleEntity extends Equatable {
  final String vehicleId;
  final String ownerId;
  final String registrationNumber;
  final String chassisNumber;
  final String? engineNumber;
  final String make;
  final String model;
  final int year;
  final int odometer;
  final String? fuelType;
  final String? transmission;
  final List<String> documentUrls;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VehicleEntity({
    required this.vehicleId,
    required this.ownerId,
    required this.registrationNumber,
    required this.chassisNumber,
    this.engineNumber,
    required this.make,
    required this.model,
    required this.year,
    required this.odometer,
    this.fuelType,
    this.transmission,
    this.documentUrls = const [],
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        vehicleId,
        ownerId,
        registrationNumber,
        chassisNumber,
        engineNumber,
        make,
        model,
        year,
        odometer,
        fuelType,
        transmission,
        documentUrls,
        createdAt,
        updatedAt,
      ];
}
