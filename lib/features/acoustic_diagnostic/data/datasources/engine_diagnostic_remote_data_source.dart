import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/firebase/firestore_collections.dart';
import 'package:autodoc_ai/core/firebase/firestore_service.dart';
import 'package:autodoc_ai/features/acoustic_diagnostic/data/models/engine_diagnostic_model.dart';

abstract class EngineDiagnosticRemoteDataSource {
  Future<List<EngineDiagnosticModel>> getDiagnosticsByInspection(String inspectionId);
  Future<String> saveDiagnosticResult(EngineDiagnosticModel diagnostic);
  Stream<List<EngineDiagnosticModel>> streamDiagnostics(String inspectionId);
}

@LazySingleton(as: EngineDiagnosticRemoteDataSource)
class EngineDiagnosticRemoteDataSourceImpl implements EngineDiagnosticRemoteDataSource {
  final FirestoreService _firestoreService;

  EngineDiagnosticRemoteDataSourceImpl(this._firestoreService);

  @override
  Future<List<EngineDiagnosticModel>> getDiagnosticsByInspection(String inspectionId) async {
    final docs = await _firestoreService.queryDocuments(
      collectionPath: FirestoreCollections.engineDiagnostics,
      queryBuilder: (query) => query.where('inspectionId', isEqualTo: inspectionId),
    );
    return docs.map((doc) => EngineDiagnosticModel.fromMap(doc, id: doc['id'] as String?)).toList();
  }

  @override
  Future<String> saveDiagnosticResult(EngineDiagnosticModel diagnostic) async {
    return _firestoreService.createDocument(
      collectionPath: FirestoreCollections.engineDiagnostics,
      documentId: diagnostic.diagnosticId.isNotEmpty ? diagnostic.diagnosticId : null,
      data: diagnostic.toMap(),
    );
  }

  @override
  Stream<List<EngineDiagnosticModel>> streamDiagnostics(String inspectionId) {
    return _firestoreService
        .streamCollection(
          collectionPath: FirestoreCollections.engineDiagnostics,
          queryBuilder: (query) => query.where('inspectionId', isEqualTo: inspectionId),
        )
        .map((docs) => docs.map((doc) => EngineDiagnosticModel.fromMap(doc, id: doc['id'] as String?)).toList());
  }
}
