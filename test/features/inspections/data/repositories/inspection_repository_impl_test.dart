import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:autodoc_ai/core/error/exceptions.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/inspections/data/datasources/inspection_remote_data_source.dart';
import 'package:autodoc_ai/features/inspections/data/models/inspection_model.dart';
import 'package:autodoc_ai/features/inspections/data/repositories/inspection_repository_impl.dart';

class MockInspectionRemoteDataSource extends Mock implements InspectionRemoteDataSource {}

class FakeInspectionModel extends Fake implements InspectionModel {}

void main() {
  late MockInspectionRemoteDataSource mockRemoteDataSource;
  late InspectionRepositoryImpl repository;

  final tInspectionModel = InspectionModel(
    inspectionId: 'insp_101',
    vehicleId: 'veh_01',
    userId: 'usr_01',
    status: 'pending',
    inspectionDate: DateTime(2026, 9, 27),
  );

  setUpAll(() {
    registerFallbackValue(FakeInspectionModel());
  });

  setUp(() {
    mockRemoteDataSource = MockInspectionRemoteDataSource();
    repository = InspectionRepositoryImpl(mockRemoteDataSource);
  });

  group('getInspectionById', () {
    test('returns Right(InspectionModel) on success', () async {
      when(() => mockRemoteDataSource.getInspectionById('insp_101'))
          .thenAnswer((_) async => tInspectionModel);

      final result = await repository.getInspectionById('insp_101');

      expect(result, Right(tInspectionModel));
      verify(() => mockRemoteDataSource.getInspectionById('insp_101')).called(1);
    });

    test('returns Left(FirestoreFailure) on FirestoreException', () async {
      when(() => mockRemoteDataSource.getInspectionById('insp_101'))
          .thenThrow(FirestoreException('Not found', code: 'not-found'));

      final result = await repository.getInspectionById('insp_101');

      expect(result, const Left(FirestoreFailure('Not found', 'not-found')));
    });
  });

  group('updateInspectionStatus', () {
    test('returns Right(null) on success', () async {
      when(() => mockRemoteDataSource.updateInspectionStatus('insp_101', 'completed'))
          .thenAnswer((_) async {});

      final result = await repository.updateInspectionStatus('insp_101', 'completed');

      expect(result, const Right(null));
    });
  });
}
