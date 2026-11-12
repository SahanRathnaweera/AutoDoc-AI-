import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

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
    final rawBox = json['box'];
    return DamageDetection(
      label: (json['label'] ?? 'Damage').toString(),
      detail: json['detail']?.toString(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      box: rawBox is List
          ? rawBox.map((e) => (e as num).toDouble()).toList()
          : null,
    );
  }
}

class PhotoDamageResult {
  const PhotoDamageResult({
    required this.imageIndex,
    required this.available,
    this.notice,
    this.detections = const [],
  });

  final int imageIndex;
  final bool available;
  final String? notice;
  final List<DamageDetection> detections;

  factory PhotoDamageResult.fromJson(Map<String, dynamic> json) {
    final raw = json['detections'];
    return PhotoDamageResult(
      imageIndex: (json['image_index'] as num?)?.toInt() ?? 0,
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
  DamageAnalysisService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  // Android emulator එකෙන් PC එකේ localhost = 10.0.2.2
  static String get _baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000';

  // ඔයාගේ FastAPI endpoint එකට ගැලපෙන්න මේක වෙනස් කරන්න
  static const _endpoint = '/damage/analyze';

  Future<String?> _token() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {
      return null; // Firebase configure වෙලා නැති විට
    }
  }

  Future<List<PhotoDamageResult>> analyzeDamage(List<XFile> photos) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl$_endpoint'),
    );

    final token = await _token();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    for (final p in photos) {
      request.files.add(await http.MultipartFile.fromPath('files', p.path));
    }

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception('Server error ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    final List list = decoded is List
        ? decoded
        : (decoded is Map ? (decoded['results'] as List? ?? const []) : const []);

    return list
        .map((e) => PhotoDamageResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void close() => _client.close();
}