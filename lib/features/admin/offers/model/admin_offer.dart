class AdminOffer {
  AdminOffer.fromJson(Map<String, dynamic> json)
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
