import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:autodoc_ai/core/error/exceptions.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/storage/data/datasources/storage_remote_data_source.dart';
import 'package:autodoc_ai/features/storage/data/repositories/storage_repository_impl.dart';

class MockStorageRemoteDataSource extends Mock implements StorageRemoteDataSource {}

class FakeFile extends Fake implements File {}

void main() {
  late MockStorageRemoteDataSource mockRemoteDataSource;
  late StorageRepositoryImpl repository;
  late Directory tempDir;

  setUpAll(() {
    registerFallbackValue(FakeFile());
  });

  setUp(() {
    mockRemoteDataSource = MockStorageRemoteDataSource();
    repository = StorageRepositoryImpl(mockRemoteDataSource);
    tempDir = Directory.systemTemp.createTempSync('repo_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('uploadVehiclePhoto', () {
    test('returns Right(UploadResultEntity) on successful upload', () async {
      final file = File('${tempDir.path}/car.jpg')..writeAsBytesSync([1, 2, 3]);

      when(() => mockRemoteDataSource.uploadFile(
            storagePath: any(named: 'storagePath'),
            file: any(named: 'file'),
            contentType: any(named: 'contentType'),
          )).thenAnswer((_) async => 'https://storage.googleapis.com/car.jpg');

      final result = await repository.uploadVehiclePhoto(
        vehicleId: 'veh_01',
        file: file,
        fileName: 'car.jpg',
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (uploadResult) {
          expect(uploadResult.downloadUrl, 'https://storage.googleapis.com/car.jpg');
          expect(uploadResult.storagePath, 'vehicles/veh_01/images/car.jpg');
          expect(uploadResult.contentType, 'image/jpeg');
        },
      );
    });

    test('returns Left(InvalidMimeTypeFailure) for unsupported extension', () async {
      final file = File('${tempDir.path}/car.bin')..writeAsBytesSync([1, 2, 3]);

      final result = await repository.uploadVehiclePhoto(
        vehicleId: 'veh_01',
        file: file,
        fileName: 'car.bin',
      );

      expect(result, const Left(InvalidMimeTypeFailure('Unsupported image extension: .bin', 'invalid-mime-type')));
    });

    test('returns Left(StorageQuotaExceededFailure) when storage quota is exceeded', () async {
      final file = File('${tempDir.path}/car.png')..writeAsBytesSync([1, 2, 3]);

      when(() => mockRemoteDataSource.uploadFile(
            storagePath: any(named: 'storagePath'),
            file: any(named: 'file'),
            contentType: any(named: 'contentType'),
          )).thenThrow(StorageException('Quota exceeded', code: 'quota-exceeded'));

      final result = await repository.uploadVehiclePhoto(
        vehicleId: 'veh_01',
        file: file,
        fileName: 'car.png',
      );

      expect(result, const Left(StorageQuotaExceededFailure('Quota exceeded', 'quota-exceeded')));
    });
  });

  group('uploadInspectionAudio', () {
    test('returns Right(UploadResultEntity) for valid WAV audio', () async {
      final file = File('${tempDir.path}/engine.wav')..writeAsBytesSync([1, 2, 3]);

      when(() => mockRemoteDataSource.uploadFile(
            storagePath: any(named: 'storagePath'),
            file: any(named: 'file'),
            contentType: any(named: 'contentType'),
          )).thenAnswer((_) async => 'https://storage.googleapis.com/engine.wav');

      final result = await repository.uploadInspectionAudio(
        inspectionId: 'insp_101',
        file: file,
        fileName: 'engine.wav',
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (uploadResult) {
          expect(uploadResult.downloadUrl, 'https://storage.googleapis.com/engine.wav');
          expect(uploadResult.storagePath, 'inspections/insp_101/audio/engine.wav');
          expect(uploadResult.contentType, 'audio/wav');
        },
      );
    });
  });

  group('getDownloadUrl and deleteFile', () {
    test('getDownloadUrl returns Right(url)', () async {
      when(() => mockRemoteDataSource.getDownloadUrl('path/to/file.pdf'))
          .thenAnswer((_) async => 'https://storage.googleapis.com/file.pdf');

      final result = await repository.getDownloadUrl('path/to/file.pdf');

      expect(result, const Right('https://storage.googleapis.com/file.pdf'));
    });

    test('deleteFile returns Right(null)', () async {
      when(() => mockRemoteDataSource.deleteFile('path/to/file.pdf'))
          .thenAnswer((_) async {});

      final result = await repository.deleteFile('path/to/file.pdf');

      expect(result, const Right(null));
    });
  });
}
