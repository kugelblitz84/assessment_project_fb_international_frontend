import 'package:assessment_project_fb_international_frontend/features/admin/services/model/admin_service.dart';

abstract final class ServiceValidation {
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
}
