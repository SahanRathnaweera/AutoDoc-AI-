import 'package:flutter_test/flutter_test.dart';
import 'package:autodoc_ai/features/authentication/data/models/user_model.dart';
import 'package:autodoc_ai/features/authentication/domain/entities/user_entity.dart';

void main() {
  group('UserModel', () {
    final testDate = DateTime(2026, 9, 26, 12, 0, 0);

    final tUserModel = UserModel(
      uid: 'user_123',
      email: 'test@autodoc.ai',
      displayName: 'Test User',
      phoneNumber: '+1234567890',
      photoUrl: 'https://example.com/avatar.jpg',
      isEmailVerified: true,
      role: 'inspector',
      createdAt: testDate,
      updatedAt: testDate,
    );

    test('should be a subclass of UserEntity', () {
      expect(tUserModel, isA<UserEntity>());
    });

    test('fromMap parses map data correctly with ISO date strings', () {
      final map = {
        'uid': 'user_123',
        'email': 'test@autodoc.ai',
        'displayName': 'Test User',
        'phoneNumber': '+1234567890',
        'photoUrl': 'https://example.com/avatar.jpg',
        'isEmailVerified': true,
        'role': 'inspector',
        'createdAt': testDate.toIso8601String(),
        'updatedAt': testDate.toIso8601String(),
      };

      final result = UserModel.fromMap(map, uid: 'user_123');

      expect(result.uid, equals('user_123'));
      expect(result.email, equals('test@autodoc.ai'));
      expect(result.displayName, equals('Test User'));
      expect(result.isEmailVerified, isTrue);
      expect(result.role, equals('inspector'));
      expect(result.createdAt, equals(testDate));
    });

    test('fromMap handles milliseconds since epoch', () {
      final millis = testDate.millisecondsSinceEpoch;
      final map = {
        'uid': 'user_456',
        'email': 'user456@autodoc.ai',
        'createdAt': millis,
      };

      final result = UserModel.fromMap(map);
      expect(result.uid, equals('user_456'));
      expect(result.createdAt, equals(testDate));
    });

    test('toMap produces valid dictionary for Firestore persistence', () {
      final map = tUserModel.toMap();

      expect(map['uid'], equals('user_123'));
      expect(map['email'], equals('test@autodoc.ai'));
      expect(map['displayName'], equals('Test User'));
      expect(map['role'], equals('inspector'));
      expect(map['isEmailVerified'], isTrue);
      expect(map.containsKey('createdAt'), isTrue);
      expect(map.containsKey('updatedAt'), isTrue);
    });

    test('copyWith properly overrides specified attributes', () {
      final updated = tUserModel.copyWith(
        displayName: 'Updated Name',
        role: 'admin',
      );

      expect(updated.displayName, equals('Updated Name'));
      expect(updated.role, equals('admin'));
      expect(updated.uid, equals(tUserModel.uid));
      expect(updated.email, equals(tUserModel.email));
    });
  });
}
