/// UI contract. JSON keys can be adapted when backend DTOs are supplied.
class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.price,
    required this.currency,
    required this.durationMinutes,
    this.imageUrl,
    this.inclusions = const [],
    this.available = true,
    this.type = 'INDIVIDUAL',
    this.originalPrice,
  });
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final String categoryName;
  final num price;
  final String currency;
  final int durationMinutes;
  final String? imageUrl;
  final List<String> inclusions;
  final bool available;
  final String type;
  final num? originalPrice;
  bool get isPackage => type == 'PACKAGE';

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    categoryId: json['categoryId'] as String,
    categoryName: json['categoryName'] as String,
    price: json['price'] as num,
    currency: json['currency'] as String,
    durationMinutes: json['durationMinutes'] as int,
    imageUrl: json['imageUrl'] as String?,
    inclusions: List<String>.unmodifiable(
      (json['inclusions'] as List?)?.cast<String>() ?? const [],
    ),
    available: json['available'] as bool? ?? true,
    type: _serviceType(json['type']),
    originalPrice: json['originalPrice'] as num?,
  );
  static String _serviceType(Object? value) {
    if (value == null) return 'INDIVIDUAL';
    if (value != 'INDIVIDUAL' && value != 'PACKAGE') {
      throw const FormatException('Invalid service type.');
    }
    return value as String;
  }
}
