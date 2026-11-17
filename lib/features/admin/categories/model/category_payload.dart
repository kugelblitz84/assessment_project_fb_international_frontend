import 'package:assessment_project_fb_international_frontend/features/admin/shared/model/admin_validation.dart';

class CategoryPayload {
  const CategoryPayload({
    required this.name,
    this.slug,
    this.description = '',
    this.sortOrder = 0,
    this.isActive = true,
    this.imageUrl,
  });
  final String name;
  final String? slug, imageUrl;
  final String description;
  final int sortOrder;
  final bool isActive;
  String? get validationError =>
      AdminValidation.name(name) ??
      AdminValidation.slug(slug) ??
      AdminValidation.description(description) ??
      AdminValidation.integer('$sortOrder');
  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    if (slug != null && slug!.isNotEmpty) 'slug': slug,
    'description': description,
    'sortOrder': sortOrder,
    'isActive': isActive,
    'imageUrl': imageUrl,
  };
}
