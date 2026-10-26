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
