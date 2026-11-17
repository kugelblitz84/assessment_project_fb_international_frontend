/// Safe generic failure messages. Business messages are composed by the app.
abstract final class ApiErrorMessages {
  /// Only locally defined copy is exposed to views, never server error details.
  static String messageFor(String? code) => switch (code) {
    'BACKEND_UNAVAILABLE' =>
      'The workshop is temporarily unavailable. Retry connecting; your session is preserved.',
    'NETWORK_ERROR' => 'Check your internet connection and try again.',
    'CONNECTION_TIMEOUT' ||
    'SEND_TIMEOUT' ||
    'RECEIVE_TIMEOUT' ||
    'TIMEOUT' => 'The request took too long. Please try again.',
    'VALIDATION_ERROR' => 'Please check the information you entered.',
    'INVALID_CREDENTIALS' => 'The email or password is incorrect.',
    'SECURE_STORAGE_ERROR' =>
      'Unable to save your session securely. Please try again.',
    'PAYLOAD_TOO_LARGE' => 'The submitted information is too large.',
    'CANCELLED' => '',
    'SESSION_EXPIRED' || 'UNAUTHORIZED' => 'Please sign in again to continue.',
    'FORBIDDEN' => 'You do not have permission to perform this action.',
    'NOT_FOUND' => 'The requested information could not be found.',
    'CONFLICT' =>
      'The request conflicts with current information. Refresh and try again.',
    'RATE_LIMITED' => 'Too many requests. Please try again shortly.',
    'SERVER_ERROR' =>
      'The service is temporarily unavailable. Try again later.',
    'INVALID_RESPONSE' =>
      'We could not load the information correctly. Try again.',
    _ => 'Something went wrong. Please try again.',
  };
}
