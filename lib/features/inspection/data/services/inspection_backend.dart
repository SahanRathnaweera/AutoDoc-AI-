import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

abstract final class InspectionBackend {
  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _defaultRenderUrl = 'https://autodoc-ai-qsib.onrender.com';

  static String get baseUrl {
    if (_configuredBaseUrl.trim().isNotEmpty) return _configuredBaseUrl.trim();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return _defaultRenderUrl;
    }
    return _defaultRenderUrl;
  }

  static Uri endpoint(String baseUrl, String path) {
    final base = Uri.tryParse(baseUrl);
    if (base == null ||
        base.host.isEmpty ||
        !const {'http', 'https'}.contains(base.scheme)) {
      throw StateError('Set API_BASE_URL to the HTTP or HTTPS backend address.');
    }
    return base.replace(
      path: '${base.path.replaceFirst(RegExp(r'/$'), '')}$path',
    );
  }

  static String errorMessage(http.Response response, String operation) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
        return decoded['detail'].toString();
      }
    } on FormatException {
      // Non-JSON responses can come from a reverse proxy.
    }
    return '$operation failed with HTTP ${response.statusCode}.';
  }
}