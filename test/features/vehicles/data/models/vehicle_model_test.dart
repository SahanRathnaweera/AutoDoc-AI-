import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:autodoc_ai/features/vehicles/data/models/vehicle_model.dart';
import 'package:autodoc_ai/features/vehicles/domain/entities/vehicle_entity.dart';

void main() {
  final tTimestamp = Timestamp.fromDate(DateTime(2026, 9, 27, 10, 0, 0));
  final tDateTime = tTimestamp.toDate();

  final tVehicleModel = VehicleModel(
    vehicleId: 'veh_01',
    ownerId: 'usr_01',
    registrationNumber: 'CAB-1234',
    chassisNumber: 'VIN12345678901234',
    engineNumber: 'ENG-9988',
    make: 'Toyota',
    model: 'Corolla',
    year: 2021,
    odometer: 45000,
    fuelType: 'Petrol',
    transmission: 'Automatic',
    documentUrls: const ['https://example.com/doc1.pdf'],
    createdAt: tDateTime,
    updatedAt: tDateTime,
  );

  test('VehicleModel should be a subclass of VehicleEntity', () {
    expect(tVehicleModel, isA<VehicleEntity>());
  });

  test('fromMap parses valid map with Firestore Timestamp', () {
    final map = {
      'vehicleId': 'veh_01',
      'ownerId': 'usr_01',
      'registrationNumber': 'CAB-1234',
      'chassisNumber': 'VIN12345678901234',
      'engineNumber': 'ENG-9988',
      'make': 'Toyota',
      'model': 'Corolla',
      'year': 2021,
      'odometer': 45000,
      'fuelType': 'Petrol',
      'transmission': 'Automatic',
      'documentUrls': ['https://example.com/doc1.pdf'],
      'createdAt': tTimestamp,
      'updatedAt': tTimestamp,
    };

    final result = VehicleModel.fromMap(map);

    expect(result.vehicleId, 'veh_01');
    expect(result.make, 'Toyota');
    expect(result.year, 2021);
    expect(result.documentUrls.length, 1);
    expect(result.createdAt, tDateTime);
  });

  test('toMap produces serializable map with Timestamp', () {
    final map = tVehicleModel.toMap();

    expect(map['vehicleId'], 'veh_01');
    expect(map['ownerId'], 'usr_01');
    expect(map['registrationNumber'], 'CAB-1234');
    expect(map['year'], 2021);
    expect(map['createdAt'], isA<Timestamp>());
  });

  test('copyWith properly overrides fields', () {
    final updated = tVehicleModel.copyWith(odometer: 46000, make: 'Lexus');

    expect(updated.odometer, 46000);
    expect(updated.make, 'Lexus');
    expect(updated.model, 'Corolla');
    expect(updated.vehicleId, tVehicleModel.vehicleId);
  });
}
