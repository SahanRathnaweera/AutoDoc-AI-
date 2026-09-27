import 'package:equatable/equatable.dart';

class MarketplaceListingEntity extends Equatable {
  final String listingId;
  final String sellerId;
  final String vehicleId;
  final String? inspectionId;
  final String? reportId;
  final String title;
  final String description;
  final double price;
  final String currency;
  final List<String> images;
  final String verificationStatus;
  final String status;
  final int viewsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MarketplaceListingEntity({
    required this.listingId,
    required this.sellerId,
    required this.vehicleId,
    this.inspectionId,
    this.reportId,
    required this.title,
    required this.description,
    required this.price,
    this.currency = 'USD',
    this.images = const [],
    this.verificationStatus = 'unverified',
    this.status = 'active',
    this.viewsCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        listingId,
        sellerId,
        vehicleId,
        inspectionId,
        reportId,
        title,
        description,
        price,
        currency,
        images,
        verificationStatus,
        status,
        viewsCount,
        createdAt,
        updatedAt,
      ];
}
