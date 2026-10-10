import 'package:flutter_test/flutter_test.dart';
import 'package:autodoc_ai/core/firebase/storage_paths.dart';
import 'package:autodoc_ai/core/firebase/firestore_collections.dart';

void main() {
  group('StoragePaths', () {
    test('userProfile formats properly', () {
      final path = StoragePaths.userProfile('uid_123', 'avatar.jpg');
      expect(path, equals('users/uid_123/profile/avatar.jpg'));
    });

    test('vehicleImage and vehicleDocument format properly', () {
      final img = StoragePaths.vehicleImage('v_1', 'front.jpg');
      final doc = StoragePaths.vehicleDocument('v_1', 'reg.pdf');
      expect(img, equals('vehicles/v_1/images/front.jpg'));
      expect(doc, equals('vehicles/v_1/documents/reg.pdf'));
    });

    test('inspectionImage and inspectionAudio format properly', () {
      final img = StoragePaths.inspectionImage('insp_10', 'bumper.png');
      final audio = StoragePaths.inspectionAudio('insp_10', 'engine.wav');
      expect(img, equals('inspections/insp_10/images/bumper.png'));
      expect(audio, equals('inspections/insp_10/audio/engine.wav'));
    });

    test('inspectionReport formats properly', () {
      final path = StoragePaths.inspectionReport('insp_10', 'summary.pdf');
      expect(path, equals('reports/insp_10/summary.pdf'));
    });
  });

  group('FirestoreCollections', () {
    test('collection constants are non-empty and formatted', () {
      expect(FirestoreCollections.users, equals('users'));
      expect(FirestoreCollections.vehicles, equals('vehicles'));
      expect(FirestoreCollections.inspections, equals('inspections'));
      expect(FirestoreCollections.damageResults, equals('damage_results'));
      expect(FirestoreCollections.engineDiagnostics, equals('engine_diagnostics'));
      expect(FirestoreCollections.ocrResults, equals('ocr_results'));
      expect(FirestoreCollections.valuations, equals('valuations'));
      expect(FirestoreCollections.reports, equals('reports'));
      expect(FirestoreCollections.marketplaceListings, equals('marketplace_listings'));
    });
  });
}
