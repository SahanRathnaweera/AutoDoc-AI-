import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/marketplace/domain/entities/marketplace_listing_entity.dart';
import 'package:autodoc_ai/features/marketplace/domain/repositories/marketplace_repository.dart';

class GetListingByIdParams extends Equatable {
  final String listingId;

  const GetListingByIdParams(this.listingId);

  @override
  List<Object?> get props => [listingId];
}

@lazySingleton
class GetListingById implements UseCase<MarketplaceListingEntity?, GetListingByIdParams> {
  final MarketplaceRepository _repository;

  GetListingById(this._repository);

  @override
  Future<Either<Failure, MarketplaceListingEntity?>> call(GetListingByIdParams params) {
    return _repository.getListingById(params.listingId);
  }
}
