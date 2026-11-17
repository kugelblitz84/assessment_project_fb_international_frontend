/// Calendar values are workshop wall-clock fields, never device-local instants.
abstract final class WorkshopCalendar {
  static const timeZone = 'Asia/Dhaka';
  static const utcOffset = Duration(hours: 6);

  /// UTC is a neutral container for wall-clock fields, never the slot instant.
  static DateTime wallTime(DateTime instant) => instant.toUtc().add(utcOffset);

  static DateTime today([DateTime? instant]) {
    final workshop = wallTime(instant ?? DateTime.now());
    return DateTime(workshop.year, workshop.month, workshop.day);
  }

  static String dateText(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static DateTime lastDate(DateTime first, {required int horizonDays}) {
    if (horizonDays < 1 || horizonDays > 90) {
      throw const FormatException('Invalid booking horizon configuration.');
    }
    return DateTime(first.year, first.month, first.day + horizonDays - 1);
  }
}
