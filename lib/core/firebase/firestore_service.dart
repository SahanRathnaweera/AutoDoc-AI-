import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/exceptions.dart';
import 'package:autodoc_ai/core/utils/app_logger.dart';

typedef FirestoreQueryBuilder = Query<Map<String, dynamic>> Function(
    Query<Map<String, dynamic>> query);

/// Generic, reusable Firestore service abstraction providing safe CRUD,
/// querying, transactions, and streams for AutoDoc AI.
@lazySingleton
class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService(this._firestore);

  FirebaseFirestore get instance => _firestore;

  /// Creates a document in [collectionPath]. If [documentId] is omitted, Firestore auto-generates one.
  Future<String> createDocument({
    required String collectionPath,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      final docRef = documentId != null
          ? _firestore.collection(collectionPath).doc(documentId)
          : _firestore.collection(collectionPath).doc();

      final dataWithTimestamp = {
        ...data,
        'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(dataWithTimestamp, SetOptions(merge: true));
      return docRef.id;
    } on FirebaseException catch (e) {
      _logAndThrow(e, 'createDocument in $collectionPath');
    } catch (e) {
      throw FirestoreException('Unexpected error creating document: $e');
    }
  }

  /// Sets or overwrites a document at [collectionPath]/[documentId].
  Future<void> setDocument({
    required String collectionPath,
    required String documentId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    try {
      final dataWithTimestamp = {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection(collectionPath)
          .doc(documentId)
          .set(dataWithTimestamp, SetOptions(merge: merge));
    } on FirebaseException catch (e) {
      _logAndThrow(e, 'setDocument in $collectionPath/$documentId');
    } catch (e) {
      throw FirestoreException('Unexpected error setting document: $e');
    }
  }

  /// Fetches a single document data map at [collectionPath]/[documentId].
  Future<Map<String, dynamic>?> getDocument({
    required String collectionPath,
    required String documentId,
  }) async {
    try {
      final snapshot =
          await _firestore.collection(collectionPath).doc(documentId).get();
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return {
        'id': snapshot.id,
        ...snapshot.data()!,
      };
    } on FirebaseException catch (e) {
      _logAndThrow(e, 'getDocument from $collectionPath/$documentId');
    } catch (e) {
      throw FirestoreException('Unexpected error getting document: $e');
    }
  }

  /// Updates existing fields in document at [collectionPath]/[documentId].
  Future<void> updateDocument({
    required String collectionPath,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final dataWithTimestamp = {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection(collectionPath)
          .doc(documentId)
          .update(dataWithTimestamp);
    } on FirebaseException catch (e) {
      _logAndThrow(e, 'updateDocument in $collectionPath/$documentId');
    } catch (e) {
      throw FirestoreException('Unexpected error updating document: $e');
    }
  }

  /// Deletes a document at [collectionPath]/[documentId].
  Future<void> deleteDocument({
    required String collectionPath,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collectionPath).doc(documentId).delete();
    } on FirebaseException catch (e) {
      _logAndThrow(e, 'deleteDocument in $collectionPath/$documentId');
    } catch (e) {
      throw FirestoreException('Unexpected error deleting document: $e');
    }
  }

  /// Queries documents in [collectionPath] applying an optional [queryBuilder].
  Future<List<Map<String, dynamic>>> queryDocuments({
    required String collectionPath,
    FirestoreQueryBuilder? queryBuilder,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection(collectionPath);
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }
      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } on FirebaseException catch (e) {
      _logAndThrow(e, 'queryDocuments in $collectionPath');
    } catch (e) {
      throw FirestoreException('Unexpected error querying documents: $e');
    }
  }

  /// Streams real-time updates for a single document.
  Stream<Map<String, dynamic>?> streamDocument({
    required String collectionPath,
    required String documentId,
  }) {
    return _firestore
        .collection(collectionPath)
        .doc(documentId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return {'id': snapshot.id, ...snapshot.data()!};
    });
  }

  /// Streams real-time updates for a query or collection.
  Stream<List<Map<String, dynamic>>> streamCollection({
    required String collectionPath,
    FirestoreQueryBuilder? queryBuilder,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(collectionPath);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }

  /// Executes atomic operations inside a Firestore transaction.
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) transactionHandler,
  ) async {
    try {
      return await _firestore.runTransaction(transactionHandler);
    } on FirebaseException catch (e) {
      _logAndThrow(e, 'runTransaction');
    } catch (e) {
      throw FirestoreException('Unexpected error running transaction: $e');
    }
  }

  /// Executes multiple writes atomically using WriteBatch.
  Future<void> runBatch(void Function(WriteBatch batch) batchHandler) async {
    try {
      final batch = _firestore.batch();
      batchHandler(batch);
      await batch.commit();
    } on FirebaseException catch (e) {
      _logAndThrow(e, 'runBatch');
    } catch (e) {
      throw FirestoreException('Unexpected error running batch: $e');
    }
  }

  Never _logAndThrow(FirebaseException e, String context) {
    AppLogger.error('FirestoreException in $context [${e.code}]: ${e.message}');
    throw FirestoreException(
      e.message ?? 'Firestore error occurred during $context',
      code: e.code,
    );
  }
}
