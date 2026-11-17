import 'package:assessment_project_fb_international_frontend/features/workshop/utils/workshop_calendar.dart';

class AvailabilityModel {
  const AvailabilityModel({
    required this.date,
    required this.timeZone,
    required this.slots,
  });
  final DateTime date;
  final String timeZone;
  final List<TimeSlotModel> slots;

  factory AvailabilityModel.fromJson(Map<String, dynamic> json) {
    final text = json['date'] as String;
    final date = DateTime.parse('${text}T00:00:00Z');
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text) ||
        date.toIso8601String().substring(0, 10) != text ||
        json['timeZone'] != WorkshopCalendar.timeZone) {
      throw const FormatException('Invalid workshop calendar.');
    }
    return AvailabilityModel(
      date: date,
      timeZone: json['timeZone'] as String,
      slots: List.unmodifiable(
        (json['slots'] as List).map(
          (row) =>
              TimeSlotModel.fromJson(Map<String, dynamic>.from(row as Map)),
        ),
      ),
    );
  }
}

class TimeSlotModel {
  const TimeSlotModel({
    required this.id,
    required this.startsAt,
    required this.workshopTime,
    required this.timeZone,
    this.available = true,
    this.endsAt,
  });
  final String id;

  /// Absolute instant for ordering and determining whether a booking is past.
  final DateTime startsAt;

  /// Workshop wall-clock time, rendered without device-timezone conversion.
  final DateTime workshopTime;
  final String timeZone;
  final bool available;
  final DateTime? endsAt;

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    final workshopText = json['workshopTime'] as String;
    final instantText = json['startsAt'] as String;
    // UTC is a neutral container for wall-clock fields, not this slot's instant.
    final workshop = DateTime.parse('${workshopText}Z');
    if (!RegExp(
          r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$',
        ).hasMatch(workshopText) ||
        workshop.toIso8601String().substring(0, 19) != workshopText ||
        !RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(instantText) ||
        json['timeZone'] != WorkshopCalendar.timeZone ||
        (json['id'] as String).isEmpty ||
        json['available'] is! bool) {
      throw const FormatException('Invalid workshop slot.');
    }
    final startsAt = DateTime.parse(instantText).toUtc();
    final endText = json['endsAt'] as String;
    if (!RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(endText)) {
      throw const FormatException('Missing slot timestamp offset.');
    }
    final end = DateTime.parse(endText).toUtc();
    if (!end.isAfter(startsAt) ||
        workshop != WorkshopCalendar.wallTime(startsAt)) {
      throw const FormatException('Invalid slot interval.');
    }
    return TimeSlotModel(
      id: json['id'] as String,
      startsAt: startsAt,
      endsAt: end,
      workshopTime: workshop,
      timeZone: json['timeZone'] as String,
      available: json['available'] as bool,
    );
  }
}
