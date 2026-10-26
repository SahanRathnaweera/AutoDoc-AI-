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
