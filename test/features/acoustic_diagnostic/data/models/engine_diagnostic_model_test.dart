import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:autodoc_ai/features/acoustic_diagnostic/data/models/engine_diagnostic_model.dart';
import 'package:autodoc_ai/features/acoustic_diagnostic/domain/entities/engine_diagnostic_entity.dart';

void main() {
  final tTimestamp = Timestamp.fromDate(DateTime(2026, 9, 27, 12, 15, 0));
  final tDateTime = tTimestamp.toDate();

  final tDiagnosticModel = EngineDiagnosticModel(
    diagnosticId: 'eng_01',
    inspectionId: 'insp_101',
    vehicleId: 'veh_01',
    audioStoragePath: 'inspections/insp_101/audio/engine.wav',
    durationSeconds: 15.0,
    status: 'completed',
    anomalyDetected: false,
    anomalyType: 'normal',
    confidence: 0.98,
    spectralFeatures: const {'rpm': 800, 'peak_freq': 120.5},
    createdAt: tDateTime,
  );

  test('EngineDiagnosticModel should be a subclass of EngineDiagnosticEntity', () {
    expect(tDiagnosticModel, isA<EngineDiagnosticEntity>());
  });

  test('fromMap parses valid map with spectralFeatures', () {
    final map = {
      'diagnosticId': 'eng_01',
      'inspectionId': 'insp_101',
      'vehicleId': 'veh_01',
      'audioStoragePath': 'inspections/insp_101/audio/engine.wav',
      'durationSeconds': 15.0,
      'status': 'completed',
      'anomalyDetected': false,
      'anomalyType': 'normal',
      'confidence': 0.98,
      'spectralFeatures': {'rpm': 800, 'peak_freq': 120.5},
      'createdAt': tTimestamp,
    };

    final result = EngineDiagnosticModel.fromMap(map);

    expect(result.diagnosticId, 'eng_01');
    expect(result.anomalyDetected, false);
    expect(result.confidence, 0.98);
    expect(result.spectralFeatures?['rpm'], 800);
  });

  test('toMap produces serializable map with Timestamp', () {
    final map = tDiagnosticModel.toMap();

    expect(map['diagnosticId'], 'eng_01');
    expect(map['durationSeconds'], 15.0);
    expect(map['anomalyDetected'], false);
    expect(map['createdAt'], isA<Timestamp>());
  });
}
