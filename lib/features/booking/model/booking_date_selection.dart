/// Snapshot of the date-picker bounds. The controller accepts its result only
/// while this selection still belongs to the same draft and session.
class BookingDateSelection {
  const BookingDateSelection({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate, firstDate, lastDate;
}
