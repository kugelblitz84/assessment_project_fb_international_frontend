import '../../../shared/model/appointment_model.dart';
import '../../../shared/model/service_model.dart';

typedef Json = Map<String, dynamic>;

class AdminCategory {
  AdminCategory.fromJson(Json json)
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

class PackageItem {
  const PackageItem({required this.serviceId, required this.quantity});
  factory PackageItem.fromJson(Json json) => PackageItem(
    serviceId: json['serviceId'] as String,
    quantity: json['quantity'] as int,
  );
  final String serviceId;
  final int quantity;
  Json toJson() => {'serviceId': serviceId, 'quantity': quantity};
}

/// Administrative metadata around the same catalog entity used by customers.
/// Admin price is the stored base price; public price is the effective price.
class AdminService {
  AdminService.fromJson(Json json)
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

class AdminOffer {
  AdminOffer.fromJson(Json json)
    : id = json['id'] as String,
      serviceId = json['serviceId'] as String,
      title = json['title'] as String,
      description = json['description'] as String,
      discountType = json['discountType'] as String,
      discountValue = json['discountValue'] as num,
      startsAt = DateTime.parse(json['startsAt'] as String),
      endsAt = DateTime.parse(json['endsAt'] as String),
      isActive = json['isActive'] as bool;
  final String id, serviceId, title, description, discountType;
  final num discountValue;
  final DateTime startsAt, endsAt;
  final bool isActive;
  String stateAt(DateTime now) => !isActive
      ? 'Disabled'
      : !now.isBefore(endsAt)
      ? 'Expired'
      : now.isBefore(startsAt)
      ? 'Scheduled'
      : 'Active';
}

class AdminAppointment {
  AdminAppointment.fromJson(Json json)
    : id = json['id'] as String,
      serviceName = json['serviceName'] as String,
      customerName = (json['user'] as Map)['name'] as String,
      customerEmail = (json['user'] as Map)['email'] as String,
      startsAt = DateTime.parse(json['startsAt'] as String),
      endsAt = DateTime.parse(json['endsAt'] as String),
      status = BookingStatus.values.byName(json['status'] as String),
      price = json['price'] as num,
      basePrice = json['basePrice'] as num,
      currency = json['currency'] as String,
      durationMinutes = json['durationMinutes'] as int,
      createdAt = DateTime.parse(json['createdAt'] as String),
      cancelledAt = json['cancelledAt'] == null
          ? null
          : DateTime.parse(json['cancelledAt'] as String),
      vehicle = json['vehicle'] == null
          ? null
          : Map<String, dynamic>.from(json['vehicle'] as Map),
      appliedOfferId = json['appliedOfferId'] as String?;
  final String id, serviceName, customerName, customerEmail, currency;
  final BookingStatus status;
  final DateTime startsAt, endsAt, createdAt;
  final DateTime? cancelledAt;
  final num price, basePrice;
  final int durationMinutes;
  final Json? vehicle;
  final String? appliedOfferId;
  List<BookingStatus> actionsAt(DateTime now) => switch (status) {
    BookingStatus.pending => [BookingStatus.confirmed, BookingStatus.cancelled],
    BookingStatus.confirmed => [
      if (!now.isBefore(endsAt)) BookingStatus.completed,
      BookingStatus.cancelled,
    ],
    _ => [],
  };
}

/// The backend workshop uses Asia/Dhaka (UTC+06, no daylight saving).
abstract final class WorkshopTime {
  static DateTime local(DateTime instant) =>
      instant.toUtc().add(const Duration(hours: 6));
  static String input(DateTime instant) =>
      local(instant).toIso8601String().substring(0, 16).replaceFirst('T', ' ');
  static DateTime? parse(String text) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}$').hasMatch(text)) {
      return null;
    }
    final wall = DateTime.tryParse('${text.replaceFirst(' ', 'T')}Z');
    if (wall == null ||
        wall.toIso8601String().substring(0, 16) !=
            text.replaceFirst(' ', 'T')) {
      return null;
    }
    return wall.subtract(const Duration(hours: 6));
  }
}
