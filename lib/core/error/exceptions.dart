class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'Server Exception']);

  @override
  String toString() => 'ServerException: $message';
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Network Exception']);

  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'Cache Exception']);

  @override
  String toString() => 'CacheException: $message';
}

class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException: $message (code: $code)';
}

class FirestoreException implements Exception {
  final String message;
  final String? code;

  FirestoreException(this.message, {this.code});

  @override
  String toString() => 'FirestoreException: $message (code: $code)';
}

class StorageException implements Exception {
  final String message;
  final String? code;

  StorageException(this.message, {this.code});

  @override
  String toString() => 'StorageException: $message (code: $code)';
}
