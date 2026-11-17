abstract final class AuthValidation {
  static String? password(String? value) =>
      value == null || value.isEmpty ? 'Enter your password.' : null;
  static String? name(String? value) =>
      value == null || value.trim().isEmpty ? 'Enter your name.' : null;
}
