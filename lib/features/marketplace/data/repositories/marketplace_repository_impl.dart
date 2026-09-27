import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/exceptions.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/marketplace/data/datasources/marketplace_remote_data_source.dart';
import 'package:autodoc_ai/features/marketplace/data/models/marketplace_listing_model.dart';
import 'package:autodoc_ai/features/marketplace/domain/entities/marketplace_listing_entity.dart';
import 'package:autodoc_ai/features/marketplace/domain/repositories/marketplace_repository.dart';

@LazySingleton(as: MarketplaceRepository)
class MarketplaceRepositoryImpl implements MarketplaceRepository {
  final MarketplaceRemoteDataSource _remoteDataSource;

  MarketplaceRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, MarketplaceListingEntity?>> getListingById(String listingId) async {
    try {
      final listing = await _remoteDataSource.getListingById(listingId);
      return Right(listing);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(e.message, e.code));
    } catch (e) {
      return Left(FirestoreFailure('Failed to fetch listing: $e'));
    }
  }

  @override
  Future<Either<Failure, List<MarketplaceListingEntity>>> getActiveListings({int limit = 20}) async {
    try {
      final listings = await _remoteDataSource.getActiveListings(limit: limit);
      return Right(listings);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(e.message, e.code));
    } catch (e) {
      return Left(FirestoreFailure('Failed to fetch active listings: $e'));
    }
  }

  @override
  Future<Either<Failure, List<MarketplaceListingEntity>>> getListingsBySeller(String sellerId) async {
    try {
      final listings = await _remoteDataSource.getListingsBySeller(sellerId);
      return Right(listings);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(e.message, e.code));
    } catch (e) {
      return Left(FirestoreFailure('Failed to fetch seller listings: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> createListing(MarketplaceListingEntity listing) async {
    try {
      final model = _toModel(listing);
      final id = await _remoteDataSource.createListing(model);
      return Right(id);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(e.message, e.code));
    } catch (e) {
      return Left(FirestoreFailure('Failed to create listing: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateListingStatus(String listingId, String status) async {
    try {
      await _remoteDataSource.updateListingStatus(listingId, status);
      return const Right(null);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(e.message, e.code));
    } catch (e) {
      return Left(FirestoreFailure('Failed to update listing status: $e'));
    }
  }

  @override
  Stream<List<MarketplaceListingEntity>> streamActiveListings() {
    return _remoteDataSource.streamActiveListings();
  }

  MarketplaceListingModel _toModel(MarketplaceListingEntity entity) {
    if (entity is MarketplaceListingModel) return entity;
    return MarketplaceListingModel(
      listingId: entity.listingId,
      sellerId: entity.sellerId,
      vehicleId: entity.vehicleId,
      inspectionId: entity.inspectionId,
      reportId: entity.reportId,
      title: entity.title,
      description: entity.description,
      price: entity.price,
      currency: entity.currency,
      images: entity.images,
      verificationStatus: entity.verificationStatus,
      status: entity.status,
      viewsCount: entity.viewsCount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
