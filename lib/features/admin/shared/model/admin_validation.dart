abstract final class AdminValidation {
  static String? name(String? value) =>
      value == null || value.trim().isEmpty || value.trim().length > 200
      ? 'Enter 1–200 characters.'
      : null;
  static String? description(String? value) =>
      (value?.length ?? 0) > 10000 ? 'Use at most 10,000 characters.' : null;
  static String? slug(String? value) => value == null || value.isEmpty
      ? null
      : value.length <= 200 &&
            RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(value)
      ? null
      : 'Use lowercase letters, numbers and single hyphens.';
  static String? money(String? value) =>
      value != null && RegExp(r'^\d{1,10}(\.\d{1,2})?$').hasMatch(value)
      ? null
      : 'Enter a nonnegative BDT amount with at most 2 decimals.';
  static String? integer(
    String? value, {
    int min = -2147483648,
    int max = 2147483647,
  }) {
    final number = int.tryParse(value ?? '');
    return number == null || number < min || number > max
        ? 'Enter a whole number from $min to $max.'
        : null;
  }
}
