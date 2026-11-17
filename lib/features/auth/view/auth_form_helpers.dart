import '../../../core/session/domain/session_exception.dart';
import '../../../core/utils/validators.dart';

String? validateEmail(String? value) => Validators.email(value);

String? validatePassword(String? value) =>
    value == null || value.isEmpty ? 'Enter your password.' : null;

String authErrorMessage(Object error) => error is SessionException
    ? error.message
    : 'Unable to save your session securely. Please try again.';
