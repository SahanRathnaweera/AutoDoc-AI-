import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:autodoc_ai/core/error/exceptions.dart';
import 'package:autodoc_ai/core/firebase/firebase_token_provider.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;
  late FirebaseTokenProvider tokenProvider;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();
    tokenProvider = FirebaseTokenProvider(mockFirebaseAuth);
  });

  group('FirebaseTokenProvider', () {
    test('requireIdToken returns token when user is logged in', () async {
      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.getIdToken(false)).thenAnswer((_) async => 'valid_token_123');

      final token = await tokenProvider.requireIdToken();

      expect(token, equals('valid_token_123'));
      verify(() => mockUser.getIdToken(false)).called(1);
    });

    test('requireIdToken throws AuthException when currentUser is null', () async {
      when(() => mockFirebaseAuth.currentUser).thenReturn(null);

      expect(
        () => tokenProvider.requireIdToken(),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'unauthenticated')),
      );
    });

    test('getIdToken returns null when user is not logged in', () async {
      when(() => mockFirebaseAuth.currentUser).thenReturn(null);

      final token = await tokenProvider.getIdToken();
      expect(token, isNull);
    });

    test('getAuthorizationHeader returns correct Bearer map', () async {
      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.getIdToken(false)).thenAnswer((_) async => 'bearer_jwt');

      final headers = await tokenProvider.getAuthorizationHeader();

      expect(headers, {
        'Authorization': 'Bearer bearer_jwt',
        'Content-Type': 'application/json',
      });
    });
  });
}
