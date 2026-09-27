import 'package:dartz/dartz.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/marketplace/domain/entities/marketplace_listing_entity.dart';

abstract class MarketplaceRepository {
  Future<Either<Failure, MarketplaceListingEntity?>> getListingById(String listingId);
  Future<Either<Failure, List<MarketplaceListingEntity>>> getActiveListings({int limit = 20});
  Future<Either<Failure, List<MarketplaceListingEntity>>> getListingsBySeller(String sellerId);
  Future<Either<Failure, String>> createListing(MarketplaceListingEntity listing);
  Future<Either<Failure, void>> updateListingStatus(String listingId, String status);
  Stream<List<MarketplaceListingEntity>> streamActiveListings();
}
