import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/exceptions.dart';
import 'package:autodoc_ai/core/firebase/firestore_collections.dart';
import 'package:autodoc_ai/core/firebase/firestore_service.dart';
import 'package:autodoc_ai/features/inspections/data/models/inspection_model.dart';

abstract class InspectionRemoteDataSource {
  Future<InspectionModel?> getInspectionById(String inspectionId);
  Future<List<InspectionModel>> getInspectionsByVehicle(String vehicleId);
  Future<List<InspectionModel>> getInspectionsByUser(String userId);
  Future<String> createInspection(InspectionModel inspection);
  Future<void> updateInspectionStatus(String inspectionId, String status);
  Stream<InspectionModel?> streamInspection(String inspectionId);
}

@LazySingleton(as: InspectionRemoteDataSource)
class InspectionRemoteDataSourceImpl implements InspectionRemoteDataSource {
  final FirestoreService _firestoreService;

  InspectionRemoteDataSourceImpl(this._firestoreService);

  @override
  Future<InspectionModel?> getInspectionById(String inspectionId) async {
    final data = await _firestoreService.getDocument(
      collectionPath: FirestoreCollections.inspections,
      documentId: inspectionId,
    );
    if (data == null) return null;
    return InspectionModel.fromMap(data, id: inspectionId);
  }

  @override
  Future<List<InspectionModel>> getInspectionsByVehicle(String vehicleId) async {
    final docs = await _firestoreService.queryDocuments(
      collectionPath: FirestoreCollections.inspections,
      queryBuilder: (query) => query.where('vehicleId', isEqualTo: vehicleId),
    );
    return docs.map((doc) => InspectionModel.fromMap(doc, id: doc['id'] as String?)).toList();
  }

  @override
  Future<List<InspectionModel>> getInspectionsByUser(String userId) async {
    final docs = await _firestoreService.queryDocuments(
      collectionPath: FirestoreCollections.inspections,
      queryBuilder: (query) => query.where('userId', isEqualTo: userId),
    );
    return docs.map((doc) => InspectionModel.fromMap(doc, id: doc['id'] as String?)).toList();
  }

  @override
  Future<String> createInspection(InspectionModel inspection) async {
    return _firestoreService.createDocument(
      collectionPath: FirestoreCollections.inspections,
      documentId: inspection.inspectionId.isNotEmpty ? inspection.inspectionId : null,
      data: inspection.toMap(),
    );
  }

  @override
  Future<void> updateInspectionStatus(String inspectionId, String status) async {
    if (inspectionId.isEmpty) {
      throw FirestoreException('Cannot update inspection without inspectionId');
    }
    await _firestoreService.updateDocument(
      collectionPath: FirestoreCollections.inspections,
      documentId: inspectionId,
      data: {'status': status},
    );
  }

  @override
  Stream<InspectionModel?> streamInspection(String inspectionId) {
    return _firestoreService
        .streamDocument(
          collectionPath: FirestoreCollections.inspections,
          documentId: inspectionId,
        )
        .map((data) => data == null ? null : InspectionModel.fromMap(data, id: inspectionId));
  }
}
