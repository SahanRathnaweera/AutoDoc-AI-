import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/authentication/domain/entities/user_entity.dart';
import 'package:autodoc_ai/features/authentication/domain/repositories/auth_repository.dart';

class SendPhoneOtpParams extends Equatable {
  final String phoneNumber;
  final void Function(String verificationId, int? resendToken) onCodeSent;
  final void Function(AuthFailure failure) onVerificationFailed;
  final void Function(UserEntity user)? onVerificationCompleted;
  final void Function(String verificationId)? onCodeAutoRetrievalTimeout;
  final int? forceResendingToken;
  final Duration timeout;

  const SendPhoneOtpParams({
    required this.phoneNumber,
    required this.onCodeSent,
    required this.onVerificationFailed,
    this.onVerificationCompleted,
    this.onCodeAutoRetrievalTimeout,
    this.forceResendingToken,
    this.timeout = const Duration(seconds: 60),
  });

  @override
  List<Object?> get props => [phoneNumber, forceResendingToken, timeout];
}

@lazySingleton
class SendPhoneOtp implements UseCase<void, SendPhoneOtpParams> {
  final AuthRepository _repository;

  SendPhoneOtp(this._repository);

  @override
  Future<Either<Failure, void>> call(SendPhoneOtpParams params) {
    return _repository.verifyPhoneNumber(
      phoneNumber: params.phoneNumber,
      onCodeSent: params.onCodeSent,
      onVerificationFailed: params.onVerificationFailed,
      onVerificationCompleted: params.onVerificationCompleted,
      onCodeAutoRetrievalTimeout: params.onCodeAutoRetrievalTimeout,
      forceResendingToken: params.forceResendingToken,
      timeout: params.timeout,
    );
  }
}
