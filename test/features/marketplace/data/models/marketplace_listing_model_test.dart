import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:autodoc_ai/features/marketplace/data/models/marketplace_listing_model.dart';
import 'package:autodoc_ai/features/marketplace/domain/entities/marketplace_listing_entity.dart';

void main() {
  final tTimestamp = Timestamp.fromDate(DateTime(2026, 9, 27, 14, 0, 0));
  final tDateTime = tTimestamp.toDate();

  final tListingModel = MarketplaceListingModel(
    listingId: 'list_01',
    sellerId: 'usr_01',
    vehicleId: 'veh_01',
    inspectionId: 'insp_101',
    reportId: 'rep_01',
    title: '2021 Toyota Corolla - Certified Inspection',
    description: 'Immaculate condition with verified AutoDoc report.',
    price: 21500.0,
    currency: 'USD',
    images: const ['https://storage.googleapis.com/car.jpg'],
    verificationStatus: 'verified',
    status: 'active',
    viewsCount: 15,
    createdAt: tDateTime,
    updatedAt: tDateTime,
  );

  test('MarketplaceListingModel should be a subclass of MarketplaceListingEntity', () {
    expect(tListingModel, isA<MarketplaceListingEntity>());
  });

  test('fromMap parses valid map with listing details', () {
    final map = {
      'listingId': 'list_01',
      'sellerId': 'usr_01',
      'vehicleId': 'veh_01',
      'inspectionId': 'insp_101',
      'reportId': 'rep_01',
      'title': '2021 Toyota Corolla - Certified Inspection',
      'description': 'Immaculate condition with verified AutoDoc report.',
      'price': 21500.0,
      'currency': 'USD',
      'images': ['https://storage.googleapis.com/car.jpg'],
      'verificationStatus': 'verified',
      'status': 'active',
      'viewsCount': 15,
      'createdAt': tTimestamp,
      'updatedAt': tTimestamp,
    };

    final result = MarketplaceListingModel.fromMap(map);

    expect(result.listingId, 'list_01');
    expect(result.price, 21500.0);
    expect(result.verificationStatus, 'verified');
    expect(result.status, 'active');
  });

  test('toMap produces serializable map with Timestamp', () {
    final map = tListingModel.toMap();

    expect(map['listingId'], 'list_01');
    expect(map['price'], 21500.0);
    expect(map['verificationStatus'], 'verified');
    expect(map['createdAt'], isA<Timestamp>());
  });
}
