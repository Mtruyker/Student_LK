/// Unified authentication exception for all app roles.
class AppAuthException implements Exception {
  final String message;

  const AppAuthException(this.message);

  @override
  String toString() => 'AppAuthException: $message';
}

/// Unified data-fetching exception for all app roles.
class AppDataException implements Exception {
  final String message;

  const AppDataException(this.message);

  @override
  String toString() => 'AppDataException: $message';
}

/// Network-specific exception (no connection, timeout, DNS failure).
///
/// Extends [AppDataException] so existing `catch (AppDataException)` blocks
/// still work — but callers can optionally distinguish network errors.
class AppNetworkException extends AppDataException {
  final bool isTimeout;

  const AppNetworkException(super.message, {this.isTimeout = false});

  @override
  String toString() => 'AppNetworkException: $message';
}
