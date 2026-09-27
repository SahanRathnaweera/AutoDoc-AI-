import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:autodoc_ai/core/error/exceptions.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/vehicles/data/datasources/vehicle_remote_data_source.dart';
import 'package:autodoc_ai/features/vehicles/data/models/vehicle_model.dart';
import 'package:autodoc_ai/features/vehicles/data/repositories/vehicle_repository_impl.dart';

class MockVehicleRemoteDataSource extends Mock implements VehicleRemoteDataSource {}

class FakeVehicleModel extends Fake implements VehicleModel {}

void main() {
  late MockVehicleRemoteDataSource mockRemoteDataSource;
  late VehicleRepositoryImpl repository;

  final tVehicleModel = VehicleModel(
    vehicleId: 'veh_01',
    ownerId: 'usr_01',
    registrationNumber: 'CAB-1234',
    chassisNumber: 'VIN12345678901234',
    make: 'Toyota',
    model: 'Corolla',
    year: 2021,
    odometer: 45000,
  );

  setUpAll(() {
    registerFallbackValue(FakeVehicleModel());
  });

  setUp(() {
    mockRemoteDataSource = MockVehicleRemoteDataSource();
    repository = VehicleRepositoryImpl(mockRemoteDataSource);
  });

  group('getVehicleById', () {
    test('returns Right(VehicleModel) on success', () async {
      when(() => mockRemoteDataSource.getVehicleById('veh_01'))
          .thenAnswer((_) async => tVehicleModel);

      final result = await repository.getVehicleById('veh_01');

      expect(result, Right(tVehicleModel));
      verify(() => mockRemoteDataSource.getVehicleById('veh_01')).called(1);
    });

    test('returns Left(FirestoreFailure) on FirestoreException', () async {
      when(() => mockRemoteDataSource.getVehicleById('veh_01'))
          .thenThrow(FirestoreException('Permission denied', code: 'permission-denied'));

      final result = await repository.getVehicleById('veh_01');

      expect(result, const Left(FirestoreFailure('Permission denied', 'permission-denied')));
    });
  });

  group('createVehicle', () {
    test('returns Right(vehicleId) on success', () async {
      when(() => mockRemoteDataSource.createVehicle(any()))
          .thenAnswer((_) async => 'veh_01');

      final result = await repository.createVehicle(tVehicleModel);

      expect(result, const Right('veh_01'));
    });
  });
}