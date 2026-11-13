import 'dart:convert';
import 'dart:typed_data';

import 'package:autodoc_ai/features/inspection/data/services/damage_analysis_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('uploads each scan photo and maps the matching damage result', () async {
    var requests = 0;
    final client = MockClient((request) async {
      final index = requests++;
      expect(request.url.path, '/api/v1/damage');
      expect(request.body, contains('name="vehicle_type"'));
      expect(request.body, contains('car'));
      expect(request.body, contains('name="image"; filename="angle-$index.jpg"'));
      if (index == 1) {
        return http.Response(jsonEncode({'detail': 'Model unavailable.'}), 503);
      }
      return http.Response(
        jsonEncode({
          'image_width': 640,
          'image_height': 480,
          'detections': [
            {
              'label': 'dent',
              'bbox': [0.125, 0.25, 0.5, 0.75],
            },
          ],
        }),
        200,
      );
    });
    final service = DamageAnalysisService(
      client: client,
      baseUrl: 'http://localhost:8000/',
    );
    addTearDown(service.close);
    final photos = [
      for (var i = 0; i < 2; i++)
        XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'angle-$i.jpg'),
    ];

    final results = await service.analyzeDamage(photos);

    expect(requests, 2);
    expect(results.map((result) => result.imageIndex), [0, 1]);
    expect(results.first.imageWidth, 640);
    expect(results.first.detections.single.box, [0.125, 0.25, 0.375, 0.5]);
    expect(results.last.available, isFalse);
    expect(results.last.notice, 'Model unavailable.');
  });
}
