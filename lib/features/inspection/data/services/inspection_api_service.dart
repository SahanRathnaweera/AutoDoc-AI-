import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/inspection_report.dart';

class InspectionApiService {
  InspectionApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? _defaultBaseUrl).trim();

  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _requestTimeout = Duration(minutes: 3);
  static final _defaultBaseUrl = _configuredBaseUrl.isNotEmpty
      ? _configuredBaseUrl
      : kIsWeb
      ? 'http://127.0.0.1:8000'
      : defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:8000'
      : 'http://127.0.0.1:8000';

  final http.Client _client;
  final String _baseUrl;

  void close() => _client.close();

  Future<InspectionReport> createReport({
    required String vehicleType,
    required String make,
    required String model,
    required int year,
    required double mileageKm,
    required double reviewedRepairAllowanceLkr,
    required String registrationNumber,
    required List<XFile> images,
    XFile? audio,
  }) async {
    if (images.isEmpty || images.length > 6) {
      throw ArgumentError('Select between 1 and 6 inspection photos.');
    }
    final audioBytes = audio == null ? null : await audio.readAsBytes();
    if (audioBytes != null && audioBytes.isEmpty) {
      throw ArgumentError('The selected audio recording could not be read.');
    }
    await _validateUploadSizes(images, audio);

    final baseUri = Uri.tryParse(_baseUrl);
    if (baseUri == null ||
        !baseUri.hasAuthority ||
        !const {'http', 'https'}.contains(baseUri.scheme)) {
      throw StateError(
        'Set API_BASE_URL to your backend URL, for example '
        'http://10.0.2.2:8000 for an Android emulator.',
      );
    }

    final request = http.MultipartRequest(
      'POST',
      baseUri.replace(
        path:
            '${baseUri.path.replaceFirst(RegExp(r'/$'), '')}/api/v1/inspection',
      ),
    );
    request.fields['metadata'] = jsonEncode({
      'vehicle_type': vehicleType,
      'make': make,
      'model': model,
      'year': year,
      'mileage_km': mileageKm,
      'reviewed_repair_allowance_lkr': reviewedRepairAllowanceLkr,
    });

    for (var index = 0; index < images.length; index++) {
      final image = images[index];
      request.files.add(
        http.MultipartFile.fromBytes(
          'images',
          await image.readAsBytes(),
          filename: image.name.isEmpty ? 'inspection-${index + 1}' : image.name,
        ),
      );
    }

    if (audio != null && audioBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',
          audioBytes,
          filename: audio.name.isEmpty ? 'engine.wav' : audio.name,
        ),
      );
    }

    late final http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await _client.send(request).timeout(_requestTimeout);
    } on http.ClientException catch (error) {
      throw Exception(
        'Could not connect to the backend at $_baseUrl. Confirm the API is '
        'running and that this app is allowed by the backend CORS settings. '
        'Original error: $error',
      );
    }
    final response = await http.Response.fromStream(streamedResponse)
        .timeout(_requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'The inspection service returned an invalid response.',
      );
    }

    return InspectionReport.fromApiResponse(
      response: decoded,
      make: make,
      model: model,
      year: year,
      registrationNumber: registrationNumber,
    );
  }

  static Future<void> _validateUploadSizes(
    List<XFile> images,
    XFile? audio,
  ) async {
    const maxBytes = 10 * 1024 * 1024;
    for (final image in images) {
      if (await image.length() > maxBytes) {
        throw ArgumentError('${image.name} exceeds the 10 MiB upload limit.');
      }
    }
    if (audio != null && await audio.length() > maxBytes) {
      throw ArgumentError('${audio.name} exceeds the 10 MiB upload limit.');
    }
  }

  static String _errorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) return detail;
        if (detail != null) return detail.toString();
      }
    } on FormatException {
      return 'Inspection failed with HTTP ${response.statusCode}.';
    }
    return 'Inspection failed with HTTP ${response.statusCode}.';
  }
}
