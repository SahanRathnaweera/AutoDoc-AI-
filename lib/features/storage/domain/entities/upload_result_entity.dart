import 'package:equatable/equatable.dart';

class UploadResultEntity extends Equatable {
  final String storagePath;
  final String downloadUrl;
  final String contentType;
  final int sizeBytes;
  final DateTime uploadedAt;

  const UploadResultEntity({
    required this.storagePath,
    required this.downloadUrl,
    required this.contentType,
    required this.sizeBytes,
    required this.uploadedAt,
  });

  @override
  List<Object?> get props => [storagePath, downloadUrl, contentType, sizeBytes, uploadedAt];
}
