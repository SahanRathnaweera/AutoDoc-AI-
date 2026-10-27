import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/firebase/firestore_collections.dart';
import 'package:autodoc_ai/core/firebase/firestore_service.dart';
import 'package:autodoc_ai/features/damage_assessment/data/models/damage_result_model.dart';

abstract class DamageRemoteDataSource {
  Future<List<DamageResultModel>> getDamageResultsByInspection(String inspectionId);
  Future<String> saveDamageResult(DamageResultModel damageResult);
  Stream<List<DamageResultModel>> streamDamageResults(String inspectionId);
}

@LazySingleton(as: DamageRemoteDataSource)
class DamageRemoteDataSourceImpl implements DamageRemoteDataSource {
  final FirestoreService _firestoreService;

  DamageRemoteDataSourceImpl(this._firestoreService);

  @override
  Future<List<DamageResultModel>> getDamageResultsByInspection(String inspectionId) async {
    final docs = await _firestoreService.queryDocuments(
      collectionPath: FirestoreCollections.damageResults,
      queryBuilder: (query) => query.where('inspectionId', isEqualTo: inspectionId),
    );
    return docs.map((doc) => DamageResultModel.fromMap(doc, id: doc['id'] as String?)).toList();
  }

  @override
  Future<String> saveDamageResult(DamageResultModel damageResult) async {
    return _firestoreService.createDocument(
      collectionPath: FirestoreCollections.damageResults,
      documentId: damageResult.damageId.isNotEmpty ? damageResult.damageId : null,
      data: damageResult.toMap(),
    );
  }

  @override
  Stream<List<DamageResultModel>> streamDamageResults(String inspectionId) {
    return _firestoreService
        .streamCollection(
          collectionPath: FirestoreCollections.damageResults,
          queryBuilder: (query) => query.where('inspectionId', isEqualTo: inspectionId),
        )
        .map((docs) => docs.map((doc) => DamageResultModel.fromMap(doc, id: doc['id'] as String?)).toList());
  }
}
