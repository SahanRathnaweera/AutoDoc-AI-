import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:autodoc_ai/features/marketplace/domain/entities/marketplace_listing_entity.dart';

class MarketplaceListingModel extends MarketplaceListingEntity {
  const MarketplaceListingModel({
    required super.listingId,
    required super.sellerId,
    required super.vehicleId,
    super.inspectionId,
    super.reportId,
    required super.title,
    required super.description,
    required super.price,
    super.currency,
    super.images,
    super.verificationStatus,
    super.status,
    super.viewsCount,
    super.createdAt,
    super.updatedAt,
  });

  factory MarketplaceListingModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return MarketplaceListingModel(
      listingId: id ?? map['listingId'] as String? ?? map['id'] as String? ?? '',
      sellerId: map['sellerId'] as String? ?? '',
      vehicleId: map['vehicleId'] as String? ?? '',
      inspectionId: map['inspectionId'] as String?,
      reportId: map['reportId'] as String?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'USD',
      images: (map['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      verificationStatus: map['verificationStatus'] as String? ?? 'unverified',
      status: map['status'] as String? ?? 'active',
      viewsCount: (map['viewsCount'] as num?)?.toInt() ?? 0,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'sellerId': sellerId,
      'vehicleId': vehicleId,
      if (inspectionId != null) 'inspectionId': inspectionId,
      if (reportId != null) 'reportId': reportId,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'images': images,
      'verificationStatus': verificationStatus,
      'status': status,
      'viewsCount': viewsCount,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  MarketplaceListingModel copyWith({
    String? listingId,
    String? sellerId,
    String? vehicleId,
    String? inspectionId,
    String? reportId,
    String? title,
    String? description,
    double? price,
    String? currency,
    List<String>? images,
    String? verificationStatus,
    String? status,
    int? viewsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MarketplaceListingModel(
      listingId: listingId ?? this.listingId,
      sellerId: sellerId ?? this.sellerId,
      vehicleId: vehicleId ?? this.vehicleId,
      inspectionId: inspectionId ?? this.inspectionId,
      reportId: reportId ?? this.reportId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      images: images ?? this.images,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      status: status ?? this.status,
      viewsCount: viewsCount ?? this.viewsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value);
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }
}
