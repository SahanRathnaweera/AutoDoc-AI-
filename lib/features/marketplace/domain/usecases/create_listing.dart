import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/marketplace/domain/entities/marketplace_listing_entity.dart';
import 'package:autodoc_ai/features/marketplace/domain/repositories/marketplace_repository.dart';

class CreateListingParams extends Equatable {
  final MarketplaceListingEntity listing;

  const CreateListingParams(this.listing);

  @override
  List<Object?> get props => [listing];
}

@lazySingleton
class CreateListing implements UseCase<String, CreateListingParams> {
  final MarketplaceRepository _repository;

  CreateListing(this._repository);

  @override
  Future<Either<Failure, String>> call(CreateListingParams params) {
    return _repository.createListing(params.listing);
  }
}
