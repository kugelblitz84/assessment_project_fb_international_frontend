import 'package:assessment_project_fb_international_frontend/features/catalog/model/service_model.dart';

class PackageItem {
  const PackageItem({required this.serviceId, required this.quantity});
  factory PackageItem.fromJson(Map<String, dynamic> json) => PackageItem(
    serviceId: json['serviceId'] as String,
    quantity: json['quantity'] as int,
  );
  final String serviceId;
  final int quantity;
  Map<String, dynamic> toJson() => {
    'serviceId': serviceId,
    'quantity': quantity,
  };
}

/// Administrative metadata around the same catalog entity used by customers.
/// Admin price is the stored base price; public price is the effective price.

class AdminService {
  AdminService.fromJson(Map<String, dynamic> json)
    : service = ServiceModel.fromJson(json),
      slug = json['slug'] as String,
      isActive = json['isActive'] as bool,
      isFeatured = json['isFeatured'] as bool,
      sortOrder = json['sortOrder'] as int,
      items = List.unmodifiable(
        (json['packageItems'] as List).map(
          (item) =>
              PackageItem.fromJson(Map<String, dynamic>.from(item as Map)),
        ),
      );
  final ServiceModel service;
  final String slug;
  final bool isActive, isFeatured;
  final int sortOrder;
  final List<PackageItem> items;
  String get id => service.id;
}
