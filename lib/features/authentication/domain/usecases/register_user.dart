import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/authentication/domain/entities/user_entity.dart';
import 'package:autodoc_ai/features/authentication/domain/repositories/auth_repository.dart';

class RegisterParams extends Equatable {
  final String email;
  final String password;
  final String? displayName;
  final String? phoneNumber;
  final String role;

  const RegisterParams({
    required this.email,
    required this.password,
    this.displayName,
    this.phoneNumber,
    this.role = 'client',
  });

  @override
  List<Object?> get props => [email, password, displayName, phoneNumber, role];
}

@lazySingleton
class RegisterUser implements UseCase<UserEntity, RegisterParams> {
  final AuthRepository repository;

  RegisterUser(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(RegisterParams params) {
    return repository.registerWithEmailAndPassword(
      email: params.email,
      password: params.password,
      displayName: params.displayName,
      phoneNumber: params.phoneNumber,
      role: params.role,
    );
  }
}
