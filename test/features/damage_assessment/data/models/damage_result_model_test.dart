import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:autodoc_ai/features/damage_assessment/data/models/damage_result_model.dart';
import 'package:autodoc_ai/features/damage_assessment/domain/entities/damage_result_entity.dart';

void main() {
  final tTimestamp = Timestamp.fromDate(DateTime(2026, 9, 27, 12, 10, 0));
  final tDateTime = tTimestamp.toDate();

  final tDamageResultModel = DamageResultModel(
    damageId: 'dmg_01',
    inspectionId: 'insp_101',
    vehicleId: 'veh_01',
    imageStoragePath: 'inspections/insp_101/images/front.jpg',
    annotatedImagePath: 'inspections/insp_101/images/front_annotated.jpg',
    damageType: 'dent',
    severity: 'minor',
    confidence: 0.94,
    bodyLocation: 'front_bumper',
    estimatedRepairCost: 150.0,
    createdAt: tDateTime,
  );

  test('DamageResultModel should be a subclass of DamageResultEntity', () {
    expect(tDamageResultModel, isA<DamageResultEntity>());
  });

  test('fromMap parses valid map with confidence and cost', () {
    final map = {
      'damageId': 'dmg_01',
      'inspectionId': 'insp_101',
      'vehicleId': 'veh_01',
      'imageStoragePath': 'inspections/insp_101/images/front.jpg',
      'annotatedImagePath': 'inspections/insp_101/images/front_annotated.jpg',
      'damageType': 'dent',
      'severity': 'minor',
      'confidence': 0.94,
      'bodyLocation': 'front_bumper',
      'estimatedRepairCost': 150.0,
      'createdAt': tTimestamp,
    };

    final result = DamageResultModel.fromMap(map);

    expect(result.damageId, 'dmg_01');
    expect(result.damageType, 'dent');
    expect(result.confidence, 0.94);
    expect(result.estimatedRepairCost, 150.0);
  });

  test('toMap produces serializable map with Timestamp', () {
    final map = tDamageResultModel.toMap();

    expect(map['damageId'], 'dmg_01');
    expect(map['damageType'], 'dent');
    expect(map['confidence'], 0.94);
    expect(map['createdAt'], isA<Timestamp>());
  });
}
