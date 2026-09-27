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
