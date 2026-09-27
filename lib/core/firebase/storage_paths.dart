/// Standardized Firebase Storage paths ensuring predictable bucket hierarchy.
class StoragePaths {
  StoragePaths._();

  /// User profile picture path: users/{uid}/profile/{fileName}
  static String userProfile(String uid, String fileName) =>
      'users/$uid/profile/$fileName';

  /// Vehicle photo path: vehicles/{vehicleId}/images/{fileName}
  static String vehicleImage(String vehicleId, String fileName) =>
      'vehicles/$vehicleId/images/$fileName';

  /// Vehicle registration/tax document scan path: vehicles/{vehicleId}/documents/{fileName}
  static String vehicleDocument(String vehicleId, String fileName) =>
      'vehicles/$vehicleId/documents/$fileName';

  /// Inspection 360° photo path: inspections/{inspectionId}/images/{fileName}
  static String inspectionImage(String inspectionId, String fileName) =>
      'inspections/$inspectionId/images/$fileName';

  /// Inspection engine audio clip path: inspections/{inspectionId}/audio/{fileName}
  static String inspectionAudio(String inspectionId, String fileName) =>
      'inspections/$inspectionId/audio/$fileName';

  /// Generated inspection PDF report path: reports/{inspectionId}/{fileName}
  static String inspectionReport(String inspectionId, String fileName) =>
      'reports/$inspectionId/$fileName';
}
