import 'dart:io';

void main() {
  final files = <String, String>{
    r"lib/core/storage/storage_validator.dart": r'''
import 'dart:io';
import 'package:autodoc_ai/core/error/exceptions.dart';

class StorageValidator {
  static const int maxImageSizeBytes = 10 * 1024 * 1024;
  static const int maxAudioSizeBytes = 25 * 1024 * 1024;
  static const int maxDocumentSizeBytes = 20 * 1024 * 1024;

  static const Map<String, String> allowedImageExtensions = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
  };

  static const Map<String, String> allowedAudioExtensions = {
    'wav': 'audio/wav',
    'mp3': 'audio/mpeg',
    'm4a': 'audio/mp4',
    'aac': 'audio/aac',
  };

  static const Map<String, String> allowedDocumentExtensions = {
    'pdf': 'application/pdf',
  };

  static String validateImage(File file) {
    _ensureFileExists(file);
    final ext = _getExtension(file.path);
    final mime = allowedImageExtensions[ext];
    if (mime == null) {
      throw StorageException('Unsupported image extension: .' + ext, code: 'invalid-mime-type');
    }
    _ensureFileSize(file, maxImageSizeBytes, 'Image');
    return mime;
  }

  static String validateAudio(File file) {
    _ensureFileExists(file);
    final ext = _getExtension(file.path);
    final mime = allowedAudioExtensions[ext];
    if (mime == null) {
      throw StorageException('Unsupported audio extension: .' + ext, code: 'invalid-mime-type');
    }
    _ensureFileSize(file, maxAudioSizeBytes, 'Audio');
    return mime;
  }

  static String validateDocument(File file) {
    _ensureFileExists(file);
    final ext = _getExtension(file.path);
    final mime = allowedDocumentExtensions[ext];
    if (mime == null) {
      throw StorageException('Unsupported document extension: .' + ext, code: 'invalid-mime-type');
    }
    _ensureFileSize(file, maxDocumentSizeBytes, 'Document');
    return mime;
  }

  static void _ensureFileExists(File file) {
    if (!file.existsSync()) {
      throw const StorageException('File does not exist at local path', code: 'object-not-found');
    }
  }

  static void _ensureFileSize(File file, int maxBytes, String fileType) {
    final size = file.lengthSync();
    if (size > maxBytes) {
      throw StorageException(
        fileType + ' file size (' + (size / (1024 * 1024)).toStringAsFixed(1) + ' MB) exceeds allowed limit of ' + (maxBytes / (1024 * 1024)).toStringAsFixed(1) + ' MB',
        code: 'file-too-large',
      );
    }
  }

  static String _getExtension(String path) {
    final parts = path.split('.');
    if (parts.length < 2) return '';
    return parts.last.toLowerCase().trim();
  }
}
''',
    r"lib/features/storage/domain/entities/upload_result_entity.dart": r'''
import 'package:equatable/equatable.dart';

class UploadResultEntity extends Equatable {
  final String storagePath;
  final String downloadUrl;
  final String contentType;
  final int sizeBytes;
  final DateTime uploadedAt;

  const UploadResultEntity({
    required this.storagePath,
    required this.downloadUrl,
    required this.contentType,
    required this.sizeBytes,
    required this.uploadedAt,
  });

  @override
  List<Object?> get props => [storagePath, downloadUrl, contentType, sizeBytes, uploadedAt];
}
''',
    r"lib/features/storage/domain/repositories/storage_repository.dart": r'''
import 'dart:io';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/storage/domain/entities/upload_result_entity.dart';

abstract class StorageRepository {
  Future<Either<Failure, UploadResultEntity>> uploadVehiclePhoto({required String vehicleId, required File file, required String fileName});
  Future<Either<Failure, UploadResultEntity>> uploadInspectionPhoto({required String inspectionId, required File file, required String fileName});
  Future<Either<Failure, UploadResultEntity>> uploadInspectionAudio({required String inspectionId, required File file, required String fileName});
  Future<Either<Failure, UploadResultEntity>> uploadUserProfilePhoto({required String userId, required File file, required String fileName});
  Future<Either<Failure, UploadResultEntity>> uploadVehicleDocument({required String vehicleId, required File file, required String fileName});
  Future<Either<Failure, UploadResultEntity>> uploadRawBytes({required String storagePath, required Uint8List bytes, required String contentType});
  Future<Either<Failure, String>> getDownloadUrl(String storagePath);
  Future<Either<Failure, void>> deleteFile(String storagePath);
}
''',
    r"lib/features/storage/data/datasources/storage_remote_data_source.dart": r'''
import 'dart:io';
import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/services/firebase_storage_service.dart';

abstract class StorageRemoteDataSource {
  Future<String> uploadFile({required String storagePath, required File file, required String contentType});
  Future<String> uploadBytes({required String storagePath, required Uint8List bytes, required String contentType});
  Future<String> getDownloadUrl(String storagePath);
  Future<void> deleteFile(String storagePath);
}

@LazySingleton(as: StorageRemoteDataSource)
class StorageRemoteDataSourceImpl implements StorageRemoteDataSource {
  final FirebaseStorageService _storageService;
  StorageRemoteDataSourceImpl(this._storageService);

  @override
  Future<String> uploadFile({required String storagePath, required File file, required String contentType}) async {
    return _storageService.uploadFile(path: storagePath, file: file, metadata: {'contentType': contentType});
  }

  @override
  Future<String> uploadBytes({required String storagePath, required Uint8List bytes, required String contentType}) async {
    return _storageService.uploadBytes(path: storagePath, bytes: bytes, metadata: {'contentType': contentType});
  }

  @override
  Future<String> getDownloadUrl(String storagePath) async => _storageService.getDownloadUrl(storagePath);

  @override
  Future<void> deleteFile(String storagePath) async => _storageService.deleteFile(storagePath);
}
''',
    r"lib/features/storage/data/repositories/storage_repository_impl.dart": r'''
import 'dart:io';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/constants/storage_paths.dart';
import 'package:autodoc_ai/core/error/exceptions.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/storage/storage_validator.dart';
import 'package:autodoc_ai/features/storage/data/datasources/storage_remote_data_source.dart';
import 'package:autodoc_ai/features/storage/domain/entities/upload_result_entity.dart';
import 'package:autodoc_ai/features/storage/domain/repositories/storage_repository.dart';

@LazySingleton(as: StorageRepository)
class StorageRepositoryImpl implements StorageRepository {
  final StorageRemoteDataSource _remoteDataSource;
  StorageRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, UploadResultEntity>> uploadVehiclePhoto({required String vehicleId, required File file, required String fileName}) async {
    try {
      final contentType = StorageValidator.validateImage(file);
      final storagePath = StoragePaths.vehicleImage(vehicleId, fileName);
      final downloadUrl = await _remoteDataSource.uploadFile(storagePath: storagePath, file: file, contentType: contentType);
      return Right(UploadResultEntity(storagePath: storagePath, downloadUrl: downloadUrl, contentType: contentType, sizeBytes: file.lengthSync(), uploadedAt: DateTime.now()));
    } catch (e) {
      return Left(_mapToFailure(e));
    }
  }

  @override
  Future<Either<Failure, UploadResultEntity>> uploadInspectionPhoto({required String inspectionId, required File file, required String fileName}) async {
    try {
      final contentType = StorageValidator.validateImage(file);
      final storagePath = StoragePaths.inspectionImage(inspectionId, fileName);
      final downloadUrl = await _remoteDataSource.uploadFile(storagePath: storagePath, file: file, contentType: contentType);
      return Right(UploadResultEntity(storagePath: storagePath, downloadUrl: downloadUrl, contentType: contentType, sizeBytes: file.lengthSync(), uploadedAt: DateTime.now()));
    } catch (e) {
      return Left(_mapToFailure(e));
    }
  }

  @override
  Future<Either<Failure, UploadResultEntity>> uploadInspectionAudio({required String inspectionId, required File file, required String fileName}) async {
    try {
      final contentType = StorageValidator.validateAudio(file);
      final storagePath = StoragePaths.inspectionAudio(inspectionId, fileName);
      final downloadUrl = await _remoteDataSource.uploadFile(storagePath: storagePath, file: file, contentType: contentType);
      return Right(UploadResultEntity(storagePath: storagePath, downloadUrl: downloadUrl, contentType: contentType, sizeBytes: file.lengthSync(), uploadedAt: DateTime.now()));
    } catch (e) {
      return Left(_mapToFailure(e));
    }
  }

  @override
  Future<Either<Failure, UploadResultEntity>> uploadUserProfilePhoto({required String userId, required File file, required String fileName}) async {
    try {
      final contentType = StorageValidator.validateImage(file);
      final storagePath = StoragePaths.userAvatar(userId, fileName);
      final downloadUrl = await _remoteDataSource.uploadFile(storagePath: storagePath, file: file, contentType: contentType);
      return Right(UploadResultEntity(storagePath: storagePath, downloadUrl: downloadUrl, contentType: contentType, sizeBytes: file.lengthSync(), uploadedAt: DateTime.now()));
    } catch (e) {
      return Left(_mapToFailure(e));
    }
  }

  @override
  Future<Either<Failure, UploadResultEntity>> uploadVehicleDocument({required String vehicleId, required File file, required String fileName}) async {
    try {
      final contentType = StorageValidator.validateDocument(file);
      final storagePath = StoragePaths.vehicleDocument(vehicleId, fileName);
      final downloadUrl = await _remoteDataSource.uploadFile(storagePath: storagePath, file: file, contentType: contentType);
      return Right(UploadResultEntity(storagePath: storagePath, downloadUrl: downloadUrl, contentType: contentType, sizeBytes: file.lengthSync(), uploadedAt: DateTime.now()));
    } catch (e) {
      return Left(_mapToFailure(e));
    }
  }

  @override
  Future<Either<Failure, UploadResultEntity>> uploadRawBytes({required String storagePath, required Uint8List bytes, required String contentType}) async {
    try {
      final downloadUrl = await _remoteDataSource.uploadBytes(storagePath: storagePath, bytes: bytes, contentType: contentType);
      return Right(UploadResultEntity(storagePath: storagePath, downloadUrl: downloadUrl, contentType: contentType, sizeBytes: bytes.lengthInBytes, uploadedAt: DateTime.now()));
    } catch (e) {
      return Left(_mapToFailure(e));
    }
  }

  @override
  Future<Either<Failure, String>> getDownloadUrl(String storagePath) async {
    try {
      return Right(await _remoteDataSource.getDownloadUrl(storagePath));
    } catch (e) {
      return Left(_mapToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFile(String storagePath) async {
    try {
      await _remoteDataSource.deleteFile(storagePath);
      return const Right(null);
    } catch (e) {
      return Left(_mapToFailure(e));
    }
  }

  Failure _mapToFailure(dynamic error) {
    if (error is StorageException) {
      switch (error.code) {
        case 'quota-exceeded':
          return StorageQuotaExceededFailure(error.message, error.code);
        case 'object-not-found':
          return StorageFileNotFoundFailure(error.message, error.code);
        case 'unauthorized':
          return StorageUnauthorizedFailure(error.message, error.code);
        case 'invalid-mime-type':
          return InvalidMimeTypeFailure(error.message, error.code);
        case 'file-too-large':
          return FileTooLargeFailure(error.message, error.code);
        default:
          return StorageFailure(error.message, error.code);
      }
    }
    return StorageFailure(error.toString(), 'unknown');
  }
}
''',
    r"lib/features/storage/domain/usecases/upload_vehicle_photo.dart": r'''
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/storage/domain/entities/upload_result_entity.dart';
import 'package:autodoc_ai/features/storage/domain/repositories/storage_repository.dart';

@lazySingleton
class UploadVehiclePhoto {
  final StorageRepository _repository;
  UploadVehiclePhoto(this._repository);
  Future<Either<Failure, UploadResultEntity>> call({required String vehicleId, required File file, required String fileName}) => _repository.uploadVehiclePhoto(vehicleId: vehicleId, file: file, fileName: fileName);
}
''',
    r"lib/features/storage/domain/usecases/upload_inspection_photo.dart": r'''
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/storage/domain/entities/upload_result_entity.dart';
import 'package:autodoc_ai/features/storage/domain/repositories/storage_repository.dart';

@lazySingleton
class UploadInspectionPhoto {
  final StorageRepository _repository;
  UploadInspectionPhoto(this._repository);
  Future<Either<Failure, UploadResultEntity>> call({required String inspectionId, required File file, required String fileName}) => _repository.uploadInspectionPhoto(inspectionId: inspectionId, file: file, fileName: fileName);
}
''',
    r"lib/features/storage/domain/usecases/upload_inspection_audio.dart": r'''
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/storage/domain/entities/upload_result_entity.dart';
import 'package:autodoc_ai/features/storage/domain/repositories/storage_repository.dart';

@lazySingleton
class UploadInspectionAudio {
  final StorageRepository _repository;
  UploadInspectionAudio(this._repository);
  Future<Either<Failure, UploadResultEntity>> call({required String inspectionId, required File file, required String fileName}) => _repository.uploadInspectionAudio(inspectionId: inspectionId, file: file, fileName: fileName);
}
''',
    r"lib/features/storage/domain/usecases/upload_user_profile_photo.dart": r'''
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/storage/domain/entities/upload_result_entity.dart';
import 'package:autodoc_ai/features/storage/domain/repositories/storage_repository.dart';

@lazySingleton
class UploadUserProfilePhoto {
  final StorageRepository _repository;
  UploadUserProfilePhoto(this._repository);
  Future<Either<Failure, UploadResultEntity>> call({required String userId, required File file, required String fileName}) => _repository.uploadUserProfilePhoto(userId: userId, file: file, fileName: fileName);
}
''',
    r"lib/features/storage/domain/usecases/upload_vehicle_document.dart": r'''
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/storage/domain/entities/upload_result_entity.dart';
import 'package:autodoc_ai/features/storage/domain/repositories/storage_repository.dart';

@lazySingleton
class UploadVehicleDocument {
  final StorageRepository _repository;
  UploadVehicleDocument(this._repository);
  Future<Either<Failure, UploadResultEntity>> call({required String vehicleId, required File file, required String fileName}) => _repository.uploadVehicleDocument(vehicleId: vehicleId, file: file, fileName: fileName);
}
''',
    r"lib/features/storage/domain/usecases/get_storage_download_url.dart": r'''
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/storage/domain/repositories/storage_repository.dart';

@lazySingleton
class GetStorageDownloadUrl {
  final StorageRepository _repository;
  GetStorageDownloadUrl(this._repository);
  Future<Either<Failure, String>> call(String storagePath) => _repository.getDownloadUrl(storagePath);
}
''',
    r"lib/features/storage/domain/usecases/delete_storage_file.dart": r'''
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/storage/domain/repositories/storage_repository.dart';

@lazySingleton
class DeleteStorageFile {
  final StorageRepository _repository;
  DeleteStorageFile(this._repository);
  Future<Either<Failure, void>> call(String storagePath) => _repository.deleteFile(storagePath);
}
''',
    r"test/core/storage/storage_validator_test.dart": r'''
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:autodoc_ai/core/error/exceptions.dart';
import 'package:autodoc_ai/core/storage/storage_validator.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('storage_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('StorageValidator.validateImage', () {
    test('returns image/jpeg for .jpg and .jpeg files', () {
      final file = File('${tempDir.path}/car.jpg')..writeAsBytesSync([1, 2, 3]);
      expect(StorageValidator.validateImage(file), 'image/jpeg');
    });

    test('returns image/png for .png files', () {
      final file = File('${tempDir.path}/car.png')..writeAsBytesSync([1, 2, 3]);
      expect(StorageValidator.validateImage(file), 'image/png');
    });

    test('throws StorageException for invalid extension', () {
      final file = File('${tempDir.path}/car.exe')..writeAsBytesSync([1, 2, 3]);
      expect(
        () => StorageValidator.validateImage(file),
        throwsA(isA<StorageException>().having((e) => e.code, 'code', 'invalid-mime-type')),
      );
    });

    test('throws StorageException if file does not exist', () {
      final file = File('${tempDir.path}/missing.jpg');
      expect(
        () => StorageValidator.validateImage(file),
        throwsA(isA<StorageException>().having((e) => e.code, 'code', 'object-not-found')),
      );
    });
  });

  group('StorageValidator.validateAudio', () {
    test('returns audio/wav for .wav file', () {
      final file = File('${tempDir.path}/engine.wav')..writeAsBytesSync([1, 2, 3]);
      expect(StorageValidator.validateAudio(file), 'audio/wav');
    });

    test('returns audio/mpeg for .mp3 file', () {
      final file = File('${tempDir.path}/engine.mp3')..writeAsBytesSync([1, 2, 3]);
      expect(StorageValidator.validateAudio(file), 'audio/mpeg');
    });

    test('throws StorageException for unsupported audio', () {
      final file = File('${tempDir.path}/engine.txt')..writeAsBytesSync([1, 2, 3]);
      expect(
        () => StorageValidator.validateAudio(file),
        throwsA(isA<StorageException>().having((e) => e.code, 'code', 'invalid-mime-type')),
      );
    });
  });

  group('StorageValidator.validateDocument', () {
    test('returns application/pdf for .pdf files', () {
      final file = File('${tempDir.path}/reg.pdf')..writeAsBytesSync([1, 2, 3]);
      expect(StorageValidator.validateDocument(file), 'application/pdf');
    });

    test('throws StorageException for invalid document type', () {
      final file = File('${tempDir.path}/doc.zip')..writeAsBytesSync([1, 2, 3]);
      expect(
        () => StorageValidator.validateDocument(file),
        throwsA(isA<StorageException>().having((e) => e.code, 'code', 'invalid-mime-type')),
      );
    });
  });
}
''',
    r"test/features/storage/data/repositories/storage_repository_impl_test.dart": r'''
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
          )).thenThrow(const StorageException('Quota exceeded', code: 'quota-exceeded'));

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
''',
    r"test/features/storage/domain/usecases/storage_usecases_test.dart": r'''
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
''',
  };

  for (final entry in files.entries) {
    final file = File(entry.key);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(entry.value.trimLeft());
    print('Created: ' + entry.key);
  }

  final failuresFile = File('lib/core/error/failures.dart');
  var fContent = failuresFile.readAsStringSync();
  if (!fContent.contains('StorageQuotaExceededFailure')) {
    fContent += r'''

class StorageQuotaExceededFailure extends StorageFailure {
  const StorageQuotaExceededFailure([super.message = 'Storage quota exceeded', super.code = 'quota-exceeded']);
}

class StorageFileNotFoundFailure extends StorageFailure {
  const StorageFileNotFoundFailure([super.message = 'File not found in storage', super.code = 'object-not-found']);
}

class StorageUnauthorizedFailure extends StorageFailure {
  const StorageUnauthorizedFailure([super.message = 'Unauthorized storage access', super.code = 'unauthorized']);
}

class InvalidMimeTypeFailure extends StorageFailure {
  const InvalidMimeTypeFailure([super.message = 'Unsupported file format or MIME type', super.code = 'invalid-mime-type']);
}

class FileTooLargeFailure extends StorageFailure {
  const FileTooLargeFailure([super.message = 'File size exceeds maximum allowed limit', super.code = 'file-too-large']);
}
''';
    failuresFile.writeAsStringSync(fContent);
    print('Updated: lib/core/error/failures.dart');
  }

  print('All 15 Cloud Storage files created successfully!');
}