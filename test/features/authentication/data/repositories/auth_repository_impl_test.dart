import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:autodoc_ai/core/error/exceptions.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:autodoc_ai/features/authentication/data/models/user_model.dart';
import 'package:autodoc_ai/features/authentication/data/repositories/auth_repository_impl.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late AuthRepositoryImpl repository;

  final tUserModel = UserModel(
    uid: 'u123',
    email: 'user@autodoc.ai',
    displayName: 'User',
    role: 'client',
  );

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(mockRemoteDataSource);
  });

  group('loginWithEmailAndPassword', () {
    test('returns Right(UserModel) on success', () async {
      when(() => mockRemoteDataSource.loginWithEmailAndPassword(
            email: 'user@autodoc.ai',
            password: 'pass',
          )).thenAnswer((_) async => tUserModel);

      final result = await repository.loginWithEmailAndPassword(
        email: 'user@autodoc.ai',
        password: 'pass',
      );

      expect(result, Right(tUserModel));
    });

    test('maps invalid-credential code to InvalidCredentialsFailure', () async {
      when(() => mockRemoteDataSource.loginWithEmailAndPassword(
            email: 'user@autodoc.ai',
            password: 'pass',
          )).thenThrow(AuthException('Invalid credentials', code: 'invalid-credential'));

      final result = await repository.loginWithEmailAndPassword(
        email: 'user@autodoc.ai',
        password: 'pass',
      );

      expect(result, const Left(InvalidCredentialsFailure('Invalid credentials', 'invalid-credential')));
    });

    test('maps user-not-found code to UserNotFoundFailure', () async {
      when(() => mockRemoteDataSource.loginWithEmailAndPassword(
            email: 'user@autodoc.ai',
            password: 'pass',
          )).thenThrow(AuthException('User not found', code: 'user-not-found'));

      final result = await repository.loginWithEmailAndPassword(
        email: 'user@autodoc.ai',
        password: 'pass',
      );

      expect(result, const Left(UserNotFoundFailure('User not found', 'user-not-found')));
    });
  });

  group('registerWithEmailAndPassword', () {
    test('returns Right(UserModel) on success', () async {
      when(() => mockRemoteDataSource.registerWithEmailAndPassword(
            email: 'user@autodoc.ai',
            password: 'pass',
            displayName: 'User',
            phoneNumber: null,
            role: 'client',
          )).thenAnswer((_) async => tUserModel);

      final result = await repository.registerWithEmailAndPassword(
        email: 'user@autodoc.ai',
        password: 'pass',
        displayName: 'User',
      );

      expect(result, Right(tUserModel));
    });

    test('maps email-already-in-use code to EmailAlreadyInUseFailure', () async {
      when(() => mockRemoteDataSource.registerWithEmailAndPassword(
            email: 'user@autodoc.ai',
            password: 'pass',
            displayName: null,
            phoneNumber: null,
            role: 'client',
          )).thenThrow(AuthException('Email taken', code: 'email-already-in-use'));

      final result = await repository.registerWithEmailAndPassword(
        email: 'user@autodoc.ai',
        password: 'pass',
      );

      expect(result, const Left(EmailAlreadyInUseFailure('Email taken', 'email-already-in-use')));
    });

    test('maps weak-password code to WeakPasswordFailure', () async {
      when(() => mockRemoteDataSource.registerWithEmailAndPassword(
            email: 'user@autodoc.ai',
            password: '123',
            displayName: null,
            phoneNumber: null,
            role: 'client',
          )).thenThrow(AuthException('Weak pass', code: 'weak-password'));

      final result = await repository.registerWithEmailAndPassword(
        email: 'user@autodoc.ai',
        password: '123',
      );

      expect(result, const Left(WeakPasswordFailure('Weak pass', 'weak-password')));
    });
  });

  group('logout and tokens', () {
    test('logout returns Right(null) on success', () async {
      when(() => mockRemoteDataSource.logout()).thenAnswer((_) async {});

      final result = await repository.logout();

      expect(result, const Right(null));
    });

    test('getIdToken returns Right(token) on success', () async {
      when(() => mockRemoteDataSource.getIdToken(forceRefresh: false))
          .thenAnswer((_) async => 'sample_jwt');

      final result = await repository.getIdToken();

      expect(result, const Right('sample_jwt'));
    });

    test('getIdToken returns Left(AuthFailure) when unauthenticated', () async {
      when(() => mockRemoteDataSource.getIdToken(forceRefresh: false))
          .thenThrow(AuthException('Unauthenticated', code: 'unauthenticated'));

      final result = await repository.getIdToken();

      expect(result, const Left(AuthFailure('Unauthenticated', 'unauthenticated')));
    });
  });
}
