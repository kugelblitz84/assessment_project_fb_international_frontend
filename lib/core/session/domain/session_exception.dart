sealed class SessionException implements Exception {
  const SessionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class InvalidSessionException extends SessionException {
  const InvalidSessionException()
    : super('The session is invalid or has expired.');
}

class InvalidCredentialsException extends SessionException {
  const InvalidCredentialsException()
    : super('The email or password is incorrect.');
}

class InvalidAuthResponseException extends SessionException {
  const InvalidAuthResponseException([
    super.message = 'The authentication response is invalid.',
  ]);
}

class AuthRequestException extends SessionException {
  const AuthRequestException(super.message, {this.code = 'UNEXPECTED_ERROR'});
  final String code;
}

class SecureStorageException extends SessionException {
  const SecureStorageException()
    : super('Unable to access secure session storage.');
}
