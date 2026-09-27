/// Strongly-typed Firestore collection identifiers for AutoDoc AI.
class FirestoreCollections {
  FirestoreCollections._();

  /// User profile collection: users/{uid}
  static const String users = 'users';

  /// Registered vehicles collection: vehicles/{vehicleId}
  static const String vehicles = 'vehicles';

  /// Inspection sessions collection: inspections/{inspectionId}
  static const String inspections = 'inspections';

  /// AI damage detection results collection: damage_results/{damageId}
  static const String damageResults = 'damage_results';

  /// Engine acoustic diagnostic results collection: engine_diagnostics/{diagnosticId}
  static const String engineDiagnostics = 'engine_diagnostics';

  /// OCR document scanning results collection: ocr_results/{ocrId}
  static const String ocrResults = 'ocr_results';

  /// Vehicle valuation estimates collection: valuations/{valuationId}
  static const String valuations = 'valuations';

  /// Generated inspection reports collection: reports/{reportId}
  static const String reports = 'reports';

  /// Vehicle marketplace listings collection: marketplace_listings/{listingId}
  static const String marketplaceListings = 'marketplace_listings';
}
