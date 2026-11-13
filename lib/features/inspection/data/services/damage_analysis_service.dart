import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

import 'inspection_backend.dart';

class DamageDetection {
  const DamageDetection({
    required this.label,
    this.detail,
    this.confidence,
    this.box,
  });

  final String label;
  final String? detail;
  final double? confidence;

  /// Normalized [x, y, width, height] (0..1)
  final List<double>? box;

  factory DamageDetection.fromJson(Map<String, dynamic> json) {
    final rawBox = json['bbox'];
    final validBox = rawBox is List &&
        rawBox.length == 4 &&
        rawBox.every((value) => value is num && value.isFinite);
    return DamageDetection(
      label: (json['label'] ?? 'Damage').toString(),
      detail: json['detail']?.toString(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      box: validBox ? _normalizedBox(rawBox.cast<num>()) : null,
    );
  }
  static List<double>? _normalizedBox(List<num> coordinates) {
    final bounds = coordinates.map((value) => value.clamp(0, 1).toDouble()).toList();
    final width = bounds[2] - bounds[0];
    final height = bounds[3] - bounds[1];
    if (width <= 0 || height <= 0) return null;
    return [bounds[0], bounds[1], width, height];
  }
}

class PhotoDamageResult {
  const PhotoDamageResult({
    required this.imageIndex,
    required this.available,
    this.notice,
    this.detections = const [],
    this.imageWidth,
    this.imageHeight,
  });

  final int imageIndex;
  final bool available;
  final String? notice;
  final List<DamageDetection> detections;
  final int? imageWidth;
  final int? imageHeight;

  factory PhotoDamageResult.fromJson(
    Map<String, dynamic> json, {
    required int imageIndex,
  }) {
    final raw = json['detections'];
    return PhotoDamageResult(
      imageIndex: imageIndex,
      imageWidth: (json['image_width'] as num?)?.toInt(),
      imageHeight: (json['image_height'] as num?)?.toInt(),
      available: json['available'] as bool? ?? true,
      notice: json['notice']?.toString(),
      detections: raw is List
          ? raw
                .map((e) => DamageDetection.fromJson(e as Map<String, dynamic>))
                .toList()
          : const [],
    );
  }
}

class DamageAnalysisService {
  DamageAnalysisService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? InspectionBackend.baseUrl).trim();

  final http.Client _client;
  final String _baseUrl;

  Future<List<PhotoDamageResult>> analyzeDamage(List<XFile> photos) async {
    final endpoint = InspectionBackend.endpoint(_baseUrl, '/api/v1/damage');
    final results = <PhotoDamageResult>[];
    for (var index = 0; index < photos.length; index++) {
      final photo = photos[index];
      final request = http.MultipartRequest('POST', endpoint);
      request.fields['vehicle_type'] = 'car';
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          await photo.readAsBytes(),
          filename: photo.name.isEmpty ? 'scan-${index + 1}.jpg' : photo.name,
        ),
      );
      late final http.Response response;
      try {
        response = await _client
            .send(request)
            .then(http.Response.fromStream)
            .timeout(const Duration(minutes: 3));
      } on http.ClientException {
        throw Exception(
          'Could not connect to the damage service at $_baseUrl. '
          'Confirm the backend is running and reachable from this device.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        results.add(PhotoDamageResult(
          imageIndex: index,
          available: false,
          notice: InspectionBackend.errorMessage(response, 'Damage analysis'),
        ));
        continue;
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic> || decoded['detections'] is! List) {
        throw const FormatException('The damage service returned an invalid response.');
      }
      results.add(PhotoDamageResult.fromJson(decoded, imageIndex: index));
    }
    return results;
  }

  void close() => _client.close();
}
