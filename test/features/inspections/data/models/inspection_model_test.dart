import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:autodoc_ai/features/inspections/data/models/inspection_model.dart';
import 'package:autodoc_ai/features/inspections/domain/entities/inspection_entity.dart';

void main() {
  final tTimestamp = Timestamp.fromDate(DateTime(2026, 9, 27, 12, 0, 0));
  final tDateTime = tTimestamp.toDate();

  final tInspectionModel = InspectionModel(
    inspectionId: 'insp_101',
    vehicleId: 'veh_01',
    userId: 'usr_01',
    inspectorId: 'insp_pro',
    status: 'completed',
    inspectionDate: tDateTime,
    overallScore: 88.5,
    damageScore: 90.0,
    engineScore: 87.0,
    createdAt: tDateTime,
    updatedAt: tDateTime,
  );

  test('InspectionModel should be a subclass of InspectionEntity', () {
    expect(tInspectionModel, isA<InspectionEntity>());
  });

  test('fromMap parses valid map with scores', () {
    final map = {
      'inspectionId': 'insp_101',
      'vehicleId': 'veh_01',
      'userId': 'usr_01',
      'inspectorId': 'insp_pro',
      'status': 'completed',
      'inspectionDate': tTimestamp,
      'overallScore': 88.5,
      'damageScore': 90.0,
      'engineScore': 87.0,
      'createdAt': tTimestamp,
      'updatedAt': tTimestamp,
    };

    final result = InspectionModel.fromMap(map);

    expect(result.inspectionId, 'insp_101');
    expect(result.vehicleId, 'veh_01');
    expect(result.overallScore, 88.5);
    expect(result.status, 'completed');
  });

  test('toMap produces serializable map with Timestamp', () {
    final map = tInspectionModel.toMap();

    expect(map['inspectionId'], 'insp_101');
    expect(map['overallScore'], 88.5);
    expect(map['status'], 'completed');
    expect(map['inspectionDate'], isA<Timestamp>());
  });

  test('copyWith properly updates status and scores', () {
    final updated = tInspectionModel.copyWith(status: 'verified', overallScore: 92.0);

    expect(updated.status, 'verified');
    expect(updated.overallScore, 92.0);
    expect(updated.inspectionId, tInspectionModel.inspectionId);
  });
}
