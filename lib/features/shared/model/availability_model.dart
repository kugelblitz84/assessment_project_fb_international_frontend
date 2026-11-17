class AvailabilityModel {
  const AvailabilityModel({
    required this.date,
    required this.timeZone,
    required this.slots,
  });
  final DateTime date;
  final String timeZone;
  final List<TimeSlotModel> slots;
}

class TimeSlotModel {
  const TimeSlotModel({
    required this.id,
    required this.startsAt,
    required this.workshopTime,
    required this.timeZone,
    this.available = true,
  });
  final String id;

  /// Absolute instant for ordering and determining whether a booking is past.
  final DateTime startsAt;

  /// Workshop wall-clock time, rendered without device-timezone conversion.
  final DateTime workshopTime;
  final String timeZone;
  final bool available;

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) => TimeSlotModel(
    id: json['id'] as String,
    startsAt: DateTime.parse(json['startsAt'] as String),
    workshopTime: DateTime.parse(json['workshopTime'] as String),
    timeZone: json['timeZone'] as String,
    available: json['available'] as bool? ?? true,
  );
}
