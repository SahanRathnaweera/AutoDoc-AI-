import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/exceptions.dart';
import 'package:autodoc_ai/core/utils/app_logger.dart';

/// Reusable Firebase Storage service abstraction for media, audio, and report uploads.
@lazySingleton
class FirebaseStorageService {
  final FirebaseStorage _storage;

  FirebaseStorageService(this._storage);

  FirebaseStorage get instance => _storage;

  /// Uploads raw binary [data] (bytes) to the specified [storagePath].
  Future<String> uploadData({
    required String storagePath,
    required Uint8List data,
    required String contentType,
    Map<String, String>? customMetadata,
  }) async {
    try {
      final ref = _storage.ref().child(storagePath);
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: customMetadata,
      );

      final uploadTask = await ref.putData(data, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      _logAndThrow(e, 'uploadData to $storagePath');
    } catch (e) {
      throw StorageException('Unexpected error uploading data: $e');
    }
  }

  /// Uploads a local [file] to [storagePath].
  Future<String> uploadFile({
    required String storagePath,
    required File file,
    String? contentType,
    Map<String, String>? customMetadata,
  }) async {
    try {
      final ref = _storage.ref().child(storagePath);
      final metadata = contentType != null
          ? SettableMetadata(contentType: contentType, customMetadata: customMetadata)
          : (customMetadata != null ? SettableMetadata(customMetadata: customMetadata) : null);

      final uploadTask = await ref.putFile(file, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      _logAndThrow(e, 'uploadFile to $storagePath');
    } catch (e) {
      throw StorageException('Unexpected error uploading file: $e');
    }
  }

  /// Uploads an image (JPEG, PNG, WebP) from byte data.
  Future<String> uploadImage({
    required String storagePath,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    Map<String, String>? metadata,
  }) {
    return uploadData(
      storagePath: storagePath,
      data: bytes,
      contentType: contentType,
      customMetadata: metadata,
    );
  }

  /// Uploads an engine audio recording (WAV, MP3, AAC, M4A).
  Future<String> uploadAudio({
    required String storagePath,
    required Uint8List bytes,
    String contentType = 'audio/wav',
    Map<String, String>? metadata,
  }) {
    return uploadData(
      storagePath: storagePath,
      data: bytes,
      contentType: contentType,
      customMetadata: metadata,
    );
  }

  /// Uploads a scanned vehicle or legal document (PDF, PNG, JPG).
  Future<String> uploadDocument({
    required String storagePath,
    required Uint8List bytes,
    String contentType = 'application/pdf',
    Map<String, String>? metadata,
  }) {
    return uploadData(
      storagePath: storagePath,
      data: bytes,
      contentType: contentType,
      customMetadata: metadata,
    );
  }

  /// Uploads an inspection report PDF.
  Future<String> uploadReport({
    required String storagePath,
    required Uint8List bytes,
    Map<String, String>? metadata,
  }) {
    return uploadData(
      storagePath: storagePath,
      data: bytes,
      contentType: 'application/pdf',
      customMetadata: metadata,
    );
  }

  /// Obtains the public download URL for a storage object.
  Future<String> getDownloadUrl(String storagePath) async {
    try {
      return await _storage.ref().child(storagePath).getDownloadURL();
    } on FirebaseException catch (e) {
      _logAndThrow(e, 'getDownloadUrl for $storagePath');
    } catch (e) {
      throw StorageException('Unexpected error getting download URL: $e');
    }
  }

  /// Deletes a file located at [storagePath].
  Future<void> deleteFile(String storagePath) async {
    try {
      await _storage.ref().child(storagePath).delete();
    } on FirebaseException catch (e) {
      _logAndThrow(e, 'deleteFile at $storagePath');
    } catch (e) {
      throw StorageException('Unexpected error deleting file: $e');
    }
  }

  /// Retrieves metadata for a file at [storagePath].
  Future<FullMetadata> getMetadata(String storagePath) async {
    try {
      return await _storage.ref().child(storagePath).getMetadata();
    } on FirebaseException catch (e) {
      _logAndThrow(e, 'getMetadata for $storagePath');
    } catch (e) {
      throw StorageException('Unexpected error retrieving metadata: $e');
    }
  }

  Never _logAndThrow(FirebaseException e, String context) {
    AppLogger.error('StorageException in $context [${e.code}]: ${e.message}');
    throw StorageException(
      e.message ?? 'Storage operation failed during $context',
      code: e.code,
    );
  }
}
