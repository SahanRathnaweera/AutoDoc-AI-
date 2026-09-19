abstract class Failure {
  final String message;
  const Failure(this.message);
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