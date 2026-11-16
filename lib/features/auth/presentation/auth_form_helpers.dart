import '../../../core/session/domain/session_exception.dart';

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
      ? null
      : 'Enter a valid email address.';
}

String? validatePassword(String? value) =>
    value == null || value.isEmpty ? 'Enter your password.' : null;

String authErrorMessage(Object error) => error is SessionException
    ? error.message
    : 'Unable to save your session securely. Please try again.';
