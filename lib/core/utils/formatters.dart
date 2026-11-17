abstract final class Formatters {
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static String date(DateTime value) =>
      '${_weekdays[value.weekday - 1]}, ${value.day} ${_months[value.month - 1]} ${value.year}';
  static String shortDate(DateTime value) =>
      '${value.day} ${_months[value.month - 1]}';
  static String time(DateTime value) =>
      '${value.hour % 12 == 0 ? 12 : value.hour % 12}:${value.minute.toString().padLeft(2, '0')} ${value.hour < 12 ? 'AM' : 'PM'}';
  static String duration(int minutes) => minutes < 60
      ? '$minutes min'
      : '${minutes ~/ 60} hr${minutes % 60 == 0 ? '' : ' ${minutes % 60} min'}';
  static String price(num amount, String currency) {
    final parts = amount
        .toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2)
        .split('.');
    final whole = parts.first.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '${currency == 'BDT' ? '৳' : '$currency '}$whole${parts.length == 2 ? '.${parts[1]}' : ''}';
  }

  static String initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    return words.isEmpty
        ? '?'
        : '${words.first[0]}${words.length > 1 ? words.last[0] : ''}'
              .toUpperCase();
  }
}
