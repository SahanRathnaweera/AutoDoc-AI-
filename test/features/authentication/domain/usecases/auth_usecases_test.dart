import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/authentication/domain/entities/user_entity.dart';
import 'package:autodoc_ai/features/authentication/domain/repositories/auth_repository.dart';
import 'package:autodoc_ai/features/authentication/domain/usecases/get_current_user.dart';
import 'package:autodoc_ai/features/authentication/domain/usecases/get_id_token.dart';
import 'package:autodoc_ai/features/authentication/domain/usecases/login_user.dart';
import 'package:autodoc_ai/features/authentication/domain/usecases/logout_user.dart';
import 'package:autodoc_ai/features/authentication/domain/usecases/observe_auth_state.dart';
import 'package:autodoc_ai/features/authentication/domain/usecases/register_user.dart';
import 'package:autodoc_ai/features/authentication/domain/usecases/reset_password.dart';
import 'package:autodoc_ai/features/authentication/domain/usecases/send_email_verification.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late LoginUser loginUser;
  late RegisterUser registerUser;
  late LogoutUser logoutUser;
  late GetCurrentUser getCurrentUser;
  late ObserveAuthState observeAuthState;
  late ResetPassword resetPassword;
  late SendEmailVerification sendEmailVerification;
  late GetIdToken getIdToken;

  const tUser = UserEntity(
    uid: 'test_uid_1',
    email: 'client@autodoc.ai',
    displayName: 'Client Name',
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    loginUser = LoginUser(mockAuthRepository);
    registerUser = RegisterUser(mockAuthRepository);
    logoutUser = LogoutUser(mockAuthRepository);
    getCurrentUser = GetCurrentUser(mockAuthRepository);
    observeAuthState = ObserveAuthState(mockAuthRepository);
    resetPassword = ResetPassword(mockAuthRepository);
    sendEmailVerification = SendEmailVerification(mockAuthRepository);
    getIdToken = GetIdToken(mockAuthRepository);
  });

  group('LoginUser', () {
    test('should return UserEntity on successful login', () async {
      when(() => mockAuthRepository.loginWithEmailAndPassword(
            email: 'client@autodoc.ai',
            password: 'Password123!',
          )).thenAnswer((_) async => const Right(tUser));

      final result = await loginUser(const LoginParams(
        email: 'client@autodoc.ai',
        password: 'Password123!',
      ));

      expect(result, const Right(tUser));
      verify(() => mockAuthRepository.loginWithEmailAndPassword(
            email: 'client@autodoc.ai',
            password: 'Password123!',
          )).called(1);
    });

    test('should return Failure on failed login', () async {
      when(() => mockAuthRepository.loginWithEmailAndPassword(
            email: 'client@autodoc.ai',
            password: 'wrong',
          )).thenAnswer((_) async => const Left(InvalidCredentialsFailure()));

      final result = await loginUser(const LoginParams(
        email: 'client@autodoc.ai',
        password: 'wrong',
      ));

      expect(result, const Left(InvalidCredentialsFailure()));
    });
  });

  group('RegisterUser', () {
    test('should delegate to repository and return registered UserEntity', () async {
      when(() => mockAuthRepository.registerWithEmailAndPassword(
            email: 'client@autodoc.ai',
            password: 'Password123!',
            displayName: 'Client Name',
            phoneNumber: '+123456789',
            role: 'client',
          )).thenAnswer((_) async => const Right(tUser));

      final result = await registerUser(const RegisterParams(
        email: 'client@autodoc.ai',
        password: 'Password123!',
        displayName: 'Client Name',
        phoneNumber: '+123456789',
        role: 'client',
      ));

      expect(result, const Right(tUser));
      verify(() => mockAuthRepository.registerWithEmailAndPassword(
            email: 'client@autodoc.ai',
            password: 'Password123!',
            displayName: 'Client Name',
            phoneNumber: '+123456789',
            role: 'client',
          )).called(1);
    });
  });

  group('LogoutUser', () {
    test('should call repository logout', () async {
      when(() => mockAuthRepository.logout())
          .thenAnswer((_) async => const Right(null));

      final result = await logoutUser(const NoParams());

      expect(result, const Right(null));
      verify(() => mockAuthRepository.logout()).called(1);
    });
  });

  group('GetCurrentUser', () {
    test('should return current user from repository', () async {
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => const Right(tUser));

      final result = await getCurrentUser(const NoParams());

      expect(result, const Right(tUser));
      verify(() => mockAuthRepository.getCurrentUser()).called(1);
    });
  });

  group('ObserveAuthState', () {
    test('should return stream of UserEntity from repository', () {
      when(() => mockAuthRepository.observeAuthState())
          .thenAnswer((_) => Stream.value(tUser));

      final stream = observeAuthState(const NoParams());

      expect(stream, emits(tUser));
      verify(() => mockAuthRepository.observeAuthState()).called(1);
    });
  });

  group('ResetPassword & SendEmailVerification', () {
    test('should delegate reset password call to repository', () async {
      when(() => mockAuthRepository.sendPasswordResetEmail(email: 'test@autodoc.ai'))
          .thenAnswer((_) async => const Right(null));

      final result = await resetPassword(const ResetPasswordParams(email: 'test@autodoc.ai'));

      expect(result, const Right(null));
      verify(() => mockAuthRepository.sendPasswordResetEmail(email: 'test@autodoc.ai')).called(1);
    });

    test('should delegate send email verification call', () async {
      when(() => mockAuthRepository.sendEmailVerification())
          .thenAnswer((_) async => const Right(null));

      final result = await sendEmailVerification(const NoParams());

      expect(result, const Right(null));
      verify(() => mockAuthRepository.sendEmailVerification()).called(1);
    });
  });

  group('GetIdToken', () {
    test('should return JWT token string from repository', () async {
      when(() => mockAuthRepository.getIdToken(forceRefresh: true))
          .thenAnswer((_) async => const Right('mock.jwt.token'));

      final result = await getIdToken(const GetIdTokenParams(forceRefresh: true));

      expect(result, const Right('mock.jwt.token'));
      verify(() => mockAuthRepository.getIdToken(forceRefresh: true)).called(1);
    });
  });
}
