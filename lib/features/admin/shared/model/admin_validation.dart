import 'admin_models.dart';

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

  static String? inclusions(List<String> values) =>
      values.length > 100 ||
          values.any((v) => v.trim().isEmpty || v.trim().length > 1000)
      ? 'Use up to 100 nonempty inclusions, each at most 1,000 characters.'
      : null;
  static String? packageItems(
    List<PackageItem> items,
    Set<String> individualIds,
  ) =>
      items.isEmpty ||
          items.length > 100 ||
          items.map((i) => i.serviceId).toSet().length != items.length ||
          items.any(
            (i) =>
                !individualIds.contains(i.serviceId) ||
                i.quantity < 1 ||
                i.quantity > 1000,
          )
      ? 'Select 1–100 unique individual services with quantities from 1 to 1,000.'
      : null;
  static String? offer(
    String type,
    String value,
    DateTime? start,
    DateTime? end,
  ) {
    if (money(value) != null || num.parse(value) <= 0) {
      return 'Enter a positive discount with at most 2 decimals.';
    }
    if (!{'PERCENTAGE', 'FIXED_AMOUNT'}.contains(type)) {
      return 'Choose a discount type.';
    }
    if (type == 'PERCENTAGE' && num.parse(value) > 100) {
      return 'Percentage must be at most 100.';
    }
    if (start == null || end == null || !end.isAfter(start)) {
      return 'Enter valid dates with the end after the start.';
    }
    return null;
  }
}
