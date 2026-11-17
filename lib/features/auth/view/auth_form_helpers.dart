import '../../../core/utils/validators.dart';

String? validateEmail(String? value) => Validators.email(value);

String? validatePassword(String? value) =>
    value == null || value.isEmpty ? 'Enter your password.' : null;
