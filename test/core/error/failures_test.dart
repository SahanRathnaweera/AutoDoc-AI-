import 'package:flutter_test/flutter_test.dart';
import 'package:autodoc_ai/core/error/failures.dart';

void main() {
  group('Failures', () {
    test('ServerFailure has default message and equality', () {
      const f1 = ServerFailure();
      const f2 = ServerFailure('Server Error Occurred');
      expect(f1, equals(f2));
      expect(f1.message, equals('Server Error Occurred'));
    });

    test('NetworkFailure has default message', () {
      const failure = NetworkFailure();
      expect(failure.message, equals('No Internet Connection'));
    });

    test('AuthFailure holds message and optional code', () {
      const failure = AuthFailure('Auth failed', 'custom-code');
      expect(failure.message, equals('Auth failed'));
      expect(failure.code, equals('custom-code'));
    });

    test('Specific auth failures have proper default codes and messages', () {
      const invalidCred = InvalidCredentialsFailure();
      expect(invalidCred.code, equals('invalid-credential'));

      const userNotFound = UserNotFoundFailure();
      expect(userNotFound.code, equals('user-not-found'));

      const emailInUse = EmailAlreadyInUseFailure();
      expect(emailInUse.code, equals('email-already-in-use'));

      const weakPass = WeakPasswordFailure();
      expect(weakPass.code, equals('weak-password'));

      const userDisabled = UserDisabledFailure();
      expect(userDisabled.code, equals('user-disabled'));

      const tooManyReq = TooManyRequestsFailure();
      expect(tooManyReq.code, equals('too-many-requests'));

      const invalidOtp = InvalidOtpFailure();
      expect(invalidOtp.code, equals('invalid-verification-code'));

      const otpTimeout = OtpTimeoutFailure();
      expect(otpTimeout.code, equals('session-expired'));

      const quotaExceeded = PhoneAuthQuotaExceededFailure();
      expect(quotaExceeded.code, equals('quota-exceeded'));
    });

    test('FirestoreFailure and StorageFailure support custom codes', () {
      const firestoreFailure = FirestoreFailure('Permission denied', 'permission-denied');
      expect(firestoreFailure.code, equals('permission-denied'));

      const storageFailure = StorageFailure('Quota exceeded', 'quota-exceeded');
      expect(storageFailure.code, equals('quota-exceeded'));
    });
  });
}
