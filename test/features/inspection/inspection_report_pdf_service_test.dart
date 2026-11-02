import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:autodoc_ai/features/inspection/data/services/inspection_api_service.dart';
import 'package:autodoc_ai/features/inspection/data/services/inspection_report_pdf_service.dart';
import 'package:autodoc_ai/features/inspection/domain/entities/inspection_report.dart';

void main() {
  group('InspectionApiService', () {
    test('sends inspection media and maps the backend result', () async {
      final responseBody = {
        'vehicle_type': 'car',
        'damage': [
          {
            'image_index': 0,
            'detections': [
              {'label': 'dent', 'confidence': 0.94},
            ],
          },
        ],
        'audio': {
          'predicted_label': 'normal',
          'notice': 'Experimental sound classification.',
        },
        'valuation': {
          'currency': 'LKR',
          'base_estimate_lkr': 2500000,
          'reviewed_repair_allowance_lkr': 100000,
          'adjusted_estimate_lkr': 2400000,
          'notice': 'Prototype estimate.',
        },
        'voice_summary': 'Inspection processing completed.',
      };

      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/inspection');
        expect(
          request.headers['content-type'],
          startsWith('multipart/form-data;'),
        );
        expect(request.body, contains('name="metadata"'));
        expect(request.body, contains('"make":"Tesla"'));
        expect(request.body, contains('name="images"'));
        expect(request.body, contains('name="audio"'));
        return http.Response(jsonEncode(responseBody), 200);
      });
      final service = InspectionApiService(
        client: client,
        baseUrl: 'http://localhost:8000',
      );
      final photo = XFile.fromData(
        Uint8List.fromList([1, 2, 3]),
        name: 'front.jpg',
      );

      final report = await service.createReport(
        vehicleType: 'car',
        make: 'Tesla',
        model: 'Model 3',
        year: 2019,
        mileageKm: 64320,
        reviewedRepairAllowanceLkr: 100000,
        registrationNumber: 'WP CAA-2048',
        images: [photo],
        audio: XFile.fromData(
          Uint8List.fromList([1, 2, 3]),
          name: 'engine.m4a',
        ),
      );

      service.close();

      expect(report.vehicleName, '2019 Tesla Model 3');
      expect(report.photosAnalyzed, 1);
      expect(report.findings.single.label, 'dent');
      expect(report.findings.single.confidenceLabel, '94% confidence');
      expect(report.audioLabel, 'normal');
      expect(report.baseEstimateLabel, 'LKR 2,500,000');
      expect(report.adjustedEstimateLabel, 'LKR 2,400,000');
      expect(report.isSimulated, isFalse);
    });

    test(
      'maps partial live results without fabricating missing components',
      () async {
        final client = MockClient((request) async {
          expect(request.body, contains('name="images"'));
          expect(request.body, isNot(contains('name="audio"')));
          return http.Response(
            jsonEncode({
              'status': 'partial',
              'unavailable_components': ['valuation', 'audio classification'],
              'damage': [
                {
                  'image_index': 0,
                  'available': true,
                  'detections': [
                    {'label': 'dent', 'confidence': 0.9},
                  ],
                },
              ],
              'audio': {
                'available': false,
                'predicted_label': 'Unavailable',
                'notice': 'Audio model is not installed.',
              },
              'valuation': {
                'available': false,
                'reviewed_repair_allowance_lkr': 25000,
                'notice': 'LKR price units are not verified.',
              },
              'voice_summary': 'Inspection processing partial.',
            }),
            200,
          );
        });
        final service = InspectionApiService(
          client: client,
          baseUrl: 'http://localhost:8000',
        );

        final report = await service.createReport(
          vehicleType: 'car',
          make: 'Toyota',
          model: 'Corolla',
          year: 2020,
          mileageKm: 45000,
          reviewedRepairAllowanceLkr: 25000,
          registrationNumber: 'DEMO-123',
          images: [
            XFile.fromData(Uint8List.fromList([1]), name: 'front.jpg'),
          ],
        );
        service.close();

        expect(report.isPartial, isTrue);
        expect(report.visualAnalysisAvailable, isTrue);
        expect(report.photosAnalyzed, 1);
        expect(report.findings.single.label, 'dent');
        expect(report.audioAvailable, isFalse);
        expect(report.audioLabel, 'Unavailable');
        expect(report.valuationAvailable, isFalse);
        expect(report.baseEstimate, isNull);
        expect(report.baseEstimateLabel, 'Unavailable');
        expect(report.repairAllowanceLabel, 'LKR 25,000');
        final pdf = await InspectionReportPdfService.buildPdf(report);
        expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
      },
    );
  });

  group('InspectionReportPdfService', () {
    test('builds a PDF for an explicitly simulated report', () async {
      final report = InspectionReport(
        reportId: 'DEMO-1',
        vehicleName: '2020 Demo Model',
        registrationNumber: 'DEMO',
        generatedAt: DateTime(2026),
        currency: 'DEMO LKR',
        baseEstimate: 1234567,
        adjustedEstimate: 1234567,
        repairAllowance: 0,
        photosAnalyzed: 0,
        findings: const [],
        audioLabel: 'SIMULATED: rough-idle-like sound',
        audioNotice: 'Random placeholder only.',
        valuationNotice: 'Not a market valuation.',
        voiceSummary: 'No photos or audio were analyzed.',
        isSimulated: true,
      );

      final bytes = await InspectionReportPdfService.buildPdf(report);

      expect(report.isSimulated, isTrue);
      expect(report.baseEstimateLabel, 'DEMO LKR 1,234,567');
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('builds a PDF from live inspection report data', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'damage': [
              {
                'image_index': 0,
                'detections': [
                  {
                    'label': 'dent',
                    'confidence': 0.94,
                    'bbox': [0.1, 0.2, 0.3, 0.4],
                  },
                ],
              },
            ],
            'audio': {
              'predicted_label': 'normal',
              'notice': 'Experimental classification.',
            },
            'valuation': {
              'currency': 'LKR',
              'base_estimate_lkr': 2500000,
              'reviewed_repair_allowance_lkr': 0,
              'adjusted_estimate_lkr': 2500000,
              'notice': 'Prototype estimate.',
            },
            'voice_summary': 'Inspection processing completed.',
          }),
          200,
        ),
      );
      final service = InspectionApiService(
        client: client,
        baseUrl: 'http://localhost:8000',
      );
      final report = await service.createReport(
        vehicleType: 'car',
        make: 'Tesla',
        model: 'Model 3',
        year: 2019,
        mileageKm: 64320,
        reviewedRepairAllowanceLkr: 0,
        registrationNumber: 'WP CAA-2048',
        images: [
          XFile.fromData(Uint8List.fromList([1]), name: 'front.jpg'),
        ],
        audio: XFile.fromData(Uint8List.fromList([1]), name: 'engine.wav'),
      );
      service.close();

      final bytes = await InspectionReportPdfService.buildPdf(report);

      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(1000));
    });
  });
}
