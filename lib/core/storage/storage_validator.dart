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
