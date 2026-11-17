import 'package:assessment_project_fb_international_frontend/features/admin/services/model/admin_service.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/model/service_validation.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/model/admin_validation.dart';

class ServicePayload {
  ServicePayload({
    required this.name,
    this.slug,
    required this.description,
    required this.categoryId,
    required this.type,
    required this.price,
    required this.durationMinutes,
    required List<String> inclusions,
    List<PackageItem> packageItems = const [],
    this.sortOrder = 0,
    this.isActive = true,
    this.isFeatured = false,
    this.imageUrl,
  }) : inclusions = List.unmodifiable(inclusions),
       packageItems = List.unmodifiable(packageItems);
  final String name, description, categoryId, type, price;
  final String? slug, imageUrl;
  final int durationMinutes, sortOrder;
  final bool isActive, isFeatured;
  final List<String> inclusions;
  final List<PackageItem> packageItems;
  String? validate(Set<String> individualIds) =>
      AdminValidation.name(name) ??
      AdminValidation.slug(slug) ??
      AdminValidation.description(description) ??
      AdminValidation.money(price) ??
      AdminValidation.integer('$durationMinutes', min: 1, max: 1440) ??
      AdminValidation.integer('$sortOrder') ??
      ServiceValidation.inclusions(inclusions) ??
      (!{'INDIVIDUAL', 'PACKAGE'}.contains(type) || categoryId.isEmpty
          ? 'Choose a category and service type.'
          : null) ??
      (type == 'PACKAGE'
          ? ServiceValidation.packageItems(packageItems, individualIds)
          : packageItems.isNotEmpty
          ? 'Individual services cannot contain package items.'
          : null);
  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    if (slug != null && slug!.isNotEmpty) 'slug': slug,
    'description': description,
    'categoryId': categoryId,
    'type': type,
    'price': price,
    'currency': 'BDT',
    'durationMinutes': durationMinutes,
    'sortOrder': sortOrder,
    'isActive': isActive,
    'isFeatured': isFeatured,
    'imageUrl': imageUrl,
    'inclusions': inclusions,
    'packageItems': packageItems.map((item) => item.toJson()).toList(),
  };
}
