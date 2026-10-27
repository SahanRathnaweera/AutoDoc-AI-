import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/firebase/firestore_collections.dart';
import 'package:autodoc_ai/core/firebase/firestore_service.dart';
import 'package:autodoc_ai/features/marketplace/data/models/marketplace_listing_model.dart';

abstract class MarketplaceRemoteDataSource {
  Future<MarketplaceListingModel?> getListingById(String listingId);
  Future<List<MarketplaceListingModel>> getActiveListings({int limit = 20});
  Future<List<MarketplaceListingModel>> getListingsBySeller(String sellerId);
  Future<String> createListing(MarketplaceListingModel listing);
  Future<void> updateListingStatus(String listingId, String status);
  Stream<List<MarketplaceListingModel>> streamActiveListings();
}

@LazySingleton(as: MarketplaceRemoteDataSource)
class MarketplaceRemoteDataSourceImpl implements MarketplaceRemoteDataSource {
  final FirestoreService _firestoreService;

  MarketplaceRemoteDataSourceImpl(this._firestoreService);

  @override
  Future<MarketplaceListingModel?> getListingById(String listingId) async {
    final data = await _firestoreService.getDocument(
      collectionPath: FirestoreCollections.marketplaceListings,
      documentId: listingId,
    );
    if (data == null) return null;
    return MarketplaceListingModel.fromMap(data, id: listingId);
  }

  @override
  Future<List<MarketplaceListingModel>> getActiveListings({int limit = 20}) async {
    final docs = await _firestoreService.queryDocuments(
      collectionPath: FirestoreCollections.marketplaceListings,
      queryBuilder: (query) => query.where('status', isEqualTo: 'active').limit(limit),
    );
    return docs.map((doc) => MarketplaceListingModel.fromMap(doc, id: doc['id'] as String?)).toList();
  }

  @override
  Future<List<MarketplaceListingModel>> getListingsBySeller(String sellerId) async {
    final docs = await _firestoreService.queryDocuments(
      collectionPath: FirestoreCollections.marketplaceListings,
      queryBuilder: (query) => query.where('sellerId', isEqualTo: sellerId),
    );
    return docs.map((doc) => MarketplaceListingModel.fromMap(doc, id: doc['id'] as String?)).toList();
  }

  @override
  Future<String> createListing(MarketplaceListingModel listing) async {
    return _firestoreService.createDocument(
      collectionPath: FirestoreCollections.marketplaceListings,
      documentId: listing.listingId.isNotEmpty ? listing.listingId : null,
      data: listing.toMap(),
    );
  }

  @override
  Future<void> updateListingStatus(String listingId, String status) async {
    await _firestoreService.updateDocument(
      collectionPath: FirestoreCollections.marketplaceListings,
      documentId: listingId,
      data: {'status': status},
    );
  }

  @override
  Stream<List<MarketplaceListingModel>> streamActiveListings() {
    return _firestoreService
        .streamCollection(
          collectionPath: FirestoreCollections.marketplaceListings,
          queryBuilder: (query) => query.where('status', isEqualTo: 'active'),
        )
        .map((docs) => docs.map((doc) => MarketplaceListingModel.fromMap(doc, id: doc['id'] as String?)).toList());
  }
}
