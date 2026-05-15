/// Raw exceptions — thrown by datasource layer.
/// Repository catches these and maps to Failure types.

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class ServerException implements Exception {
  final String message;
  const ServerException(this.message);

  @override
  String toString() => 'ServerException: $message';
}

class IngestException implements Exception {
  final String message;
  const IngestException(this.message);

  @override
  String toString() => 'IngestException: $message';
}

class QueryException implements Exception {
  final String message;
  const QueryException(this.message);  // ← this.message not super.message

  @override
  String toString() => 'QueryException: $message';
}