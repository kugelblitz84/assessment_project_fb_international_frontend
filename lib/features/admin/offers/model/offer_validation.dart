import 'package:assessment_project_fb_international_frontend/features/admin/shared/model/admin_validation.dart';

abstract final class OfferValidation {
  static String? offer(
    String type,
    String value,
    DateTime? start,
    DateTime? end,
  ) {
    if (AdminValidation.money(value) != null || num.parse(value) <= 0) {
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
