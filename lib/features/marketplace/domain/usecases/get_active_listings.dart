import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/marketplace/domain/entities/marketplace_listing_entity.dart';
import 'package:autodoc_ai/features/marketplace/domain/repositories/marketplace_repository.dart';

class GetActiveListingsParams extends Equatable {
  final int limit;

  const GetActiveListingsParams({this.limit = 20});

  @override
  List<Object?> get props => [limit];
}

@lazySingleton
class GetActiveListings implements UseCase<List<MarketplaceListingEntity>, GetActiveListingsParams> {
  final MarketplaceRepository _repository;

  GetActiveListings(this._repository);

  @override
  Future<Either<Failure, List<MarketplaceListingEntity>>> call(GetActiveListingsParams params) {
    return _repository.getActiveListings(limit: params.limit);
  }
}
