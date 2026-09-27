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
