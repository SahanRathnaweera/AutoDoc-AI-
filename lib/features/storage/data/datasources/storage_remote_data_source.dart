import 'dart:io';
import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/firebase/firebase_storage_service.dart';

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
    return _storageService.uploadFile(storagePath: storagePath, file: file, contentType: contentType);
  }

  @override
  Future<String> uploadBytes({required String storagePath, required Uint8List bytes, required String contentType}) async {
    return _storageService.uploadData(storagePath: storagePath, data: bytes, contentType: contentType);
  }

  @override
  Future<String> getDownloadUrl(String storagePath) async => _storageService.getDownloadUrl(storagePath);

  @override
  Future<void> deleteFile(String storagePath) async => _storageService.deleteFile(storagePath);
}
