/// Calendar values are workshop wall-clock fields, never device-local instants.
abstract final class WorkshopCalendar {
  static const timeZone = 'Asia/Dhaka';

  static DateTime today([DateTime? instant]) {
    final workshop = (instant ?? DateTime.now()).toUtc().add(
      const Duration(hours: 6),
    );
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
