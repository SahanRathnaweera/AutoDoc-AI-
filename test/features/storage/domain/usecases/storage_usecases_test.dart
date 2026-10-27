import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:autodoc_ai/features/storage/domain/entities/upload_result_entity.dart';
import 'package:autodoc_ai/features/storage/domain/repositories/storage_repository.dart';
import 'package:autodoc_ai/features/storage/domain/usecases/delete_storage_file.dart';
import 'package:autodoc_ai/features/storage/domain/usecases/get_storage_download_url.dart';
import 'package:autodoc_ai/features/storage/domain/usecases/upload_inspection_audio.dart';
import 'package:autodoc_ai/features/storage/domain/usecases/upload_inspection_photo.dart';
import 'package:autodoc_ai/features/storage/domain/usecases/upload_user_profile_photo.dart';
import 'package:autodoc_ai/features/storage/domain/usecases/upload_vehicle_document.dart';
import 'package:autodoc_ai/features/storage/domain/usecases/upload_vehicle_photo.dart';

class MockStorageRepository extends Mock implements StorageRepository {}

class FakeFile extends Fake implements File {}

void main() {
  late MockStorageRepository mockRepository;
  late File fakeFile;

  final testResult = UploadResultEntity(
    storagePath: 'vehicles/v1/images/car.jpg',
    downloadUrl: 'https://storage.googleapis.com/car.jpg',
    contentType: 'image/jpeg',
    sizeBytes: 1024,
    uploadedAt: DateTime(2026, 9, 27),
  );

  setUpAll(() {
    registerFallbackValue(FakeFile());
  });

  setUp(() {
    mockRepository = MockStorageRepository();
    fakeFile = FakeFile();
  });

  group('UploadVehiclePhoto', () {
    test('delegates to repository.uploadVehiclePhoto', () async {
      final useCase = UploadVehiclePhoto(mockRepository);
      when(() => mockRepository.uploadVehiclePhoto(
            vehicleId: 'v1',
            file: fakeFile,
            fileName: 'car.jpg',
          )).thenAnswer((_) async => Right(testResult));

      final result = await useCase(
        vehicleId: 'v1',
        file: fakeFile,
        fileName: 'car.jpg',
      );

      expect(result, Right(testResult));
      verify(() => mockRepository.uploadVehiclePhoto(
            vehicleId: 'v1',
            file: fakeFile,
            fileName: 'car.jpg',
          )).called(1);
    });
  });

  group('UploadInspectionPhoto', () {
    test('delegates to repository.uploadInspectionPhoto', () async {
      final useCase = UploadInspectionPhoto(mockRepository);
      when(() => mockRepository.uploadInspectionPhoto(
            inspectionId: 'i1',
            file: fakeFile,
            fileName: 'front.jpg',
          )).thenAnswer((_) async => Right(testResult));

      final result = await useCase(
        inspectionId: 'i1',
        file: fakeFile,
        fileName: 'front.jpg',
      );

      expect(result, Right(testResult));
      verify(() => mockRepository.uploadInspectionPhoto(
            inspectionId: 'i1',
            file: fakeFile,
            fileName: 'front.jpg',
          )).called(1);
    });
  });

  group('UploadInspectionAudio', () {
    test('delegates to repository.uploadInspectionAudio', () async {
      final useCase = UploadInspectionAudio(mockRepository);
      when(() => mockRepository.uploadInspectionAudio(
            inspectionId: 'i1',
            file: fakeFile,
            fileName: 'engine.wav',
          )).thenAnswer((_) async => Right(testResult));

      final result = await useCase(
        inspectionId: 'i1',
        file: fakeFile,
        fileName: 'engine.wav',
      );

      expect(result, Right(testResult));
      verify(() => mockRepository.uploadInspectionAudio(
            inspectionId: 'i1',
            file: fakeFile,
            fileName: 'engine.wav',
          )).called(1);
    });
  });

  group('UploadUserProfilePhoto', () {
    test('delegates to repository.uploadUserProfilePhoto', () async {
      final useCase = UploadUserProfilePhoto(mockRepository);
      when(() => mockRepository.uploadUserProfilePhoto(
            userId: 'u1',
            file: fakeFile,
            fileName: 'profile.jpg',
          )).thenAnswer((_) async => Right(testResult));

      final result = await useCase(
        userId: 'u1',
        file: fakeFile,
        fileName: 'profile.jpg',
      );

      expect(result, Right(testResult));
      verify(() => mockRepository.uploadUserProfilePhoto(
            userId: 'u1',
            file: fakeFile,
            fileName: 'profile.jpg',
          )).called(1);
    });
  });

  group('UploadVehicleDocument', () {
    test('delegates to repository.uploadVehicleDocument', () async {
      final useCase = UploadVehicleDocument(mockRepository);
      when(() => mockRepository.uploadVehicleDocument(
            vehicleId: 'v1',
            file: fakeFile,
            fileName: 'reg.pdf',
          )).thenAnswer((_) async => Right(testResult));

      final result = await useCase(
        vehicleId: 'v1',
        file: fakeFile,
        fileName: 'reg.pdf',
      );

      expect(result, Right(testResult));
      verify(() => mockRepository.uploadVehicleDocument(
            vehicleId: 'v1',
            file: fakeFile,
            fileName: 'reg.pdf',
          )).called(1);
    });
  });

  group('GetStorageDownloadUrl and DeleteStorageFile', () {
    test('GetStorageDownloadUrl delegates to repository.getDownloadUrl', () async {
      final useCase = GetStorageDownloadUrl(mockRepository);
      when(() => mockRepository.getDownloadUrl('path/to/file.jpg'))
          .thenAnswer((_) async => const Right('https://url.com'));

      final result = await useCase('path/to/file.jpg');

      expect(result, const Right('https://url.com'));
      verify(() => mockRepository.getDownloadUrl('path/to/file.jpg')).called(1);
    });

    test('DeleteStorageFile delegates to repository.deleteFile', () async {
      final useCase = DeleteStorageFile(mockRepository);
      when(() => mockRepository.deleteFile('path/to/file.jpg'))
          .thenAnswer((_) async => const Right(null));

      final result = await useCase('path/to/file.jpg');

      expect(result, const Right(null));
      verify(() => mockRepository.deleteFile('path/to/file.jpg')).called(1);
    });
  });
}
