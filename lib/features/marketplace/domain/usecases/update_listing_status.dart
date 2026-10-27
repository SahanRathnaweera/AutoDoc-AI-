import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/marketplace/domain/repositories/marketplace_repository.dart';

class UpdateListingStatusParams extends Equatable {
  final String listingId;
  final String status;

  const UpdateListingStatusParams({
    required this.listingId,
    required this.status,
  });

  @override
  List<Object?> get props => [listingId, status];
}

@lazySingleton
class UpdateListingStatus implements UseCase<void, UpdateListingStatusParams> {
  final MarketplaceRepository _repository;

  UpdateListingStatus(this._repository);

  @override
  Future<Either<Failure, void>> call(UpdateListingStatusParams params) {
    return _repository.updateListingStatus(params.listingId, params.status);
  }
}
