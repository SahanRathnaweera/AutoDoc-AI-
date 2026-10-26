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
