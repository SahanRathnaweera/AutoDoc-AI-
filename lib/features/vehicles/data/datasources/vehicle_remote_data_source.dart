import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/exceptions.dart';
import 'package:autodoc_ai/core/firebase/firestore_collections.dart';
import 'package:autodoc_ai/core/firebase/firestore_service.dart';
import 'package:autodoc_ai/features/vehicles/data/models/vehicle_model.dart';

abstract class VehicleRemoteDataSource {
  Future<VehicleModel?> getVehicleById(String vehicleId);
  Future<List<VehicleModel>> getVehiclesByOwner(String ownerId);
  Future<String> createVehicle(VehicleModel vehicle);
  Future<void> updateVehicle(VehicleModel vehicle);
  Future<void> deleteVehicle(String vehicleId);
  Stream<VehicleModel?> streamVehicle(String vehicleId);
}

@LazySingleton(as: VehicleRemoteDataSource)
class VehicleRemoteDataSourceImpl implements VehicleRemoteDataSource {
  final FirestoreService _firestoreService;

  VehicleRemoteDataSourceImpl(this._firestoreService);

  @override
  Future<VehicleModel?> getVehicleById(String vehicleId) async {
    final data = await _firestoreService.getDocument(
      collectionPath: FirestoreCollections.vehicles,
      documentId: vehicleId,
    );
    if (data == null) return null;
    return VehicleModel.fromMap(data, id: vehicleId);
  }

  @override
  Future<List<VehicleModel>> getVehiclesByOwner(String ownerId) async {
    final docs = await _firestoreService.queryDocuments(
      collectionPath: FirestoreCollections.vehicles,
      queryBuilder: (query) => query.where('ownerId', isEqualTo: ownerId),
    );
    return docs.map((doc) => VehicleModel.fromMap(doc, id: doc['id'] as String?)).toList();
  }

  @override
  Future<String> createVehicle(VehicleModel vehicle) async {
    return _firestoreService.createDocument(
      collectionPath: FirestoreCollections.vehicles,
      documentId: vehicle.vehicleId.isNotEmpty ? vehicle.vehicleId : null,
      data: vehicle.toMap(),
    );
  }

  @override
  Future<void> updateVehicle(VehicleModel vehicle) async {
    if (vehicle.vehicleId.isEmpty) {
      throw FirestoreException('Cannot update vehicle without vehicleId');
    }
    await _firestoreService.updateDocument(
      collectionPath: FirestoreCollections.vehicles,
      documentId: vehicle.vehicleId,
      data: vehicle.toMap(),
    );
  }

  @override
  Future<void> deleteVehicle(String vehicleId) async {
    await _firestoreService.deleteDocument(
      collectionPath: FirestoreCollections.vehicles,
      documentId: vehicleId,
    );
  }

  @override
  Stream<VehicleModel?> streamVehicle(String vehicleId) {
    return _firestoreService
        .streamDocument(
          collectionPath: FirestoreCollections.vehicles,
          documentId: vehicleId,
        )
        .map((data) => data == null ? null : VehicleModel.fromMap(data, id: vehicleId));
  }
}
