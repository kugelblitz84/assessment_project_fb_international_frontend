class AdminCategory {
  AdminCategory.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String,
      slug = json['slug'] as String,
      description = json['description'] as String? ?? '',
      imageUrl = json['imageUrl'] as String?,
      isActive = json['isActive'] as bool,
      sortOrder = json['sortOrder'] as int;
  final String id, name, slug, description;
  final String? imageUrl;
  final bool isActive;
  final int sortOrder;
}
