abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server Error Occurred']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No Internet Connection']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache Error Occurred']);
}

class AuthFailure extends Failure {
  final String? code;

  const AuthFailure([super.message = 'Authentication Error Occurred', this.code]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthFailure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ (code?.hashCode ?? 0);
}

class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure([super.message = 'Invalid email or password', super.code = 'invalid-credential']);
}

class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure([super.message = 'User not found for given credentials', super.code = 'user-not-found']);
}

class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure([super.message = 'Email address is already registered', super.code = 'email-already-in-use']);
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure([super.message = 'Password provided is too weak', super.code = 'weak-password']);
}

class UserDisabledFailure extends AuthFailure {
  const UserDisabledFailure([super.message = 'This user account has been disabled', super.code = 'user-disabled']);
}

class TooManyRequestsFailure extends AuthFailure {
  const TooManyRequestsFailure([super.message = 'Too many requests. Please try again later', super.code = 'too-many-requests']);
}

class FirestoreFailure extends Failure {
  final String? code;

  const FirestoreFailure([super.message = 'Firestore Error Occurred', this.code]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FirestoreFailure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ (code?.hashCode ?? 0);
}

class StorageFailure extends Failure {
  final String? code;

  const StorageFailure([super.message = 'Storage Error Occurred', this.code]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorageFailure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ (code?.hashCode ?? 0);
}
