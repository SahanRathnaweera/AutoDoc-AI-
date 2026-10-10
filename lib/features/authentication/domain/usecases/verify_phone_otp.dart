import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/authentication/domain/entities/user_entity.dart';
import 'package:autodoc_ai/features/authentication/domain/repositories/auth_repository.dart';

class VerifyPhoneOtpParams extends Equatable {
  final String verificationId;
  final String smsCode;
  final String? displayName;
  final String role;

  const VerifyPhoneOtpParams({
    required this.verificationId,
    required this.smsCode,
    this.displayName,
    this.role = 'client',
  });

  @override
  List<Object?> get props => [verificationId, smsCode, displayName, role];
}

@lazySingleton
class VerifyPhoneOtp implements UseCase<UserEntity, VerifyPhoneOtpParams> {
  final AuthRepository _repository;

  VerifyPhoneOtp(this._repository);

  @override
  Future<Either<Failure, UserEntity>> call(VerifyPhoneOtpParams params) {
    return _repository.verifyPhoneOtp(
      verificationId: params.verificationId,
      smsCode: params.smsCode,
      displayName: params.displayName,
      role: params.role,
    );
  }
}
