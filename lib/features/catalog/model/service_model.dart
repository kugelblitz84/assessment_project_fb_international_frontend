/// Public/admin service DTO; prices retain their endpoint-specific semantics.
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
    this.isFeatured = false,
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
  final bool isFeatured;
  bool get isPackage => type == 'PACKAGE';

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    if ([
          'id',
          'name',
          'description',
          'categoryId',
          'categoryName',
          'currency',
        ].any((key) => json[key] is! String) ||
        json['price'] is! num ||
        !(json['price'] as num).isFinite ||
        (json['price'] as num) < 0 ||
        json['durationMinutes'] is! int ||
        (json['durationMinutes'] as int) < 1 ||
        json['available'] is! bool ||
        (json.containsKey('isFeatured') && json['isFeatured'] is! bool) ||
        json['inclusions'] is! List ||
        (json['inclusions'] as List).any((entry) => entry is! String)) {
      throw const FormatException('Invalid service response.');
    }
    return ServiceModel(
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
        (json['inclusions'] as List).cast<String>(),
      ),
      available: json['available'] as bool,
      type: _serviceType(json['type']),
      originalPrice: json['originalPrice'] as num?,
      isFeatured: json['isFeatured'] as bool? ?? false,
    );
  }
  static String _serviceType(Object? value) {
    if (value != 'INDIVIDUAL' && value != 'PACKAGE') {
      throw const FormatException('Invalid service type.');
    }
    return value as String;
  }
}
