class InvalidCredentialsException implements Exception {
  final String message;
  InvalidCredentialsException(this.message);
}

class AccessDeniedException implements Exception {
  final String message;
  AccessDeniedException(this.message);
}

class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException(this.message);
}

class ItemNotFoundException implements Exception {
  final String message;
  ItemNotFoundException(this.message);
}

class EmptyHistoryException implements Exception {
  final String message;
  EmptyHistoryException(this.message);
}

class TooManyRequestsException implements Exception {
  final String message;
  TooManyRequestsException(this.message);
}
