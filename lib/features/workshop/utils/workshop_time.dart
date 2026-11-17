import 'package:assessment_project_fb_international_frontend/features/workshop/utils/workshop_calendar.dart';

/// Input formatting for the authoritative workshop calendar.
abstract final class WorkshopTime {
  static DateTime local(DateTime instant) => WorkshopCalendar.wallTime(instant);
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
    return wall.subtract(WorkshopCalendar.utcOffset);
  }
}
