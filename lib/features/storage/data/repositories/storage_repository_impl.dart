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
