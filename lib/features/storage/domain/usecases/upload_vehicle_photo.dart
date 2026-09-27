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
