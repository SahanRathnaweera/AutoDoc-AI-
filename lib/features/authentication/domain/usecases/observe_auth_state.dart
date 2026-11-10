import 'package:injectable/injectable.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/features/authentication/domain/entities/user_entity.dart';
import 'package:autodoc_ai/features/authentication/domain/repositories/auth_repository.dart';

@lazySingleton
class ObserveAuthState implements StreamUseCase<UserEntity?, NoParams> {
  final AuthRepository repository;

  ObserveAuthState(this.repository);

  @override
  Stream<UserEntity?> call(NoParams params) {
    return repository.observeAuthState();
  }
}
