import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:autodoc_ai/features/vehicles/domain/entities/vehicle_entity.dart';

class VehicleModel extends VehicleEntity {
  const VehicleModel({
    required super.vehicleId,
    required super.ownerId,
    required super.registrationNumber,
    required super.chassisNumber,
    super.engineNumber,
    required super.make,
    required super.model,
    required super.year,
    required super.odometer,
    super.fuelType,
    super.transmission,
    super.documentUrls,
    super.createdAt,
    super.updatedAt,
  });

  factory VehicleModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return VehicleModel(
      vehicleId: id ?? map['vehicleId'] as String? ?? map['id'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      registrationNumber: map['registrationNumber'] as String? ?? '',
      chassisNumber: map['chassisNumber'] as String? ?? '',
      engineNumber: map['engineNumber'] as String?,
      make: map['make'] as String? ?? '',
      model: map['model'] as String? ?? '',
      year: (map['year'] as num?)?.toInt() ?? 0,
      odometer: (map['odometer'] as num?)?.toInt() ?? 0,
      fuelType: map['fuelType'] as String?,
      transmission: map['transmission'] as String?,
      documentUrls: (map['documentUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'ownerId': ownerId,
      'registrationNumber': registrationNumber,
      'chassisNumber': chassisNumber,
      if (engineNumber != null) 'engineNumber': engineNumber,
      'make': make,
      'model': model,
      'year': year,
      'odometer': odometer,
      if (fuelType != null) 'fuelType': fuelType,
      if (transmission != null) 'transmission': transmission,
      'documentUrls': documentUrls,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  VehicleModel copyWith({
    String? vehicleId,
    String? ownerId,
    String? registrationNumber,
    String? chassisNumber,
    String? engineNumber,
    String? make,
    String? model,
    int? year,
    int? odometer,
    String? fuelType,
    String? transmission,
    List<String>? documentUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleModel(
      vehicleId: vehicleId ?? this.vehicleId,
      ownerId: ownerId ?? this.ownerId,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      chassisNumber: chassisNumber ?? this.chassisNumber,
      engineNumber: engineNumber ?? this.engineNumber,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      odometer: odometer ?? this.odometer,
      fuelType: fuelType ?? this.fuelType,
      transmission: transmission ?? this.transmission,
      documentUrls: documentUrls ?? this.documentUrls,
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
